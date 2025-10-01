import Foundation

enum CopilotIntent {
    case write
    case search

    var placeholderText: String {
        switch self {
        case .write:
            return "AI Write Placeholder"
        case .search:
            return "AI Search Placeholder"
        }
    }
}

/// Encapsulates placeholder responses so real integrations can drop in later.
struct CopilotPlaceholderProvider {
    func placeholderText(for intent: CopilotIntent) -> String {
        intent.placeholderText
    }
}
