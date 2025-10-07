import SwiftUI

struct AppIconOption: Identifiable {
    let id: String
    let displayName: String
    let iconName: String // Name in Info.plist alternate icons
    let previewImageName: String // Asset name for preview

    static let options: [AppIconOption] = [
        AppIconOption(id: "default", displayName: "Default", iconName: "default", previewImageName: "AppIcon"),
        AppIconOption(id: "dark", displayName: "Dark", iconName: "AppIcon-Dark", previewImageName: "AppIcon-Dark"),
        AppIconOption(id: "minimal", displayName: "Minimal", iconName: "AppIcon-Minimal", previewImageName: "AppIcon-Minimal"),
        AppIconOption(id: "gradient", displayName: "Gradient", iconName: "AppIcon-Gradient", previewImageName: "AppIcon-Gradient")
    ]
}

struct LogoSelectionView: View {
    let onContinue: () -> Void
    var isOnboarding: Bool = true
    @StateObject private var appState = AppState.shared
    @State private var selectedIcon: String = "default"

    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("Pick your logo")
                .font(.largeTitle.weight(.bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 32)

            // Grid of logo options
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(AppIconOption.options) { option in
                        LogoOptionView(
                            option: option,
                            isSelected: selectedIcon == option.id
                        )
                        .onTapGesture {
                            HapticFeedbackManager.shared.selection()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedIcon = option.id
                            }
                            appState.selectedAppIcon = option.id
                            AppIconManager.shared.setIcon(named: option.iconName)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }

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
        .onAppear {
            selectedIcon = appState.selectedAppIcon
        }
    }
}

struct LogoOptionView: View {
    let option: AppIconOption
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 12) {
            // Icon preview with selection ring
            ZStack {
                // Selection ring (2px gap + 2px stroke)
                if isSelected {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.primary, lineWidth: 2)
                        .frame(width: 84, height: 84)
                }

                // Icon placeholder
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 76, height: 76)
                    .overlay(
                        Image(systemName: "app.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.primary)
                    )
            }
            .frame(height: 84)

            // Label
            Text(option.displayName)
                .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    LogoSelectionView(onContinue: {})
}
