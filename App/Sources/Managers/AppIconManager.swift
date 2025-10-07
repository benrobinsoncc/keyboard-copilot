import UIKit

class AppIconManager {
    static let shared = AppIconManager()

    private init() {}

    /// Set the app icon to the specified name
    /// - Parameter iconName: The name of the icon as specified in Info.plist CFBundleAlternateIcons
    func setIcon(named iconName: String) {
        guard UIApplication.shared.supportsAlternateIcons else {
            print("⚠️ Alternate icons are not supported on this device")
            return
        }

        // If trying to set to default, pass nil
        let alternateIconName: String? = iconName == "default" ? nil : iconName

        UIApplication.shared.setAlternateIconName(alternateIconName) { error in
            if let error = error {
                print("❌ Error setting alternate icon: \(error.localizedDescription)")
            } else {
                print("✅ Successfully set app icon to: \(iconName)")
            }
        }
    }

    /// Get the current app icon name
    func getCurrentIconName() -> String {
        return UIApplication.shared.alternateIconName ?? "default"
    }
}
