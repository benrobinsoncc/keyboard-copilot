import SwiftUI
import AVKit

struct KeyboardSetupView: View {
    let onContinue: () -> Void
    let onSkip: () -> Void
    @State private var isKeyboardEnabled = false
    @State private var checkTimer: Timer?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Video player placeholder
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.secondary.opacity(0.2))
                        .aspectRatio(9/16, contentMode: .fit)
                        .frame(maxHeight: 300)
                        .overlay(
                            VStack(spacing: 12) {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundStyle(.white)
                                    .shadow(radius: 4)

                                Text("Tap to watch setup guide")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        )
                        .padding(.horizontal, 20)

                    // Written instructions
                    VStack(alignment: .leading, spacing: 14) {
                        InstructionStep(number: 1, text: "Tap \"Open settings\" button below")
                        InstructionStep(number: 2, text: "Tap \"Keyboards\"")
                        InstructionStep(number: 3, text: "Enable Keyboard Copilot & Allow Full Access")

                        Text("Don't worry — we don't collect or use your data. Your privacy is protected.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)

                    // Status indicator
                    if isKeyboardEnabled {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.green)
                            Text("Keyboard Enabled!")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                    }
                }
                .padding(.bottom, 24)
            }

            Spacer()

            // Continue button
            PrimaryButton(title: "Open settings") {
                openSettings()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 50)
        }
        .navigationTitle("Turn on keyboard")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(false)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Skip") {
                    onSkip()
                }
            }
        }
        .onAppear {
            startCheckingKeyboardStatus()
        }
        .onDisappear {
            stopCheckingKeyboardStatus()
        }
    }

    private func startCheckingKeyboardStatus() {
        // Check immediately
        checkKeyboardStatus()

        // Check periodically
        checkTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            checkKeyboardStatus()
        }
    }

    private func stopCheckingKeyboardStatus() {
        checkTimer?.invalidate()
        checkTimer = nil
    }

    private func checkKeyboardStatus() {
        let enabled = KeyboardDetectionHelper.shared.isKeyboardEnabled()
        if enabled != isKeyboardEnabled {
            withAnimation {
                isKeyboardEnabled = enabled
            }
            if enabled {
                HapticFeedbackManager.shared.notification(type: .success)
            }
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

struct InstructionStep: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("\(number)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(uiColor: .systemBackground))
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(Color(uiColor: .label))
                )

            Text(text)
                .font(.body)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    KeyboardSetupView(onContinue: {}, onSkip: {})
}
