import KeyboardKit
import SwiftUI

private enum CopilotWriteAction: String, CaseIterable, Identifiable {
    case generate = "Generate"
    case rewrite = "Rewrite"
    case proofread = "Proofread"
    case tone = "Tone"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .generate: return "sparkles"
        case .rewrite: return "arrow.triangle.2.circlepath"
        case .proofread: return "checkmark.seal"
        case .tone: return "slider.horizontal.3"
        }
    }
}

private enum CopilotSearchAction: String, CaseIterable, Identifiable {
    case aiAnswer = "AI answer"
    case images = "Images"
    case maps = "Maps"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .aiAnswer: return "brain"
        case .images: return "photo.on.rectangle"
        case .maps: return "map"
        }
    }
}

private struct CopilotActionBar: View {
    let onWriteSelection: (CopilotWriteAction) -> Void
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
            ForEach(CopilotWriteAction.allCases) { option in
                Button {
                    onWriteSelection(option)
                } label: {
                    Label(option.rawValue, systemImage: option.symbolName)
                }
            }
        } label: {
            pillLabel(symbol: "square.and.pencil", title: "Write")
        }
        .menuOrder(.fixed)
        .menuStyle(.borderlessButton)
    }

    private var searchMenu: some View {
        Menu {
            ForEach(CopilotSearchAction.allCases) { option in
                Button {
                    onSearchSelection(option)
                } label: {
                    Label(option.rawValue, systemImage: option.symbolName)
                }
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
                    onWriteSelection: onWriteSelection,
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
                onSearchSelection: { action in
                    self?.handleSearchSelection(action)
                }
            )
        }
    }

    private func handleWriteSelection(_ action: CopilotWriteAction) {
        NSLog("Selected write action: \(action.rawValue)")
    }

    private func handleSearchSelection(_ action: CopilotSearchAction) {
        NSLog("Selected search action: \(action.rawValue)")
    }
}
