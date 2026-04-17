import Foundation
import Mastra
import Observation

@MainActor
@Observable
final class ChatController {
    private(set) var messages: [ChatMessage] = []
    private(set) var isStreaming: Bool = false
    private(set) var isLoadingHistory: Bool = false
    private(set) var errorMessage: String?
    private(set) var threadIdentity: ThreadIdentity

    let agentId: String

    private let client: MastraClient
    private let threadStore: any ThreadStore
    private var streamTask: Task<Void, Never>?

    init(client: MastraClient, agentId: String, threadStore: any ThreadStore) {
        self.client = client
        self.agentId = agentId
        self.threadStore = threadStore
        self.threadIdentity = threadStore.load()
    }

    func loadHistoryIfNeeded() async {
        guard let threadId = threadIdentity.threadId, messages.isEmpty else { return }
        isLoadingHistory = true
        defer { isLoadingHistory = false }
        do {
            let response = try await client.listThreadMessages(
                threadId: threadId,
                agentId: agentId
            )
            messages = response.messages.compactMap(Self.message(from:))
        } catch {
            errorMessage = "Failed to load history: \(error.localizedDescription)"
        }
    }

    func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isStreaming else { return }

        let userMessage = ChatMessage(role: .user, text: trimmed)
        messages.append(userMessage)

        let assistant = ChatMessage(role: .assistant, text: "", isStreaming: true)
        messages.append(assistant)
        let assistantId = assistant.id

        isStreaming = true
        errorMessage = nil
        streamTask = Task { [client, agentId, threadStore] in
            await self.run(
                client: client,
                agentId: agentId,
                threadStore: threadStore,
                userText: trimmed,
                assistantId: assistantId
            )
        }
    }

    func cancel() {
        streamTask?.cancel()
        streamTask = nil
        isStreaming = false
        finishStreaming()
    }

    func startNewConversation() {
        cancel()
        messages = []
        errorMessage = nil
        threadStore.reset()
        threadIdentity = threadStore.load()
    }

    private func run(
        client: MastraClient,
        agentId: String,
        threadStore: any ThreadStore,
        userText: String,
        assistantId: UUID
    ) async {
        defer {
            isStreaming = false
            finishStreaming()
        }

        do {
            let identity = try await ensureThread()
            let params = GenerateParams(
                messages: .array([
                    .object([
                        "role": .string("user"),
                        "content": .string(userText),
                    ])
                ]),
                threadId: identity.threadId,
                resourceId: identity.resourceId
            )

            let stream = try await client.agent(id: agentId).stream(params)
            for try await chunk in stream {
                guard !Task.isCancelled else { return }
                if let delta = Self.textDelta(from: chunk) {
                    appendDelta(delta, to: assistantId)
                }
            }
        } catch is CancellationError {
            // User-initiated cancel — silent.
        } catch {
            errorMessage = String(describing: error)
        }
    }

    private func ensureThread() async throws -> ThreadIdentity {
        if threadIdentity.threadId != nil {
            return threadIdentity
        }
        let params = CreateMemoryThreadParams(
            resourceId: threadIdentity.resourceId,
            agentId: agentId,
            title: "iOS Showcase Chat"
        )
        let info = try await client.createMemoryThread(params)
        var updated = threadIdentity
        updated.threadId = info.id
        threadIdentity = updated
        threadStore.save(updated)
        return updated
    }

    private func appendDelta(_ delta: String, to id: UUID) {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
        messages[index].text.append(delta)
    }

    private func finishStreaming() {
        for index in messages.indices where messages[index].isStreaming {
            messages[index].isStreaming = false
        }
    }

    /// Lifts a user-visible text delta out of a Mastra Data Stream chunk.
    /// Handles the `text-delta` and `text` shapes emitted by the JS client.
    static func textDelta(from chunk: JSONValue) -> String? {
        guard case .string(let type) = chunk["type"] ?? .null else { return nil }
        switch type {
        case "text-delta":
            return chunk["textDelta"]?.stringValue
                ?? chunk["payload"]?["text"]?.stringValue
        case "text":
            return chunk["text"]?.stringValue
        default:
            return nil
        }
    }

    #if DEBUG
    /// Preview-only seed. Never use from production code paths.
    static func previewSeed(
        client: MastraClient,
        agentId: String,
        messages: [ChatMessage],
        threadId: String
    ) -> ChatController {
        let store = UserDefaultsThreadStore(
            defaults: UserDefaults(suiteName: "preview.\(UUID().uuidString)")!
        )
        store.save(ThreadIdentity(threadId: threadId, resourceId: "preview-resource"))
        let controller = ChatController(client: client, agentId: agentId, threadStore: store)
        controller.messages = messages
        return controller
    }
    #endif

    static func message(from value: JSONValue) -> ChatMessage? {
        guard let roleString = value["role"]?.stringValue,
              let role = ChatMessage.Role(rawValue: roleString) else { return nil }
        let text = Self.extractText(from: value["content"] ?? .null)
        guard !text.isEmpty else { return nil }
        return ChatMessage(role: role, text: text)
    }

    private static func extractText(from content: JSONValue) -> String {
        switch content {
        case .string(let s):
            return s
        case .array(let parts):
            return parts.compactMap { part in
                if case .string(let s) = part { return s }
                if part["type"]?.stringValue == "text" {
                    return part["text"]?.stringValue
                }
                return nil
            }.joined()
        default:
            return ""
        }
    }
}
