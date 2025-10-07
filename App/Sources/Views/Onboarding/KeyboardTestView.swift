import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

struct KeyboardTestView: View {
    let onComplete: () -> Void
    let onSkip: () -> Void
    @State private var messageText: String = ""
    @State private var messages: [ChatMessage] = [
        ChatMessage(text: "Hi! 👋 Try typing a message to test your keyboard.", isUser: false),
        ChatMessage(text: "Tap the globe icon to switch to Keyboard Copilot, then try the Write and Ask menus!", isUser: false)
    ]
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Chat messages
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(messages) { message in
                        HStack {
                            if message.isUser {
                                Spacer()
                            }

                            Text(message.text)
                                .font(.body)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(message.isUser ? Color.accentColor : Color(uiColor: .secondarySystemBackground))
                                )
                                .foregroundStyle(message.isUser ? .white : .primary)

                            if !message.isUser {
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 16)
            }

            // Message input
            HStack(alignment: .bottom, spacing: 0) {
                TextField("Type a message...", text: $messageText, axis: .vertical)
                    .focused($isTextFieldFocused)
                    .padding(.leading, 12)
                    .padding(.trailing, 28)
                    .padding(.vertical, 7.5)
                    .lineLimit(1...4)
                    .onSubmit {
                        sendMessage()
                    }

                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(messageText.isEmpty ? .gray : Color.accentColor)
                }
                .disabled(messageText.isEmpty)
                .padding(.trailing, 2)
                .padding(.bottom, 2)
            }
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemBackground))
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(uiColor: .systemBackground))
        }
        .navigationTitle("Try your keyboard")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    onComplete()
                }
                .fontWeight(.semibold)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }

    private func sendMessage() {
        guard !messageText.isEmpty else { return }

        messages.append(ChatMessage(text: messageText, isUser: true))
        messageText = ""

        // Auto-respond
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let responses = [
                "Great! Now try using the Write menu to compose something.",
                "Nice! You can also use the Ask menu to search or chat with AI.",
                "Perfect! Tap Done when you're ready to finish setup."
            ]
            if let response = responses.randomElement() {
                messages.append(ChatMessage(text: response, isUser: false))
            }
        }
    }
}

struct TipRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.primary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    KeyboardTestView(onComplete: {}, onSkip: {})
}
