import KeyboardKit
import SwiftUI

private enum CopilotWriteAction: String, CaseIterable, Identifiable {
    case compose = "Compose"
    case rewrite = "Rewrite"
    case shortcuts = "Shortcuts"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .compose: return "sparkles"
        case .rewrite: return "arrow.triangle.2.circlepath"
        case .shortcuts: return "line.3.horizontal"
        }
    }
}

private enum CopilotRewriteAction: String, CaseIterable, Identifiable {
    case polish = "Polish"
    case shorten = "Shorten"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .polish: return "checkmark.seal"
        case .shorten: return "text.badge.minus"
        }
    }
}

private enum CopilotSearchAction: String, CaseIterable, Identifiable {
    case google = "Google"
    case explain = "Explain"
    case factCheck = "Fact check"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .google: return "arrow.up.forward.square"
        case .explain: return "lightbulb"
        case .factCheck: return "checkmark.shield"
        }
    }
}

private struct CopilotActionBar: View {
    let selectedText: String?
    let onWriteSelection: (CopilotWriteAction) -> Void
    let onRewriteSelection: (CopilotRewriteAction) -> Void
    let onSearchSelection: (CopilotSearchAction) -> Void

    var body: some View {
        HStack(spacing: 6) {
            writeMenu
            searchMenu
        }
        .padding(.horizontal, 8)
        .padding(.top, 9)
        .padding(.bottom, 4)
    }

    private var writeMenu: some View {
        Menu {
            Button(action: { onWriteSelection(.compose) }) {
                Label("Compose", systemImage: "sparkles")
            }

            Button(action: { onRewriteSelection(.polish) }) {
                Label("Polish", systemImage: "checkmark.seal")
            }

            Button(action: { onRewriteSelection(.shorten) }) {
                Label("Shorten", systemImage: "text.badge.minus")
            }

            Button(action: { onWriteSelection(.shortcuts) }) {
                Label("Shortcuts", systemImage: "line.3.horizontal")
            }
        } label: {
            pillLabel(symbol: "square.and.pencil", title: "Write")
        }
        .menuOrder(.fixed)
        .menuStyle(.borderlessButton)
    }

    private var searchMenu: some View {
        Menu {
            Button(action: { onSearchSelection(.google) }) {
                Label("Google", systemImage: "arrow.up.forward.square")
            }
            Button(action: { onSearchSelection(.explain) }) {
                Label("Explain", systemImage: "lightbulb")
            }
            Button(action: { onSearchSelection(.factCheck) }) {
                Label("Fact check", systemImage: "checkmark.shield")
            }
        } label: {
            pillLabel(symbol: "magnifyingglass", title: "Search")
        }
        .menuOrder(.fixed)
        .menuStyle(.borderlessButton)
    }

    private func pillLabel(symbol: String, title: String) -> some View {
        VStack(spacing: 1) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .semibold))
            Text(title)
                .font(.system(size: 15, weight: .regular))
            }
            .foregroundStyle(Color.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 32)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
            )

            Color.clear.frame(height: 1)
        }
    }
}

private struct CopilotKeyboardView: View {
    let services: Keyboard.Services
    let state: Keyboard.State
    let onWriteSelection: (CopilotWriteAction) -> Void
    let onRewriteSelection: (CopilotRewriteAction) -> Void
    let onSearchSelection: (CopilotSearchAction) -> Void

    var body: some View {
        KeyboardView(
            layout: nil,
            state: state,
            services: services,
            renderBackground: true,
            buttonContent: { $0.view },
            buttonView: { $0.view },
            collapsedView: { $0.view },
            emojiKeyboard: { $0.view },
            toolbar: { _ in
                CopilotActionBar(
                    selectedText: nil,
                    onWriteSelection: onWriteSelection,
                    onRewriteSelection: onRewriteSelection,
                    onSearchSelection: onSearchSelection
                )
            }
        )
    }
}

final class KeyboardViewController: KeyboardInputViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        setup(for: .keyboardCopilot) { result in
            if case .failure(let error) = result {
                NSLog("Keyboard Copilot setup failed: \(error.localizedDescription)")
            }
        }
    }

    override func viewWillSetupKeyboardView() {
        setupKeyboardView { [weak self] controller in
            CopilotKeyboardView(
                services: controller.services,
                state: controller.state,
                onWriteSelection: { action in
                    self?.handleWriteSelection(action)
                },
                onRewriteSelection: { action in
                    self?.handleRewriteSelection(action)
                },
                onSearchSelection: { action in
                    self?.handleSearchSelection(action)
                }
            )
        }
    }

    private func handleWriteSelection(_ action: CopilotWriteAction) {
        NSLog("Selected write action: \(action.rawValue)")
    }

    private func handleRewriteSelection(_ action: CopilotRewriteAction) {
        NSLog("Selected rewrite action: \(action.rawValue)")
    }

    private func handleSearchSelection(_ action: CopilotSearchAction) {
        NSLog("Selected search action: \(action.rawValue)")
    }
}
