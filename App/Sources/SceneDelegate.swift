import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)

        // Create root view controller with app root view
        let rootView = AppRootView()
        let hostingController = UIHostingController(rootView: rootView)

        window.rootViewController = hostingController
        window.makeKeyAndVisible()
        self.window = window
    }
}

// Root view that handles onboarding vs home screen
struct AppRootView: View {
    @StateObject private var appState = AppState.shared

    var body: some View {
        ZStack {
            if appState.hasCompletedOnboarding {
                HomeView()
            } else {
                OnboardingCoordinator(isPresented: .constant(true))
            }
        }
        .onAppear {
            NSLog("👀 AppRootView appeared - hasCompletedOnboarding: \(appState.hasCompletedOnboarding)")
        }
    }
}
