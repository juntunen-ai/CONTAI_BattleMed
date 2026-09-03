import SwiftUI

@main
struct MedicalAIApp: App {
    @StateObject private var ledger = LedgerStore()
    @StateObject private var clock = MissionClock()
    @StateObject private var voice = VoiceService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(ledger)
                .environmentObject(clock)
                .environmentObject(voice)
                .preferredColorScheme(.dark)
                .statusBarHidden(false)
        }
    }
}
