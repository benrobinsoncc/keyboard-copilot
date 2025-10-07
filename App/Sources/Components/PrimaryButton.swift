import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true

    var body: some View {
        Button(action: {
            HapticFeedbackManager.shared.impact(style: .medium)
            action()
        }) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isEnabled ? Color.accentColor : Color.gray)
                )
        }
        .disabled(!isEnabled)
        .buttonStyle(.plain)
    }
}
