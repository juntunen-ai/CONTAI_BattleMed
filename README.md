# BattleMed — CONTAI_BattleMed

**v0.1.0 PoC** · [juntunen-ai/CONTAI_BattleMed](https://github.com/juntunen-ai/CONTAI_BattleMed)

Native iOS SwiftUI spine for the CONTAI BattleMed MedPod programme: mission clock, append-only ledger, outcome-gated protocol cards with spoken read-back, handover packet, and optional on-device Gemma structuring.

Programme deliverables **D1** (lone casualty), **D2** (MedPod hardware), **D3** (MVP app) are documented under [`docs/medpod/`](docs/medpod/).

## Run it

1. Open `MedicalAI.xcodeproj` in Xcode 16 or later (folder / target name remains `MedicalAI` for signing continuity).
2. Select the **MedicalAI** scheme and your iPhone as the destination.
3. Signing is unchanged: team `647W3RAYL3`, bundle `ai.juntunen.medicalai`. Display name is **BattleMed**. Forks should change the bundle id and team.
4. Run. On the phone, Settings → General → VPN & Device Management → trust the developer certificate.

If the project file ever gets out of step, `project.yml` regenerates it with XcodeGen (`brew install xcodegen && xcodegen generate`).

## What is real

- **Speech output.** `AVSpeechSynthesizer` reads protocol cards and the handover packet aloud, verbatim from the bundle.
- **The clock.** 72-hour hold. Gates (including oral care, cognitive check, extraction log) are plain Swift, sorted by urgency. Tourniquet hard-locks past 6 h.
- **The ledger.** Append-only, checkpointed with `.completeFileProtection`, survives relaunch.
- **The handover.** ATMIST from the live ledger, QR on device via Core Image. Nothing transmitted.
- **Gemma (optional).** `GemmaService` can structure a transcript on device via [LlamaSwift](https://github.com/mattt/llama.swift). **GGUF weights are not in git** — download once into Application Support / Documents, or keyword fallback stays on.

## What is stubbed, and why

Without Gemma weights (or while loading), dictation falls back to keyword structuring. The calculation firewall is unchanged: the language layer may only structure language; Swift owns timers, doses, gates, and ledger commits.

## Structure

| Path | Role |
| --- | --- |
| `MedicalAI/ProtocolBundle.swift` | Versioned doctrine cards (fixed doses only). |
| `MedicalAI/MissionClock.swift` | Gate state machines · 72 h hold. |
| `MedicalAI/LedgerStore.swift` | Append-only durable store. |
| `MedicalAI/VoiceService.swift` | Speech out + SpeechAnalyzer dictation. |
| `MedicalAI/GemmaService.swift` | On-device structuring (weights not shipped). |
| `MedicalAI/CognitiveScreen.swift` | Timed serial-3 cognitive micro-task. |
| `docs/medpod/` | PoC annotated spec, psych/BOM amendments, briefing. |

## License

Proprietary. Copyright © 2026 Harri Juntunen. All rights reserved.
No third-party use. Commercial use is prohibited. See `LICENSE`.
