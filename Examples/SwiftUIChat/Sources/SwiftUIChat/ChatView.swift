#if canImport(SwiftUI)
import SwiftUI
import Mastra

/// Minimal chat UI demonstrating ``Mastra/Agent/stream(_:)`` consumption.
@available(iOS 17, macOS 14, tvOS 17, watchOS 10, visionOS 1, *)
struct ChatView: View {
    @State private var controller: ChatController
    @State private var draft: String = ""

    init(controller: ChatController) {
        _controller = State(initialValue: controller)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(controller.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(16)
                }
                .onChange(of: controller.messages.last?.id) { _, newId in
                    guard let newId else { return }
                    withAnimation { proxy.scrollTo(newId, anchor: .bottom) }
                }
            }

            if let error = controller.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(8)
            }

            composer
        }
    }

    private var composer: some View {
        HStack(spacing: 8) {
            TextField("Message", text: $draft, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1 ... 4)

            if controller.isStreaming {
                Button("Stop") { controller.cancel() }
                    .buttonStyle(.bordered)
            } else {
                Button("Send") {
                    let text = draft
                    draft = ""
                    controller.send(text)
                }
                .buttonStyle(.borderedProminent)
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(12)
    }
}

@available(iOS 17, macOS 14, tvOS 17, watchOS 10, visionOS 1, *)
struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .assistant { Spacer(minLength: 0).frame(maxWidth: 48) }
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 2) {
                Text(message.role == .user ? "You" : "Assistant")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(message.text.isEmpty ? "…" : message.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        message.role == .user
                            ? Color.accentColor.opacity(0.2)
                            : Color.gray.opacity(0.15)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            if message.role == .user { Spacer(minLength: 0).frame(maxWidth: 48) }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
    }
}
#endif
