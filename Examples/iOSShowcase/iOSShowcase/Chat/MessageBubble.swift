import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom) {
            if message.role == .user { Spacer(minLength: 40) }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(visibleText)
                    .textSelection(.enabled)
                    .foregroundStyle(foreground)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(background, in: .rect(cornerRadius: 18))

                if message.isStreaming && message.text.isEmpty {
                    TypingIndicator()
                        .padding(.leading, 8)
                }
            }

            if message.role == .assistant { Spacer(minLength: 40) }
        }
    }

    private var visibleText: String {
        if message.isStreaming && message.text.isEmpty { return " " }
        return message.text
    }

    private var background: AnyShapeStyle {
        switch message.role {
        case .user: AnyShapeStyle(Color.accentColor)
        case .assistant: AnyShapeStyle(.ultraThinMaterial)
        }
    }

    private var foreground: Color {
        message.role == .user ? .white : .primary
    }
}

private struct TypingIndicator: View {
    @State private var phase = 0.0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .frame(width: 6, height: 6)
                    .opacity(0.25 + 0.75 * dotOpacity(for: index))
            }
        }
        .foregroundStyle(.secondary)
        .onAppear {
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }

    private func dotOpacity(for index: Int) -> Double {
        let offset = Double(index) * 0.33
        return 0.5 + 0.5 * sin((phase + offset) * .pi * 2)
    }
}

#Preview {
    VStack(spacing: 12) {
        MessageBubble(message: ChatMessage(role: .user, text: "Hey, what can you do?"))
        MessageBubble(message: ChatMessage(role: .assistant, text: "Hi! I'm streaming over the Mastra data stream."))
        MessageBubble(message: ChatMessage(role: .assistant, text: "", isStreaming: true))
    }
    .padding()
}
