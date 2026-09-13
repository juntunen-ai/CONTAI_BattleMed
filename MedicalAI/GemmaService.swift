import Foundation
import LlamaSwift

/// On-device Gemma 4 E2B (Q4_0 GGUF). The language layer may only structure
/// a transcript. Swift validates the proposal; the ledger still commits.
/// Weights do not ship in git. They live in Application Support after a
/// one-time download, or in Documents if copied onto the phone.
@MainActor
final class GemmaService: ObservableObject {
    static let shared = GemmaService()

    enum State: Equatable {
        case missing
        case downloading(Double)
        case loading
        case ready
        case failed(String)
    }

    static let filename = "gemma-4-E2B-it-Q4_0.gguf"
    static let expectedBytes: Int64 = 2_841_481_184
    static let remote = URL(string: "https://huggingface.co/ggml-org/gemma-4-E2B-it-GGUF/resolve/main/gemma-4-E2B-it-Q4_0.gguf")!

    @Published private(set) var state: State = .missing

    private let runtime = GemmaRuntime()
    private var prepareTask: Task<Void, Never>?

    var isReady: Bool { state == .ready }

    var chip: String {
        switch state {
        case .ready: return "GEMMA · ON-DEVICE"
        case .downloading: return "GEMMA · DOWNLOADING"
        case .loading: return "GEMMA · LOADING"
        case .failed: return "GEMMA · FAILED"
        case .missing: return "SPEECH · ON-DEVICE"
        }
    }

    func prepare() {
        if prepareTask != nil { return }
        if case .ready = state { return }
        prepareTask = Task { await prepareOnce() }
    }

    func structure(_ raw: String) async -> DictationCandidate? {
        guard case .ready = state else { return nil }
        return await runtime.structure(raw)
    }

    private func prepareOnce() async {
        if let url = Self.locate() {
            await load(url)
            prepareTask = nil
            return
        }
        do {
            let url = try await download()
            await load(url)
        } catch is CancellationError {
            state = .missing
        } catch {
            state = .failed("Gemma 4 E2B could not be downloaded: \(error.localizedDescription). Keyword structuring stays on. Nothing clinical left the device.")
        }
        prepareTask = nil
    }

    private func load(_ url: URL) async {
        state = .loading
        do {
            try await runtime.load(path: url.path)
            state = .ready
        } catch {
            state = .failed("Gemma 4 E2B is on disk but failed to load: \(error.localizedDescription). Keyword structuring stays on.")
        }
    }

    static func locate() -> URL? {
        let urls = [
            supportDir().appendingPathComponent(filename),
            documentsDir().appendingPathComponent(filename)
        ]
        for url in urls {
            guard let values = try? url.resourceValues(forKeys: [.fileSizeKey]),
                  let size = values.fileSize,
                  Int64(size) >= expectedBytes - 4096 else { continue }
            return url
        }
        return nil
    }

    private static func supportDir() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("Models", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private static func documentsDir() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private func download() async throws -> URL {
        state = .downloading(0)
        let dest = Self.supportDir().appendingPathComponent(Self.filename)
        if FileManager.default.fileExists(atPath: dest.path) {
            try FileManager.default.removeItem(at: dest)
        }
        var request = URLRequest(url: Self.remote)
        request.timeoutInterval = 60 * 60
        let (temp, response) = try await URLSession.shared.download(from: request.url!)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw NSError(domain: "GemmaDownload", code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode) from Hugging Face"])
        }
        try FileManager.default.moveItem(at: temp, to: dest)
        return dest
    }
}

/// Blocking llama.cpp calls live off the main actor.
final class GemmaRuntime: @unchecked Sendable {
    private let lock = NSLock()
    private var model: OpaquePointer?
    private var context: OpaquePointer?
    private var backendReady = false

    deinit {
        lock.lock()
        if let context { llama_free(context) }
        if let model { llama_model_free(model) }
        lock.unlock()
    }

    func load(path: String) async throws {
        try await Task.detached(priority: .userInitiated) { [self] in
            try self.loadSync(path: path)
        }.value
    }

    func structure(_ raw: String) async -> DictationCandidate? {
        await Task.detached(priority: .userInitiated) { [self] in
            self.structureSync(raw)
        }.value
    }

    private func loadSync(path: String) throws {
        lock.lock()
        defer { lock.unlock() }
        if !backendReady {
            llama_backend_init()
            backendReady = true
        }
        if let context { llama_free(context); self.context = nil }
        if let model { llama_model_free(model); self.model = nil }

        var mp = llama_model_default_params()
        mp.n_gpu_layers = 99
        guard let model = llama_model_load_from_file(path, mp) else {
            throw RuntimeError("llama_model_load_from_file failed")
        }
        var cp = llama_context_default_params()
        cp.n_ctx = 2048
        cp.n_batch = 256
        let threads = max(2, Int32(ProcessInfo.processInfo.processorCount - 2))
        cp.n_threads = threads
        cp.n_threads_batch = threads
        guard let context = llama_init_from_model(model, cp) else {
            llama_model_free(model)
            throw RuntimeError("llama_init_from_model failed")
        }
        self.model = model
        self.context = context
    }

    private func structureSync(_ raw: String) -> DictationCandidate? {
        lock.lock()
        defer { lock.unlock() }
        guard let model, let context else { return nil }
        guard let vocab = llama_model_get_vocab(model) else { return nil }

        let formatted = Self.fallbackTurn(Self.prompt(for: raw))
        let tokens = tokenize(vocab: vocab, text: formatted, addBOS: false)
        guard !tokens.isEmpty else { return nil }

        llama_memory_clear(llama_get_memory(context), true)

        var batch = llama_batch_init(max(Int32(tokens.count), 1), 0, 1)
        defer { llama_batch_free(batch) }

        batch.n_tokens = Int32(tokens.count)
        for (i, token) in tokens.enumerated() {
            batch.token[i] = token
            batch.pos[i] = Int32(i)
            batch.n_seq_id[i] = 1
            if let seq_id = batch.seq_id[i] { seq_id[0] = 0 }
            batch.logits[i] = i == tokens.count - 1 ? 1 : 0
        }
        guard llama_decode(context, batch) == 0 else { return nil }

        var sparams = llama_sampler_chain_default_params()
        guard let smpl = llama_sampler_chain_init(sparams) else { return nil }
        defer { llama_sampler_free(smpl) }
        llama_sampler_chain_add(smpl, llama_sampler_init_greedy())

        var pieceBuf: [CChar] = []
        var output = ""
        var nCur = batch.n_tokens
        for _ in 0..<160 {
            let id = llama_sampler_sample(smpl, context, batch.n_tokens - 1)
            if llama_vocab_is_eog(vocab, id) { break }
            if let piece = piece(vocab: vocab, token: id, buffer: &pieceBuf) {
                output += piece
            }
            if let brace = output.lastIndex(of: "}"), brace >= output.startIndex {
                break
            }

            batch.n_tokens = 1
            batch.token[0] = id
            batch.pos[0] = nCur
            batch.n_seq_id[0] = 1
            if let seq_id = batch.seq_id[0] { seq_id[0] = 0 }
            batch.logits[0] = 1
            nCur += 1
            guard llama_decode(context, batch) == 0 else { break }
        }
        return DictationCandidate(raw: raw, modelJSON: output)
    }

    private func tokenize(vocab: OpaquePointer, text: String, addBOS: Bool) -> [llama_token] {
        let utf8 = Array(text.utf8)
        let cap = utf8.count + 8
        var tokens = [llama_token](repeating: 0, count: cap)
        let n = text.withCString { ptr in
            llama_tokenize(vocab, ptr, Int32(utf8.count), &tokens, Int32(cap), addBOS, true)
        }
        if n < 0 {
            let need = Int(-n)
            tokens = [llama_token](repeating: 0, count: need)
            let m = text.withCString { ptr in
                llama_tokenize(vocab, ptr, Int32(utf8.count), &tokens, Int32(need), addBOS, true)
            }
            guard m > 0 else { return [] }
            return Array(tokens.prefix(Int(m)))
        }
        guard n > 0 else { return [] }
        return Array(tokens.prefix(Int(n)))
    }

    private func piece(vocab: OpaquePointer, token: llama_token, buffer: inout [CChar]) -> String? {
        var result = [CChar](repeating: 0, count: 16)
        var n = llama_token_to_piece(vocab, token, &result, Int32(result.count), 0, false)
        if n < 0 {
            result = [CChar](repeating: 0, count: Int(-n))
            n = llama_token_to_piece(vocab, token, &result, Int32(result.count), 0, false)
        }
        guard n > 0 else { return nil }
        result = Array(result.prefix(Int(n)))
        if buffer.isEmpty, let s = String(cString: result + [0], encoding: .utf8) {
            return s
        }
        buffer.append(contentsOf: result)
        let data = Data(buffer.map { UInt8(bitPattern: $0) })
        if let s = String(data: data, encoding: .utf8) {
            buffer = []
            return s
        }
        if buffer.count >= 4 { buffer = [] }
        return nil
    }

    private static func prompt(for raw: String) -> String {
        """
        You are the language layer of a field medical app. You may only structure a dictated transcript into JSON. You must not compute, compare, decide, dose, or invent clinical content. If a field is not stated, use null.

        Pick one intervention:
        Reposition | Tourniquet check | Wound packing | Erythema margin marked | Urine volume | Pain score | Chest seal check | Dressing inspection | Unclassified — held as narrative

        Return only JSON: {"intervention":"...","site":null}

        Transcript:
        \(raw)
        """
    }

    private static func fallbackTurn(_ user: String) -> String {
        "<bos><start_of_turn>user\n\(user)<end_of_turn>\n<start_of_turn>model\n"
    }

    private struct RuntimeError: Error, LocalizedError {
        let errorDescription: String?
        init(_ message: String) { errorDescription = message }
    }
}
