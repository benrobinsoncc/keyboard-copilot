import KeyboardKit
import SwiftUI
import WebKit
import Combine

private class CopilotActionState: ObservableObject {
    @Published var showingActionView = false
    @Published var actionViewContent: AnyView?
    @Published var actionButtonText = "Insert"
    @Published var actionButtonIcon = "arrow.down.circle"
    @Published var currentURL: URL?
}

private struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Only load if URL has changed
        if uiView.url != url {
            uiView.load(URLRequest(url: url))
        }
    }
}

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

private struct CopilotActionView: View {
    let actionButtonText: String
    let actionButtonIcon: String
    let onAction: () -> Void
    let onCancel: () -> Void
    let content: AnyView

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Content area
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Divider with 12px spacing above action bar
                Color.gray.opacity(0.2)
                    .frame(height: 1)
                    .padding(.bottom, 12)

                // Action bar
                HStack {
                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 32, height: 32)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.gray.opacity(0.1))
                            )
                    }

                    Spacer()

                    Button(action: onAction) {
                        HStack(spacing: 6) {
                            Image(systemName: actionButtonIcon)
                                .font(.system(size: 12, weight: .semibold))
                            Text(actionButtonText)
                                .font(.system(size: 15, weight: .regular))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .frame(height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.black)
                        )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
            .background(Color.white)
            .cornerRadius(16)
            .frame(height: geometry.size.height)
        }
        .frame(maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
    }
}

private struct CopilotKeyboardView: View {
    let services: Keyboard.Services
    let state: Keyboard.State
    let onWriteSelection: (CopilotWriteAction) -> Void
    let onRewriteSelection: (CopilotRewriteAction) -> Void
    let onSearchSelection: (CopilotSearchAction) -> Void
    let onOpenURL: ((URL) -> Void)?

    @ObservedObject var actionState: CopilotActionState

    var body: some View {
        ZStack {
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
            .opacity(actionState.showingActionView ? 0 : 1)

            if actionState.showingActionView, let content = actionState.actionViewContent {
                CopilotActionView(
                    actionButtonText: actionState.actionButtonText,
                    actionButtonIcon: actionState.actionButtonIcon,
                    onAction: {
                        if let url = actionState.currentURL {
                            onOpenURL?(url)
                        }
                        actionState.showingActionView = false
                        actionState.actionViewContent = nil
                        actionState.currentURL = nil
                    },
                    onCancel: {
                        actionState.showingActionView = false
                        actionState.actionViewContent = nil
                        actionState.currentURL = nil
                    },
                    content: content
                )
                .padding(.horizontal, 6)
                .padding(.top, 6)
                .onDisappear {
                    // This will be called but we need to handle constraint removal in the view controller
                }
            }
        }
    }
}

final class KeyboardViewController: KeyboardInputViewController {

    private let actionState = CopilotActionState()
    private var heightConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()

        setup(for: .keyboardCopilot) { result in
            if case .failure(let error) = result {
                NSLog("Keyboard Copilot setup failed: \(error.localizedDescription)")
            }
        }

        // Observe action state changes to manage keyboard height
        actionState.$showingActionView.sink { [weak self] isShowing in
            if !isShowing {
                self?.removeHeightConstraint()
            }
        }.store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

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
                },
                onOpenURL: { url in
                    self?.openURL(url)
                },
                actionState: self?.actionState ?? CopilotActionState()
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

        switch action {
        case .google:
            showGoogleSearch()
        case .explain, .factCheck:
            // TODO: Implement these actions later
            break
        }
    }

    private func showGoogleSearch() {
        // Get the current text from the text field
        guard let textProxy = textDocumentProxy as? UITextDocumentProxy else { return }
        let searchText = textProxy.documentContextBeforeInput ?? ""

        // Encode the search query
        guard let encodedQuery = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let searchURL = URL(string: "https://www.google.com/search?q=\(encodedQuery)") else {
            return
        }

        // Expand keyboard height for better WebView interaction
        removeHeightConstraint()
        let constraint = NSLayoutConstraint(
            item: view!,
            attribute: .height,
            relatedBy: .equal,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 1.0,
            constant: 500
        )
        constraint.priority = .required
        view.addConstraint(constraint)
        heightConstraint = constraint

        // Show the WebView in the action view with "Open" button
        let webView = WebView(url: searchURL)
        actionState.actionViewContent = AnyView(webView)
        actionState.actionButtonText = "Open"
        actionState.actionButtonIcon = "safari"
        actionState.currentURL = searchURL
        actionState.showingActionView = true
    }

    private func removeHeightConstraint() {
        if let constraint = heightConstraint {
            view.removeConstraint(constraint)
            heightConstraint = nil
        }
    }

    private func openURL(_ url: URL) {
        // Use the extension context's open method to open URLs in keyboard extensions
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                application.open(url, options: [:], completionHandler: nil)
                return
            }
            responder = responder?.next
        }

        // Fallback: Use the openURL method through the extension context
        extensionContext?.open(url, completionHandler: nil)
    }
}
