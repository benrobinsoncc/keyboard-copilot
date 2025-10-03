import KeyboardKit
import SwiftUI
import WebKit
import Combine
import Pow
import AnimateText
import Vortex
import AVFoundation

private class SpeechManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking = false
    private var isStopping = false

    override init() {
        super.init()
        synthesizer.delegate = self
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        } catch {
            NSLog("Failed to configure audio session: \(error.localizedDescription)")
        }
    }

    func speak(_ text: String) {
        // If already speaking, stop it
        if synthesizer.isSpeaking || isSpeaking {
            stop()
            return
        }

        // Start speaking
        DispatchQueue.main.async {
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setActive(true, options: [])

                let utterance = AVSpeechUtterance(string: text)
                utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                utterance.rate = 0.5 // Normal speed

                self.isSpeaking = true
                self.synthesizer.speak(utterance)
            } catch {
                NSLog("Failed to activate audio session: \(error.localizedDescription)")
                self.isSpeaking = false
            }
        }
    }

    func stop() {
        guard !isStopping else { return }
        isStopping = true

        DispatchQueue.main.async {
            if self.synthesizer.isSpeaking {
                self.synthesizer.stopSpeaking(at: .immediate)
            }

            self.isSpeaking = false
            self.isStopping = false

            // Deactivate audio session
            DispatchQueue.global(qos: .background).async {
                do {
                    let audioSession = AVAudioSession.sharedInstance()
                    try audioSession.setActive(false, options: [.notifyOthersOnDeactivation])
                } catch {
                    NSLog("Failed to deactivate audio session: \(error.localizedDescription)")
                }
            }
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false

            // Deactivate audio session when finished
            DispatchQueue.global(qos: .background).async {
                do {
                    let audioSession = AVAudioSession.sharedInstance()
                    try audioSession.setActive(false, options: [.notifyOthersOnDeactivation])
                } catch {
                    NSLog("Failed to deactivate audio session: \(error.localizedDescription)")
                }
            }
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.isStopping = false
        }
    }
}

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
    @Published var isExpanded = true
    @Published var allowsToggle = false
    @Published var toggleIconState = true // Separate state for icon that updates after animation
    @Published var isLoading = false
    @Published var isReloading = false
    @Published var shouldAnimateHeight = false // Only animate height for webview
    @Published var showFireflies = false // Trigger fireflies dissolve effect
    var currentWebView: WKWebView? // Reference to current web view for reload
}

private struct WebView: UIViewRepresentable {
    let url: URL
    let onWebViewCreated: ((WKWebView) -> Void)?

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        onWebViewCreated?(webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Only load if URL has changed
        if uiView.url != url {
            uiView.load(URLRequest(url: url))
        }
    }
}

private struct WrappingHStack: Layout {
    var spacing: CGFloat = 0

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map { $0.height }.reduce(0, +)
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY

        for row in rows {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: .unspecified)
                x += size.width + spacing
            }
            y += row.height
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [(indices: [Int], height: CGFloat)] {
        var rows: [(indices: [Int], height: CGFloat)] = []
        var currentRow: [Int] = []
        var currentX: CGFloat = 0
        var currentHeight: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity

        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && !currentRow.isEmpty {
                rows.append((currentRow, currentHeight))
                currentRow = []
                currentX = 0
                currentHeight = 0
            }

            currentRow.append(index)
            currentX += size.width + spacing
            currentHeight = max(currentHeight, size.height)
        }

        if !currentRow.isEmpty {
            rows.append((currentRow, currentHeight))
        }

        return rows
    }
}

private struct AnimatedCharacter: View {
    let character: String
    let index: Int
    @State private var opacity: Double = 0
    @State private var blur: CGFloat = 8

    var body: some View {
        Text(character)
            .opacity(opacity)
            .blur(radius: blur)
            .onAppear {
                let delay = Double(index) * 0.01
                withAnimation(.easeOut(duration: 0.2).delay(delay)) {
                    opacity = 1
                    blur = 0
                }
            }
    }
}

private struct AnimatedWord: View {
    let word: String
    let startIndex: Int
    let font: Font
    let color: Color

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(word.enumerated()), id: \.offset) { charIndex, char in
                AnimatedCharacter(character: String(char), index: startIndex + charIndex)
                    .font(font)
                    .foregroundColor(color)
            }
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}

private struct BlurredText: View {
    let text: String
    let font: Font
    let color: Color

    private let paragraphs: [(lines: [(line: String, startIndex: Int)], isEmptyLine: Bool)]

    init(text: String, font: Font, color: Color) {
        self.text = text
        self.font = font
        self.color = color

        // Split into lines first, then group into paragraphs
        let textLines = text.components(separatedBy: .newlines)
        var charIndex = 0
        var currentParagraphLines: [(line: String, startIndex: Int)] = []
        var result: [(lines: [(line: String, startIndex: Int)], isEmptyLine: Bool)] = []

        for line in textLines {
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                // Empty line - close current paragraph and add spacing
                if !currentParagraphLines.isEmpty {
                    result.append((currentParagraphLines, false))
                    currentParagraphLines = []
                }
                result.append(([(line, charIndex)], true))
            } else {
                currentParagraphLines.append((line, charIndex))
            }
            charIndex += line.count + 1 // +1 for newline character
        }

        // Add remaining paragraph
        if !currentParagraphLines.isEmpty {
            result.append((currentParagraphLines, false))
        }

        self.paragraphs = result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(paragraphs.enumerated()), id: \.offset) { paragraphIndex, paragraphData in
                if paragraphData.isEmptyLine {
                    // Empty line for paragraph spacing
                    Spacer()
                        .frame(height: 8)
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(paragraphData.lines.enumerated()), id: \.offset) { lineIndex, lineData in
                            BlurredLine(line: lineData.line, startIndex: lineData.startIndex, font: font, color: color)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct BlurredLine: View {
    let line: String
    let startIndex: Int
    let font: Font
    let color: Color

    private let wordData: [(word: String, startIndex: Int, isBold: Bool)]
    private let isHeader: Bool

    init(line: String, startIndex: Int, font: Font, color: Color) {
        self.line = line
        self.startIndex = startIndex
        self.font = font
        self.color = color

        // Check if line starts with ### (header)
        var processedLine = line
        var headerOffset = 0
        if line.hasPrefix("### ") {
            processedLine = String(line.dropFirst(4)) // Remove "### "
            headerOffset = 4
            self.isHeader = true
        } else if line.hasPrefix("##") {
            processedLine = String(line.dropFirst(3)) // Remove "## "
            headerOffset = 3
            self.isHeader = true
        } else if line.hasPrefix("#") {
            processedLine = String(line.dropFirst(2)) // Remove "# "
            headerOffset = 2
            self.isHeader = true
        } else {
            self.isHeader = false
        }

        // Parse markdown bold (**text**) and split into words
        var result: [(word: String, startIndex: Int, isBold: Bool)] = []
        var currentIndex = startIndex + headerOffset
        var remainingText = processedLine

        while !remainingText.isEmpty {
            if let boldRange = remainingText.range(of: "\\*\\*([^*]+)\\*\\*", options: .regularExpression) {
                // Add words before bold
                let beforeBold = String(remainingText[..<boldRange.lowerBound])
                if !beforeBold.isEmpty {
                    let words = beforeBold.split(separator: " ", omittingEmptySubsequences: false)
                    for word in words {
                        result.append((String(word), currentIndex, false))
                        currentIndex += word.count + 1
                    }
                }

                // Add bold text words (remove the ** markers)
                let boldWithMarkers = String(remainingText[boldRange])
                let boldText = String(boldWithMarkers.dropFirst(2).dropLast(2))
                let boldWords = boldText.split(separator: " ", omittingEmptySubsequences: false)
                currentIndex += 2 // Skip the opening **
                for word in boldWords {
                    result.append((String(word), currentIndex, true))
                    currentIndex += word.count + 1
                }
                currentIndex += 2 // Skip the closing **

                // Move to remaining text
                remainingText = String(remainingText[boldRange.upperBound...])
            } else {
                // No more bold text, add remaining words as regular
                let words = remainingText.split(separator: " ", omittingEmptySubsequences: false)
                for word in words {
                    result.append((String(word), currentIndex, false))
                    currentIndex += word.count + 1
                }
                break
            }
        }

        self.wordData = result
    }

    var body: some View {
        WrappingHStack(spacing: 0) {
            ForEach(Array(wordData.enumerated()), id: \.offset) { index, data in
                HStack(spacing: 0) {
                    AnimatedWord(
                        word: data.word,
                        startIndex: data.startIndex,
                        font: (isHeader || data.isBold) ? font.weight(.semibold) : font,
                        color: color
                    )
                    if index < wordData.count - 1 {
                        AnimatedCharacter(
                            character: " ",
                            index: data.startIndex + data.word.count
                        )
                        .font((isHeader || data.isBold) ? font.weight(.semibold) : font)
                        .foregroundColor(color)
                    }
                }
            }
        }
    }
}

private struct TextResponseView: View {
    let headerText: String
    @ObservedObject var actionState: CopilotActionState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Text(headerText.uppercased())
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.gray)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)

            // Response text (scrollable) or loading indicator
            ZStack {
                if actionState.isLoading && !actionState.showFireflies {
                    VStack(spacing: 8) {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Generating")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .offset(y: -8)
                } else if let responseText = actionState.responseText {
                    ScrollView {
                        BlurredText(
                            text: responseText,
                            font: .system(size: 16, weight: .regular),
                            color: .primary
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: .infinity)
                    .id(responseText)
                    .opacity(actionState.showFireflies ? 0 : 1)
                }

                // Fireflies dissolve effect overlay
                if actionState.showFireflies {
                    VortexView(.fireflies) {
                        Circle()
                            .fill(.primary.opacity(0.3))  // Color with transparency
                            .frame(width: 24, height: 16)
                            .blur(radius: 3)
                            .tag("circle")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
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
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onWriteSelection(.compose)
            }) {
                Label("Compose", systemImage: "sparkles")
            }

            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onRewriteSelection(.polish)
            }) {
                Label("Polish", systemImage: "checkmark.seal")
            }

            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onRewriteSelection(.shorten)
            }) {
                Label("Shorten", systemImage: "text.badge.minus")
            }

            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onWriteSelection(.shortcuts)
            }) {
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
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onSearchSelection(.google)
            }) {
                Label("Google", systemImage: "arrow.up.forward.square")
            }
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onSearchSelection(.explain)
            }) {
                Label("Explain", systemImage: "lightbulb")
            }
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onSearchSelection(.factCheck)
            }) {
                Label("Fact check", systemImage: "checkmark.shield")
            }
        } label: {
            pillLabel(symbol: "magnifyingglass", title: "Ask")
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
    let onShare: (() -> Void)?
    let onToggle: (() -> Void)?
    let onSpeak: (() -> Void)?
    let content: AnyView
    let isCopied: Bool
    let isExpanded: Bool
    let allowsToggle: Bool
    let toggleIconExpanded: Bool
    let isSpeaking: Bool

    @ObservedObject var actionState: CopilotActionState

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
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onCancel()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 32, height: 32)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.gray.opacity(0.1))
                            )
                    }

                    // Show reload and copy buttons if available
                    if let onReload = onReload {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            onReload()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.primary)
                                .rotationEffect(.degrees(actionState.isReloading ? 180 : 0))
                                .animation(.easeInOut(duration: 0.3), value: actionState.isReloading)
                                .frame(width: 32, height: 32)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color.gray.opacity(0.1))
                                )
                        }
                    }

                    if let onCopy = onCopy {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            onCopy()
                        }) {
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
                        .disabled(isCopied || actionState.isLoading)
                    }

                    // Show speak button if available
                    if let onSpeak = onSpeak {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            onSpeak()
                        }) {
                            ZStack {
                                Image(systemName: isSpeaking ? "stop" : "speaker.wave.2")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .transition(.scale.combined(with: .opacity))
                                    .id(isSpeaking ? "stop" : "speak")
                            }
                            .animation(.easeInOut(duration: 0.2), value: isSpeaking)
                            .frame(width: 32, height: 32)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.gray.opacity(0.1))
                            )
                        }
                        .disabled(actionState.isLoading)
                    }

                    // Show toggle button if available
                    if allowsToggle, let onToggle = onToggle {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            onToggle()
                        }) {
                            Image(systemName: toggleIconExpanded ? "rectangle.compress.vertical" : "rectangle.expand.vertical")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.primary)
                                .frame(width: 32, height: 32)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color.gray.opacity(0.1))
                                )
                        }
                    }

                    Spacer()

                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onAction()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: actionButtonIcon)
                                .font(.system(size: 12, weight: .semibold))
                            Text(actionButtonText)
                                .font(.system(size: 15, weight: .regular))
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .frame(height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.gray.opacity(0.1))
                        )
                    }

                    // Show insert button if available
                    if let onShare = onShare {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            onShare()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Insert")
                                    .font(.system(size: 15, weight: .regular))
                            }
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .frame(height: 32)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.gray.opacity(0.1))
                            )
                        }
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
    let onShare: (() -> Void)?
    let onToggle: (() -> Void)?
    let onSpeak: (() -> Void)?

    @ObservedObject var actionState: CopilotActionState
    @ObservedObject var speechManager: SpeechManager

    var body: some View {
        VStack(spacing: 0) {
            // Action view area (only visible when showing action view)
            if actionState.showingActionView, let content = actionState.actionViewContent {
                CopilotActionView(
                    actionButtonText: actionState.actionButtonText,
                    actionButtonIcon: actionState.actionButtonIcon,
                    onAction: {
                        // Stop speech if playing
                        speechManager.stop()

                        if let url = actionState.currentURL {
                            onOpenURL?(url)
                        } else if let responseText = actionState.responseText {
                            onInsertText?(responseText)
                        }

                        // Hide action view immediately to show keyboard
                        actionState.showingActionView = false
                        actionState.actionViewContent = nil
                        actionState.currentURL = nil
                        actionState.responseText = nil
                        actionState.growFromBottom = false
                        actionState.isExpanded = true
                        actionState.allowsToggle = false
                        actionState.currentWebView = nil
                        actionState.actionViewHeight = 0
                    },
                    onCancel: {
                        // Stop speech if playing
                        speechManager.stop()

                        // Hide action view immediately to show keyboard
                        actionState.showingActionView = false
                        actionState.actionViewContent = nil
                        actionState.currentURL = nil
                        actionState.responseText = nil
                        actionState.growFromBottom = false
                        actionState.isExpanded = true
                        actionState.allowsToggle = false
                        actionState.currentWebView = nil
                        actionState.actionViewHeight = 0
                    },
                    onReload: onReload,
                    onCopy: (actionState.responseText != nil || actionState.isLoading) ? onCopy : nil,
                    onShare: actionState.currentURL != nil ? onShare : nil,
                    onToggle: actionState.allowsToggle ? onToggle : nil,
                    onSpeak: (actionState.responseText != nil || actionState.isLoading) ? onSpeak : nil,
                    content: content,
                    isCopied: actionState.isCopied,
                    isExpanded: actionState.isExpanded,
                    allowsToggle: actionState.allowsToggle,
                    toggleIconExpanded: actionState.toggleIconState,
                    isSpeaking: speechManager.isSpeaking,
                    actionState: actionState
                )
                .frame(height: actionState.isExpanded ? actionState.actionViewHeight : nil)
                .frame(maxHeight: actionState.isExpanded ? nil : .infinity)
                .clipped()
                .padding(.horizontal, 6)
                .padding(.top, 6)
                .animation(actionState.shouldAnimateHeight ? .easeInOut(duration: 0.4) : nil, value: actionState.actionViewHeight)
            }

            // Spacer to push keyboard to bottom in collapsed state
            if actionState.showingActionView && !actionState.isExpanded {
                Spacer(minLength: 0)
            }

            // Keyboard view (visible when not showing action view, or when collapsed)
            if !actionState.showingActionView || !actionState.isExpanded {
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
                        // Only show action bar when not showing action view
                        if !actionState.showingActionView {
                            CopilotActionBar(
                                selectedText: nil,
                                onWriteSelection: onWriteSelection,
                                onRewriteSelection: onRewriteSelection,
                                onSearchSelection: onSearchSelection
                            )
                        }
                    }
                )
                .animation(.easeInOut(duration: 0.3), value: actionState.showingActionView)
                .animation(.easeInOut(duration: 0.3), value: actionState.isExpanded)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

final class KeyboardViewController: KeyboardInputViewController {

    private let actionState = CopilotActionState()
    private let speechManager = SpeechManager()
    private var heightConstraint: NSLayoutConstraint?
    private var currentActionType: CopilotSearchAction?
    private var currentWriteActionType: CopilotWriteAction?
    private var currentRewriteActionType: CopilotRewriteAction?
    private var currentInputText: String?
    private var expandedHeight: CGFloat = 0
    private var collapsedHeight: CGFloat = 0
    private lazy var openAIService: OpenAIService = {
        guard let apiKey = Self.loadAPIKey() else {
            fatalError("Failed to load OpenAI API key from Config.plist")
        }
        return OpenAIService(apiKey: apiKey)
    }()

    private static func loadAPIKey() -> String? {
        // For keyboard extensions, we need to use the extension's bundle, not Bundle.main
        let bundle = Bundle(for: KeyboardViewController.self)

        guard let url = bundle.url(forResource: "Config", withExtension: "plist") else {
            NSLog("ERROR: Config.plist not found in bundle")
            NSLog("Bundle path: \(bundle.bundlePath)")
            NSLog("Bundle resources: \(bundle.paths(forResourcesOfType: "plist", inDirectory: nil))")
            return nil
        }

        guard let data = try? Data(contentsOf: url) else {
            NSLog("ERROR: Could not read Config.plist data")
            return nil
        }

        guard let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
            NSLog("ERROR: Could not parse Config.plist")
            return nil
        }

        guard let apiKey = plist["OPENAI_API_KEY"] as? String else {
            NSLog("ERROR: OPENAI_API_KEY not found in Config.plist")
            return nil
        }

        NSLog("Successfully loaded API key from Config.plist")
        return apiKey
    }

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

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Stop speech when keyboard is dismissed
        speechManager.stop()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Ensure speech is stopped
        speechManager.stop()
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
                onShare: {
                    self?.handleShare()
                },
                onToggle: {
                    self?.handleToggle()
                },
                onSpeak: {
                    self?.handleSpeak()
                },
                actionState: self?.actionState ?? CopilotActionState(),
                speechManager: self?.speechManager ?? SpeechManager()
            )
        }
    }

    private func handleWriteSelection(_ action: CopilotWriteAction) {
        NSLog("Selected write action: \(action.rawValue)")

        switch action {
        case .compose:
            showCompose()
        case .rewrite:
            // Rewrite is handled by handleRewriteSelection
            NSLog("Rewrite submenu selected")
        case .shortcuts:
            // TODO: Implement shortcuts
            NSLog("Shortcuts not yet implemented")
        }
    }

    private func handleRewriteSelection(_ action: CopilotRewriteAction) {
        NSLog("Selected rewrite action: \(action.rawValue)")

        switch action {
        case .polish:
            showPolish()
        case .shorten:
            showShorten()
        }
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
        currentWriteActionType = nil
        currentRewriteActionType = nil
        currentInputText = text

        // Show loading state
        actionState.isLoading = true
        actionState.responseText = nil
        let textResponseView = TextResponseView(
            headerText: "Explain",
            actionState: actionState
        )

        showActionView(
            content: AnyView(textResponseView),
            buttonText: "Insert",
            buttonIcon: "checkmark.circle",
            responseText: nil,
            expandHeight: false,
            growFromBottom: true
        )

        // Call OpenAI API
        openAIService.explain(inputText: text) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self.actionState.responseText = response
                    self.actionState.isLoading = false

                case .failure(let error):
                    let errorMessage = "Failed to generate response. Please try again."
                    NSLog("Explain error: \(error)")
                    self.actionState.responseText = errorMessage
                    self.actionState.isLoading = false
                }
            }
        }
    }

    private func showFactCheck() {
        guard let text = getTextForAction(), !text.isEmpty else { return }

        currentActionType = .factCheck
        currentWriteActionType = nil
        currentRewriteActionType = nil
        currentInputText = text

        // Show loading state
        actionState.isLoading = true
        actionState.responseText = nil
        let textResponseView = TextResponseView(
            headerText: "Fact Check",
            actionState: actionState
        )

        showActionView(
            content: AnyView(textResponseView),
            buttonText: "Insert",
            buttonIcon: "checkmark.circle",
            responseText: nil,
            expandHeight: false,
            growFromBottom: true
        )

        // Call OpenAI API
        openAIService.factCheck(inputText: text) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self.actionState.responseText = response
                    self.actionState.isLoading = false

                case .failure(let error):
                    let errorMessage = "Failed to generate response. Please try again."
                    NSLog("Fact Check error: \(error)")
                    self.actionState.responseText = errorMessage
                    self.actionState.isLoading = false
                }
            }
        }
    }

    private func showCompose() {
        guard let text = getTextForAction(), !text.isEmpty else { return }

        currentActionType = nil
        currentWriteActionType = .compose
        currentRewriteActionType = nil
        currentInputText = text

        // Show loading state
        actionState.isLoading = true
        actionState.responseText = nil
        let textResponseView = TextResponseView(
            headerText: "Compose",
            actionState: actionState
        )

        showActionView(
            content: AnyView(textResponseView),
            buttonText: "Insert",
            buttonIcon: "checkmark.circle",
            responseText: nil,
            expandHeight: false,
            growFromBottom: true
        )

        // Call OpenAI API
        openAIService.compose(inputText: text) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self.actionState.responseText = response
                    self.actionState.isLoading = false

                case .failure(let error):
                    let errorMessage = "Failed to generate response. Please try again."
                    NSLog("Compose error: \(error)")
                    self.actionState.responseText = errorMessage
                    self.actionState.isLoading = false
                }
            }
        }
    }

    private func showPolish() {
        guard let text = getTextForAction(), !text.isEmpty else { return }

        currentActionType = nil
        currentWriteActionType = nil
        currentRewriteActionType = .polish
        currentInputText = text

        // Show loading state
        actionState.isLoading = true
        actionState.responseText = nil
        let textResponseView = TextResponseView(
            headerText: "Polish",
            actionState: actionState
        )

        showActionView(
            content: AnyView(textResponseView),
            buttonText: "Insert",
            buttonIcon: "checkmark.circle",
            responseText: nil,
            expandHeight: false,
            growFromBottom: true
        )

        // Call OpenAI API
        openAIService.polish(inputText: text) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self.actionState.responseText = response
                    self.actionState.isLoading = false

                case .failure(let error):
                    let errorMessage = "Failed to generate response. Please try again."
                    NSLog("Polish error: \(error)")
                    self.actionState.responseText = errorMessage
                    self.actionState.isLoading = false
                }
            }
        }
    }

    private func showShorten() {
        guard let text = getTextForAction(), !text.isEmpty else { return }

        currentActionType = nil
        currentWriteActionType = nil
        currentRewriteActionType = .shorten
        currentInputText = text

        // Show loading state
        actionState.isLoading = true
        actionState.responseText = nil
        let textResponseView = TextResponseView(
            headerText: "Shorten",
            actionState: actionState
        )

        showActionView(
            content: AnyView(textResponseView),
            buttonText: "Insert",
            buttonIcon: "checkmark.circle",
            responseText: nil,
            expandHeight: false,
            growFromBottom: true
        )

        // Call OpenAI API
        openAIService.shorten(inputText: text) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self.actionState.responseText = response
                    self.actionState.isLoading = false

                case .failure(let error):
                    let errorMessage = "Failed to generate response. Please try again."
                    NSLog("Shorten error: \(error)")
                    self.actionState.responseText = errorMessage
                    self.actionState.isLoading = false
                }
            }
        }
    }

    private func showActionView(content: AnyView, buttonText: String, buttonIcon: String, url: URL? = nil, responseText: String? = nil, expandHeight: Bool = false, growFromBottom: Bool = false, allowsToggle: Bool = false) {
        // Prepare the content first
        actionState.actionViewContent = content
        actionState.actionButtonText = buttonText
        actionState.actionButtonIcon = buttonIcon
        actionState.currentURL = url
        actionState.responseText = responseText
        actionState.growFromBottom = growFromBottom
        actionState.allowsToggle = allowsToggle
        actionState.isExpanded = true // Always start in expanded state
        actionState.shouldAnimateHeight = expandHeight // Only animate for webview

        // Calculate heights
        let screenHeight = UIScreen.main.bounds.height
        let calculatedExpandedHeight = min(500, screenHeight * 0.6) // Max 500px or 60% of screen height
        let currentHeight = view.frame.height
        let targetHeight = expandHeight ? calculatedExpandedHeight : currentHeight

        // Store heights for toggle functionality
        self.expandedHeight = calculatedExpandedHeight
        self.collapsedHeight = currentHeight

        // Step 1: Fade out keyboard immediately
        withAnimation(.easeOut(duration: 0.2)) {
            actionState.showingActionView = true
        }

        // Step 2: Set action view height (animated only for webview)
        if expandHeight {
            // For webview: animate the growth
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    self.actionState.actionViewHeight = targetHeight - 6
                }
            }
        } else {
            // For text responses: set height immediately without animation
            actionState.actionViewHeight = targetHeight - 6
        }

        // Step 3: Animate keyboard height expansion if needed
        if expandHeight {
            UIView.animate(withDuration: 0.6, delay: 0.05, options: .curveEaseInOut) {
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

        let webView = WebView(url: searchURL) { [weak self] webView in
            self?.actionState.currentWebView = webView
        }
        showActionView(
            content: AnyView(webView),
            buttonText: "Open",
            buttonIcon: "safari",
            url: searchURL,
            expandHeight: true,
            growFromBottom: true,
            allowsToggle: true
        )
    }

    private func removeHeightConstraint() {
        if let constraint = heightConstraint {
            view.removeConstraint(constraint)
            heightConstraint = nil
        }
    }

    private func handleReload() {
        // Trigger spin animation
        actionState.isReloading = true

        // Reset animation state after it completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.actionState.isReloading = false
        }

        // If there's a web view, reload it (no fireflies for webview)
        if let webView = actionState.currentWebView {
            webView.reload()
            return
        }

        // Trigger fireflies dissolve effect
        actionState.showFireflies = true

        // After 2 seconds, hide fireflies and show loading if API hasn't responded
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.actionState.showFireflies = false
        }

        // Re-call the API for the current action with the stored input text
        guard let inputText = currentInputText else { return }

        // Handle search actions
        if let actionType = currentActionType {
            switch actionType {
            case .explain:
                showExplain()
            case .factCheck:
                showFactCheck()
            case .google:
                break // Google doesn't need reload (handled above)
            }
            return
        }

        // Handle write actions
        if let writeActionType = currentWriteActionType {
            switch writeActionType {
            case .compose:
                showCompose()
            case .rewrite, .shortcuts:
                break
            }
            return
        }

        // Handle rewrite actions
        if let rewriteActionType = currentRewriteActionType {
            switch rewriteActionType {
            case .polish:
                showPolish()
            case .shorten:
                showShorten()
            }
            return
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

    private func handleSpeak() {
        guard let responseText = actionState.responseText else { return }
        speechManager.speak(responseText)
    }

    private func handleShare() {
        guard let webView = actionState.currentWebView,
              let currentURL = webView.url else { return }

        // Insert the current URL on a new line
        guard let textProxy = textDocumentProxy as? UITextDocumentProxy else { return }

        // Check if there's existing text
        let hasTextBefore = !(textProxy.documentContextBeforeInput?.isEmpty ?? true)

        if hasTextBefore {
            textProxy.insertText("\n\n" + currentURL.absoluteString)
        } else {
            textProxy.insertText(currentURL.absoluteString)
        }
    }

    private func replaceTextWithResponse(_ text: String) {
        guard let textProxy = textDocumentProxy as? UITextDocumentProxy else { return }

        // For now, just insert with line breaks instead of deleting
        // (Deleting can cause freezes with large amounts of text)
        let hasTextBefore = !(textProxy.documentContextBeforeInput?.isEmpty ?? true)

        if hasTextBefore {
            textProxy.insertText("\n\n" + text)
        } else {
            textProxy.insertText(text)
        }
    }

    private func handleToggle() {
        let wasExpanded = actionState.isExpanded

        // Toggle the expanded state
        withAnimation(.easeInOut(duration: 0.4)) {
            actionState.isExpanded.toggle()
        }

        // Update action view height for expanded state
        if actionState.isExpanded {
            withAnimation(.easeInOut(duration: 0.4)) {
                actionState.actionViewHeight = expandedHeight - 6 // Subtract top padding
            }
        }

        // Change icon after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.actionState.toggleIconState = !wasExpanded
        }
        // When collapsed, height is flexible (maxHeight: .infinity) so no need to set fixed height
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
