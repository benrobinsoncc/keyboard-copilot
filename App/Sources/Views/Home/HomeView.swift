import SwiftUI
import StoreKit
import MessageUI

struct HomeView: View {
    @StateObject private var appState = AppState.shared
    @State private var showingOnboarding = false
    @State private var isKeyboardActive = false
    @State private var showingHowToUse = false
    @State private var showingAppIcon = false
    @State private var showingTheme = false
    @State private var showingFeedback = false
    @State private var showingSupport = false
    @AppStorage("isShowingOnboardingFromHome") private var isShowingOnboardingFromHome = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Status Section
                    HStack(spacing: 12) {
                        Image(systemName: isKeyboardActive ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(isKeyboardActive ? .green : .orange)

                        Text(isKeyboardActive ? "Keyboard active" : "Keyboard inactive")
                            .font(.headline)
                            .foregroundStyle(isKeyboardActive ? .green : .orange)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Setup Section
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Setup")
                            .font(.caption)
                            .textCase(.uppercase)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)

                        VStack(spacing: 0) {
                            Button(action: {
                                showingHowToUse = true
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "keyboard.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color(uiColor: .label))
                                        .frame(width: 28, height: 28)
                                        .background(Circle().fill(Color(uiColor: .secondarySystemFill)))
                                    Text("How to use")
                                        .foregroundStyle(Color(uiColor: .label))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color(uiColor: .tertiaryLabel))
                                }
                                .padding(.leading, 12)
                                .padding(.trailing, 16)
                                .padding(.vertical, 12)
                            }

                            Divider()
                                .padding(.leading, 52)

                            Button(action: {
                                // Reset to start of onboarding when manually opening it
                                appState.currentOnboardingStep = "welcome"
                                showingOnboarding = true
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "questionmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color(uiColor: .label))
                                        .frame(width: 28, height: 28)
                                        .background(Circle().fill(Color(uiColor: .secondarySystemFill)))
                                    Text("Show onboarding")
                                        .foregroundStyle(Color(uiColor: .label))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color(uiColor: .tertiaryLabel))
                                }
                                .padding(.leading, 12)
                                .padding(.trailing, 16)
                                .padding(.vertical, 12)
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                        )
                        .padding(.horizontal, 16)
                    }

                    // Customization Section
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Customise")
                            .font(.caption)
                            .textCase(.uppercase)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)

                        VStack(spacing: 0) {
                            Button(action: {
                                showingAppIcon = true
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "photo.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color(uiColor: .label))
                                        .frame(width: 28, height: 28)
                                        .background(Circle().fill(Color(uiColor: .secondarySystemFill)))
                                    Text("App icon")
                                        .foregroundStyle(Color(uiColor: .label))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color(uiColor: .tertiaryLabel))
                                }
                                .padding(.leading, 12)
                                .padding(.trailing, 16)
                                .padding(.vertical, 12)
                            }

                            Divider()
                                .padding(.leading, 52)

                            Button(action: {
                                showingTheme = true
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "paintbrush.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color(uiColor: .label))
                                        .frame(width: 28, height: 28)
                                        .background(Circle().fill(Color(uiColor: .secondarySystemFill)))
                                    Text("Theme")
                                        .foregroundStyle(Color(uiColor: .label))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color(uiColor: .tertiaryLabel))
                                }
                                .padding(.leading, 12)
                                .padding(.trailing, 16)
                                .padding(.vertical, 12)
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                        )
                        .padding(.horizontal, 16)
                    }

                    // Support Section
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Support")
                            .font(.caption)
                            .textCase(.uppercase)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)

                        VStack(spacing: 0) {
                            Button(action: shareApp) {
                                HStack(spacing: 12) {
                                    Image(systemName: "square.and.arrow.up.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color(uiColor: .label))
                                        .frame(width: 28, height: 28)
                                        .background(Circle().fill(Color(uiColor: .secondarySystemFill)))
                                    Text("Share app")
                                        .foregroundStyle(Color(uiColor: .label))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color(uiColor: .tertiaryLabel))
                                }
                                .padding(.leading, 12)
                                .padding(.trailing, 16)
                                .padding(.vertical, 12)
                            }

                            Divider()
                                .padding(.leading, 52)

                            Button(action: requestReview) {
                                HStack(spacing: 12) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color(uiColor: .label))
                                        .frame(width: 28, height: 28)
                                        .background(Circle().fill(Color(uiColor: .secondarySystemFill)))
                                    Text("Rate us")
                                        .foregroundStyle(Color(uiColor: .label))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color(uiColor: .tertiaryLabel))
                                }
                                .padding(.leading, 12)
                                .padding(.trailing, 16)
                                .padding(.vertical, 12)
                            }

                            Divider()
                                .padding(.leading, 52)

                            Button(action: {
                                showingFeedback = true
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "bubble.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color(uiColor: .label))
                                        .frame(width: 28, height: 28)
                                        .background(Circle().fill(Color(uiColor: .secondarySystemFill)))
                                    Text("Send feedback")
                                        .foregroundStyle(Color(uiColor: .label))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color(uiColor: .tertiaryLabel))
                                }
                                .padding(.leading, 12)
                                .padding(.trailing, 16)
                                .padding(.vertical, 12)
                            }

                            Divider()
                                .padding(.leading, 52)

                            Button(action: {
                                showingSupport = true
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "envelope.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color(uiColor: .label))
                                        .frame(width: 28, height: 28)
                                        .background(Circle().fill(Color(uiColor: .secondarySystemFill)))
                                    Text("Contact support")
                                        .foregroundStyle(Color(uiColor: .label))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color(uiColor: .tertiaryLabel))
                                }
                                .padding(.leading, 12)
                                .padding(.trailing, 16)
                                .padding(.vertical, 12)
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                        )
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 20)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Keyboard Copilot")
            .onAppear {
                checkKeyboardStatus()
                // Restore onboarding sheet if it was showing when app went to background
                NSLog("🏠 HomeView onAppear - isShowingOnboardingFromHome: \(isShowingOnboardingFromHome), showingOnboarding: \(showingOnboarding)")
                if isShowingOnboardingFromHome && !showingOnboarding {
                    NSLog("🏠 Restoring onboarding sheet")
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        showingOnboarding = true
                    }
                }
            }
            .fullScreenCover(isPresented: $showingOnboarding) {
                NSLog("🎬 Creating OnboardingCoordinator")
                return OnboardingCoordinator(isPresented: $showingOnboarding)
                    .id("onboarding-flow")
            }
            .onChange(of: showingOnboarding) { newValue in
                isShowingOnboardingFromHome = newValue
            }
            .sheet(isPresented: $showingHowToUse) {
                NavigationStack {
                    KeyboardTestView(onComplete: { showingHowToUse = false }, onSkip: { showingHowToUse = false })
                }
            }
            .sheet(isPresented: $showingAppIcon) {
                NavigationStack {
                    LogoSelectionView(onContinue: { showingAppIcon = false }, isOnboarding: false)
                }
            }
            .sheet(isPresented: $showingTheme) {
                NavigationStack {
                    ThemeSelectionView(onContinue: { showingTheme = false }, isOnboarding: false)
                }
            }
            .sheet(isPresented: $showingFeedback) {
                MailComposeView(recipient: "benrobinsoncc@gmail.com", subject: "Feedback for Keyboard Copilot", isPresented: $showingFeedback)
            }
            .sheet(isPresented: $showingSupport) {
                MailComposeView(recipient: "benrobinsoncc@gmail.com", subject: "Support request for Keyboard Copilot", isPresented: $showingSupport)
            }
        }
    }

    private func checkKeyboardStatus() {
        isKeyboardActive = KeyboardDetectionHelper.shared.isKeyboardEnabled()
    }

    private func requestReview() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }

    private func shareApp() {
        // Share app link
        let appURL = URL(string: "https://apps.apple.com/app/keyboard-copilot")! // Replace with actual App Store link
        let activityVC = UIActivityViewController(activityItems: [appURL], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

#Preview {
    HomeView()
}
