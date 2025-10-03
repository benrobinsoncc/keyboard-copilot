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
    @Published var actionViewHeight: CGFloat = 0
    @Published var responseText: String?
    @Published var growFromBottom = false
    @Published var isCopied = false
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

private struct TextResponseView: View {
    let headerText: String
    let responseText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Text(headerText.uppercased())
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.gray)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)

            // Response text (scrollable)
            ScrollView {
                Text(responseText)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    let onReload: (() -> Void)?
    let onCopy: (() -> Void)?
    let content: AnyView
    let isCopied: Bool

    var body: some View {
        VStack(spacing: 0) {
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

                    // Show reload and copy buttons if available
                    if let onReload = onReload {
                        Button(action: onReload) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.primary)
                                .frame(width: 32, height: 32)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color.gray.opacity(0.1))
                                )
                        }
                    }

                    if let onCopy = onCopy {
                        Button(action: onCopy) {
                            ZStack {
                                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .transition(.scale.combined(with: .opacity))
                                    .id(isCopied ? "checkmark" : "copy")
                            }
                            .frame(width: 32, height: 32)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.gray.opacity(0.1))
                            )
                        }
                        .disabled(isCopied)
                    }

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
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

private struct CopilotKeyboardView: View {
    let services: Keyboard.Services
    let state: Keyboard.State
    let onWriteSelection: (CopilotWriteAction) -> Void
    let onRewriteSelection: (CopilotRewriteAction) -> Void
    let onSearchSelection: (CopilotSearchAction) -> Void
    let onOpenURL: ((URL) -> Void)?
    let onInsertText: ((String) -> Void)?
    let onReload: (() -> Void)?
    let onCopy: (() -> Void)?

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
            .animation(.easeInOut(duration: 0.3), value: actionState.showingActionView)

            if actionState.showingActionView, let content = actionState.actionViewContent {
                VStack(spacing: 0) {
                    if !actionState.growFromBottom {
                        CopilotActionView(
                            actionButtonText: actionState.actionButtonText,
                            actionButtonIcon: actionState.actionButtonIcon,
                            onAction: {
                                if let url = actionState.currentURL {
                                    onOpenURL?(url)
                                } else if let responseText = actionState.responseText {
                                    onInsertText?(responseText)
                                }
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    actionState.actionViewHeight = 0
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    actionState.showingActionView = false
                                    actionState.actionViewContent = nil
                                    actionState.currentURL = nil
                                    actionState.responseText = nil
                                    actionState.growFromBottom = false
                                }
                            },
                            onCancel: {
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    actionState.actionViewHeight = 0
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    actionState.showingActionView = false
                                    actionState.actionViewContent = nil
                                    actionState.currentURL = nil
                                    actionState.responseText = nil
                                    actionState.growFromBottom = false
                                }
                            },
                            onReload: actionState.currentURL == nil ? onReload : nil,
                            onCopy: actionState.responseText != nil ? onCopy : nil,
                            content: content,
                            isCopied: actionState.isCopied
                        )
                        .frame(height: actionState.actionViewHeight)
                        .clipped()

                        Spacer(minLength: 0)
                    } else {
                        Spacer(minLength: 0)

                        CopilotActionView(
                            actionButtonText: actionState.actionButtonText,
                            actionButtonIcon: actionState.actionButtonIcon,
                            onAction: {
                                if let url = actionState.currentURL {
                                    onOpenURL?(url)
                                } else if let responseText = actionState.responseText {
                                    onInsertText?(responseText)
                                }
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    actionState.actionViewHeight = 0
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    actionState.showingActionView = false
                                    actionState.actionViewContent = nil
                                    actionState.currentURL = nil
                                    actionState.responseText = nil
                                    actionState.growFromBottom = false
                                }
                            },
                            onCancel: {
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    actionState.actionViewHeight = 0
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    actionState.showingActionView = false
                                    actionState.actionViewContent = nil
                                    actionState.currentURL = nil
                                    actionState.responseText = nil
                                    actionState.growFromBottom = false
                                }
                            },
                            onReload: actionState.currentURL == nil ? onReload : nil,
                            onCopy: actionState.responseText != nil ? onCopy : nil,
                            content: content,
                            isCopied: actionState.isCopied
                        )
                        .frame(height: actionState.actionViewHeight)
                        .clipped()
                    }
                }
                .padding(.horizontal, 6)
                .padding(.top, 6)
                .animation(.easeInOut(duration: 0.5), value: actionState.actionViewHeight)
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
    private var currentActionType: CopilotSearchAction?
    private var currentInputText: String?

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
                onInsertText: { text in
                    self?.replaceTextWithResponse(text)
                },
                onReload: {
                    self?.handleReload()
                },
                onCopy: {
                    self?.handleCopy()
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
        case .explain:
            showExplain()
        case .factCheck:
            showFactCheck()
        }
    }

    private func getTextForAction() -> String? {
        guard let textProxy = textDocumentProxy as? UITextDocumentProxy else { return nil }

        // Priority: selected text > text before cursor
        if let selectedText = textProxy.selectedText, !selectedText.isEmpty {
            return selectedText
        }

        let contextText = textProxy.documentContextBeforeInput ?? ""
        return contextText.isEmpty ? nil : contextText
    }

    private func showExplain() {
        guard let text = getTextForAction(), !text.isEmpty else { return }

        currentActionType = .explain
        currentInputText = text

        // Placeholder response for now
        let placeholderResponse = "Metacognition is the process of thinking about your own thinking. It involves being aware of how you learn, plan, and solve problems, and adjusting your strategies to improve outcomes."

        let textResponseView = TextResponseView(
            headerText: "Explain",
            responseText: placeholderResponse
        )

        showActionView(
            content: AnyView(textResponseView),
            buttonText: "Insert",
            buttonIcon: "checkmark.circle",
            responseText: placeholderResponse,
            expandHeight: false,
            growFromBottom: true
        )
    }

    private func showFactCheck() {
        guard let text = getTextForAction(), !text.isEmpty else { return }

        currentActionType = .factCheck
        currentInputText = text

        // Placeholder response for now
        let placeholderResponse = "Mostly false. While coffee has a mild diuretic effect, studies show it doesn't cause dehydration when consumed in normal amounts. Regular coffee drinkers adapt, and it still contributes to daily fluid intake."

        let textResponseView = TextResponseView(
            headerText: "Fact Check",
            responseText: placeholderResponse
        )

        showActionView(
            content: AnyView(textResponseView),
            buttonText: "Insert",
            buttonIcon: "checkmark.circle",
            responseText: placeholderResponse,
            expandHeight: false,
            growFromBottom: true
        )
    }

    private func showActionView(content: AnyView, buttonText: String, buttonIcon: String, url: URL? = nil, responseText: String? = nil, expandHeight: Bool = false, growFromBottom: Bool = false) {
        // Prepare the content first
        actionState.actionViewContent = content
        actionState.actionButtonText = buttonText
        actionState.actionButtonIcon = buttonIcon
        actionState.currentURL = url
        actionState.responseText = responseText
        actionState.growFromBottom = growFromBottom

        // Calculate heights
        let screenHeight = UIScreen.main.bounds.height
        let expandedHeight = min(500, screenHeight * 0.6) // Max 500px or 60% of screen height
        let currentHeight = view.frame.height
        let targetHeight = expandHeight ? expandedHeight : currentHeight

        // Step 1: Fade out keyboard immediately
        withAnimation(.easeOut(duration: 0.2)) {
            actionState.showingActionView = true
        }

        // Step 2: Start growing action view from bottom immediately (starts at 0.05s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeInOut(duration: 0.5)) {
                self.actionState.actionViewHeight = targetHeight - 12 // Subtract padding
            }
        }

        // Step 3: Animate keyboard height expansion if needed
        if expandHeight {
            UIView.animate(withDuration: 0.8, delay: 0.05, options: .curveEaseInOut) {
                self.removeHeightConstraint()
                let constraint = NSLayoutConstraint(
                    item: self.view!,
                    attribute: .height,
                    relatedBy: .equal,
                    toItem: nil,
                    attribute: .notAnAttribute,
                    multiplier: 1.0,
                    constant: targetHeight
                )
                constraint.priority = .required
                self.view.addConstraint(constraint)
                self.heightConstraint = constraint
                self.view.layoutIfNeeded()
            }
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

        let webView = WebView(url: searchURL)
        showActionView(
            content: AnyView(webView),
            buttonText: "Open",
            buttonIcon: "safari",
            url: searchURL,
            expandHeight: true,
            growFromBottom: true
        )
    }

    private func removeHeightConstraint() {
        if let constraint = heightConstraint {
            view.removeConstraint(constraint)
            heightConstraint = nil
        }
    }

    private func handleReload() {
        guard let actionType = currentActionType else { return }

        // Generate a different placeholder response
        let alternativeResponses: [CopilotSearchAction: [String]] = [
            .explain: [
                "Metacognition is the process of thinking about your own thinking. It involves being aware of how you learn, plan, and solve problems, and adjusting your strategies to improve outcomes.",
                "Metacognition refers to awareness and understanding of one's own thought processes. It's essentially 'thinking about thinking' - monitoring how you learn and adapt your strategies accordingly.",
                "In simple terms, metacognition is your ability to observe and analyze your own mental processes, helping you become more effective at learning and problem-solving."
            ],
            .factCheck: [
                "Mostly false. While coffee has a mild diuretic effect, studies show it doesn't cause dehydration when consumed in normal amounts. Regular coffee drinkers adapt, and it still contributes to daily fluid intake.",
                "False. Research indicates that moderate coffee consumption doesn't lead to dehydration. The body adapts to regular caffeine intake, and coffee contributes to overall hydration.",
                "Not true. While coffee is a mild diuretic, it doesn't cause significant dehydration. Studies show that coffee counts toward daily fluid intake for regular drinkers."
            ]
        ]

        // Get next response (cycle through alternatives)
        if let responses = alternativeResponses[actionType] {
            let currentResponse = actionState.responseText ?? ""
            if let currentIndex = responses.firstIndex(of: currentResponse) {
                let nextIndex = (currentIndex + 1) % responses.count
                let newResponse = responses[nextIndex]

                // Update the view
                let textResponseView = TextResponseView(
                    headerText: actionType == .explain ? "Explain" : "Fact Check",
                    responseText: newResponse
                )

                actionState.actionViewContent = AnyView(textResponseView)
                actionState.responseText = newResponse
            }
        }
    }

    private func handleCopy() {
        guard let responseText = actionState.responseText else { return }
        UIPasteboard.general.string = responseText

        // Animate to checkmark
        withAnimation(.easeInOut(duration: 0.2)) {
            actionState.isCopied = true
        }

        // Reset back to copy icon after 1.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.2)) {
                self.actionState.isCopied = false
            }
        }
    }

    private func replaceTextWithResponse(_ text: String) {
        guard let textProxy = textDocumentProxy as? UITextDocumentProxy else { return }

        // Delete all existing text
        if let contextBefore = textProxy.documentContextBeforeInput {
            for _ in 0..<contextBefore.count {
                textProxy.deleteBackward()
            }
        }

        if let contextAfter = textProxy.documentContextAfterInput {
            // Delete text after cursor by moving forward and deleting
            for _ in 0..<contextAfter.count {
                textProxy.deleteBackward()
            }
        }

        // Insert the new text
        textProxy.insertText(text)
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
