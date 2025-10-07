import SwiftUI

@MainActor
class AppState: ObservableObject {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("currentOnboardingStep") var currentOnboardingStep: String = "welcome"
    @AppStorage("selectedTheme") var selectedTheme: String = "auto"
    @AppStorage("selectedAppIcon") var selectedAppIcon: String = "default"

    static let shared = AppState()

    private init() {}

    func resetOnboarding() {
        hasCompletedOnboarding = false
        currentOnboardingStep = "welcome"
    }
}
