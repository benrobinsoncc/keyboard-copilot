import SwiftUI

struct ThemeSelectionView: View {
    let onContinue: () -> Void
    var isOnboarding: Bool = true
    @AppStorage("selectedTheme") private var selectedTheme: String = "auto"

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("Pick your theme")
                .font(.largeTitle.weight(.bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 32)

            // Theme options
            VStack(spacing: 16) {
                ThemeOption(
                    title: "Auto",
                    description: "Match system settings",
                    icon: "circle.lefthalf.filled",
                    isSelected: selectedTheme == "auto"
                ) {
                    selectedTheme = "auto"
                }

                ThemeOption(
                    title: "Light",
                    description: "Always light mode",
                    icon: "sun.max.fill",
                    isSelected: selectedTheme == "light"
                ) {
                    selectedTheme = "light"
                }

                ThemeOption(
                    title: "Dark",
                    description: "Always dark mode",
                    icon: "moon.fill",
                    isSelected: selectedTheme == "dark"
                ) {
                    selectedTheme = "dark"
                }
            }
            .padding(.horizontal, 20)

            Spacer()

            // Continue button (only show during onboarding)
            if isOnboarding {
                PrimaryButton(title: "Continue") {
                    onContinue()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 50)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
        .toolbar {
            if !isOnboarding {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onContinue()
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ThemeOption: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedbackManager.shared.selection()
            action()
        }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Color.primary)

                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ThemeSelectionView(onContinue: {})
}
