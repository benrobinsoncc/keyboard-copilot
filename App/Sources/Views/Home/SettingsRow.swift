import SwiftUI

struct SettingsRow: View {
    let icon: String
    let title: String
    let iconColor: Color
    let action: () -> Void

    init(icon: String, title: String, iconColor: Color = .primary, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.iconColor = iconColor
        self.action = action
    }

    var body: some View {
        Button(action: {
            HapticFeedbackManager.shared.impact(style: .light)
            action()
        }) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
                    .frame(width: 28)

                // Title
                Text(title)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.primary)

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(uiColor: .systemBackground))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack {
        SettingsRow(icon: "questionmark.circle", title: "Show Onboarding") {}
        SettingsRow(icon: "paintbrush", title: "Theme", iconColor: .blue) {}
        SettingsRow(icon: "app", title: "App Icon", iconColor: .orange) {}
    }
}
