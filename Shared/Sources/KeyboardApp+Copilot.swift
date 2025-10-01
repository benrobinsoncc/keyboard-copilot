import Foundation
import KeyboardKit

extension KeyboardApp {
    /// Defines the base configuration shared by the host app and keyboard extension.
    static var keyboardCopilot: KeyboardApp {
        .init(
            name: "Keyboard Copilot",
            locales: [.init(identifier: "en")]
        )
    }
}
