import SwiftUI

struct ChatView: View {
    @Bindable var controller: ChatController
    @State private var draft: String = ""
    @FocusState private var composerFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            conversation
            composer
        }
        .navigationTitle(controller.agentId)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    controller.startNewConversation()
                } label: {
                    Label("New", systemImage: "square.and.pencil")
                }
                .disabled(controller.messages.isEmpty && controller.threadIdentity.threadId == nil)
            }

            if let threadId = controller.threadIdentity.threadId {
                ToolbarItem(placement: .bottomBar) {
                    ThreadBadge(threadId: threadId)
                }
            }
        }
        .task { await controller.loadHistoryIfNeeded() }
        .overlay(alignment: .top) {
            if let message = controller.errorMessage {
                ErrorBanner(message: message)
                    .padding(.horizontal)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.snappy, value: controller.errorMessage)
    }

    private var conversation: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    if controller.messages.isEmpty && !controller.isLoadingHistory {
                        EmptyStateCard(agentId: controller.agentId)
                            .padding(.top, 60)
                    }
                    ForEach(controller.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                    if controller.isLoadingHistory {
                        ProgressView().padding()
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: controller.messages.last?.id) { _, newValue in
                guard let id = newValue else { return }
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(id, anchor: .bottom)
                }
            }
            .onChange(of: controller.messages.last?.text) { _, _ in
                if let id = controller.messages.last?.id {
                    proxy.scrollTo(id, anchor: .bottom)
                }
            }
        }
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Message", text: $draft, axis: .vertical)
                .lineLimit(1...6)
                .textFieldStyle(.plain)
                .focused($composerFocused)
                .submitLabel(.send)
                .onSubmit(handleSend)

            if controller.isStreaming {
                Button(role: .destructive) {
                    controller.cancel()
                } label: {
                    Image(systemName: "stop.fill")
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            } else {
                Button(action: handleSend) {
                    Image(systemName: "arrow.up")
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.borderedProminent)
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private func handleSend() {
        let text = draft
        draft = ""
        controller.send(text)
    }
}

private struct EmptyStateCard: View {
    let agentId: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "sparkles")
                .font(.system(size: 36))
                .foregroundStyle(.tint)
            Text("Chat with \(agentId)")
                .font(.title3.bold())
            Text("Messages stream token-by-token over the Mastra data stream. This thread is persisted — close the app and your conversation will still be here.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: 360)
        .background(.quaternary, in: .rect(cornerRadius: 20))
    }
}

private struct ThreadBadge: View {
    let threadId: String

    var body: some View {
        Button {
            UIPasteboard.general.string = threadId
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "bubble.left.and.bubble.right")
                    .imageScale(.small)
                Text(shortened)
                    .font(.caption.monospaced())
            }
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
    }

    private var shortened: String {
        let max = 12
        guard threadId.count > max else { return threadId }
        return String(threadId.prefix(max)) + "…"
    }
}

private struct ErrorBanner: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.footnote)
                .lineLimit(4)
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(.regularMaterial, in: .rect(cornerRadius: 12))
        .padding(.top, 6)
    }
}

#Preview {
    NavigationStack {
        ChatView(controller: PreviewClient.populatedController())
    }
}
