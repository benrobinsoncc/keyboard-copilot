import SwiftUI

enum OnboardingStep {
    case welcome
    case appIcon
    case theme
    case keyboardSetup
    case tryKeyboard
}

struct OnboardingCoordinator: View {
    @Binding var isPresented: Bool
    @StateObject private var appState = AppState.shared
    @AppStorage("isShowingOnboardingFromHome") private var isShowingOnboardingFromHome = false

    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented

        // Initialize navigation path from saved state
        let appState = AppState.shared
        let savedStep = appState.currentOnboardingStep
        NSLog("🔧 OnboardingCoordinator init with savedStep: \(savedStep)")
        var path = NavigationPath()

        let steps: [OnboardingStep]
        switch savedStep {
        case "tryKeyboard":
            steps = [.appIcon, .theme, .keyboardSetup, .tryKeyboard]
        case "keyboardSetup":
            steps = [.appIcon, .theme, .keyboardSetup]
        case "theme":
            steps = [.appIcon, .theme]
        case "appIcon":
            steps = [.appIcon]
        default:
            steps = []
        }

        NSLog("🔧 Initializing path with \(steps.count) steps")
        for step in steps {
            path.append(step)
        }

        self._navigationPath = State(initialValue: path)
    }

    @State private var navigationPath: NavigationPath

    var body: some View {
        NavigationStack(path: $navigationPath) {
            WelcomeView {
                saveStep(.appIcon)
                navigationPath.append(OnboardingStep.appIcon)
            }
            .navigationBarBackButtonHidden()
            .navigationDestination(for: OnboardingStep.self) { step in
                switch step {
                case .welcome:
                    WelcomeView {
                        saveStep(.appIcon)
                        navigationPath.append(OnboardingStep.appIcon)
                    }
                case .appIcon:
                    LogoSelectionView {
                        saveStep(.theme)
                        navigationPath.append(OnboardingStep.theme)
                    }
                case .theme:
                    ThemeSelectionView {
                        saveStep(.keyboardSetup)
                        navigationPath.append(OnboardingStep.keyboardSetup)
                    }
                case .keyboardSetup:
                    KeyboardSetupView(onContinue: {
                        saveStep(.tryKeyboard)
                        navigationPath.append(OnboardingStep.tryKeyboard)
                    }, onSkip: {
                        saveStep(.tryKeyboard)
                        navigationPath.append(OnboardingStep.tryKeyboard)
                    })
                case .tryKeyboard:
                    KeyboardTestView(onComplete: {
                        completeOnboarding()
                    }, onSkip: {
                        completeOnboarding()
                    })
                }
            }
        }
        .interactiveDismissDisabled()
    }

    private func completeOnboarding() {
        // If showing from HomeView, just dismiss the sheet
        if isShowingOnboardingFromHome {
            isShowingOnboardingFromHome = false
            isPresented = false
            appState.currentOnboardingStep = "welcome" // Reset for next time
        } else {
            // First-time onboarding completion
            appState.hasCompletedOnboarding = true
            appState.currentOnboardingStep = "welcome" // Reset for next time
        }
    }

    private func saveStep(_ step: OnboardingStep) {
        appState.currentOnboardingStep = stepToString(step)
        NSLog("💾 Saved onboarding step: \(stepToString(step))")
    }

    private func stepToString(_ step: OnboardingStep) -> String {
        switch step {
        case .welcome: return "welcome"
        case .appIcon: return "appIcon"
        case .theme: return "theme"
        case .keyboardSetup: return "keyboardSetup"
        case .tryKeyboard: return "tryKeyboard"
        }
    }
}

#Preview {
    OnboardingCoordinator(isPresented: .constant(true))
}
