import UIKit

class KeyboardDetectionHelper {
    static let shared = KeyboardDetectionHelper()

    private init() {}

    /// Check if the Keyboard Copilot keyboard is enabled in system settings
    func isKeyboardEnabled() -> Bool {
        guard let appBundleIdentifier = Bundle.main.bundleIdentifier else {
            NSLog("❌ KeyboardDetection: No bundle identifier")
            return false
        }

        // The keyboard extension has .keyboard suffix based on project settings
        let keyboardBundleID = "\(appBundleIdentifier).keyboard"
        NSLog("🔍 KeyboardDetection: App bundle ID: \(appBundleIdentifier)")
        NSLog("🔍 KeyboardDetection: Looking for keyboard bundle ID: \(keyboardBundleID)")

        // Get all active input modes
        let activeInputModes = UITextInputMode.activeInputModes
        NSLog("🔍 KeyboardDetection: Active input modes count: \(activeInputModes.count)")

        for mode in activeInputModes {
            if let identifier = mode.value(forKey: "identifier") as? String {
                NSLog("🔍 KeyboardDetection: Found input mode: \(identifier)")
                if identifier.contains(keyboardBundleID) {
                    NSLog("✅ KeyboardDetection: Keyboard is enabled!")
                    return true
                }
            }
        }

        NSLog("❌ KeyboardDetection: Keyboard not found in active input modes")
        return false
    }

    /// Check if Full Access is granted (requires checking UserDefaults in app group)
    func hasFullAccess() -> Bool {
        // Check if we can access shared UserDefaults (requires Full Access)
        guard let appGroup = getAppGroupIdentifier() else { return false }
        let sharedDefaults = UserDefaults(suiteName: appGroup)
        return sharedDefaults != nil
    }

    private func getAppGroupIdentifier() -> String? {
        // Extract from entitlements or use hardcoded value
        // For now, return nil as we'll implement this when setting up app groups
        return nil
    }
}
