import Foundation
import Mastra

#if canImport(Observation)
import Observation
#endif

/// Coordinates the SwiftUI chat view with an agent stream.
///
/// Uses `@Observable` on platforms that support it (iOS 17+, macOS 14+).
/// On Linux / older Apple platforms this class falls back to a plain
/// `@MainActor final class` — the view layer still compiles but must
/// poll via explicit re-renders.
#if canImport(Observation)
@MainActor
@Observable
final class ChatController {
    private(set) var messages: [ChatMessage] = []
    private(set) var isStreaming: Bool = false
    private(set) var errorMessage: String?

    private let client: MastraClient
    private let agentId: String
    private var streamTask: Task<Void, Never>?

    init(client: MastraClient, agentId: String) {
        self.client = client
        self.agentId = agentId
    }

    func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isStreaming else { return }

        let userMessage = ChatMessage(role: .user, text: trimmed)
        messages.append(userMessage)

        let assistant = ChatMessage(role: .assistant, text: "")
        messages.append(assistant)
        let assistantId = assistant.id

        isStreaming = true
        errorMessage = nil
        streamTask = Task { [client, agentId] in
            await self.consumeStream(
                client: client,
                agentId: agentId,
                userText: trimmed,
                assistantId: assistantId
            )
        }
    }

    func cancel() {
        streamTask?.cancel()
        streamTask = nil
        isStreaming = false
    }

    private func consumeStream(
        client: MastraClient,
        agentId: String,
        userText: String,
        assistantId: UUID
    ) async {
        defer { isStreaming = false }
        do {
            let agent = client.agent(id: agentId)
            let params = GenerateParams(
                messages: .array([
                    .object([
                        "role": .string("user"),
                        "content": .string(userText),
                    ])
                ])
            )
            let stream = try await agent.stream(params)
            for try await chunk in stream {
                guard !Task.isCancelled else { return }
                if let delta = Self.textDelta(from: chunk) {
                    appendDelta(delta, to: assistantId)
                }
            }
        } catch is CancellationError {
            // Caller cancelled — silent.
        } catch {
            errorMessage = String(describing: error)
        }
    }

    private func appendDelta(_ delta: String, to id: UUID) {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
        messages[index].text.append(delta)
    }

    /// Pulls a user-visible text delta out of a Mastra Data Stream chunk.
    /// Mirrors the common `{ type: "text-delta", textDelta: "…" }` shape
    /// emitted by the JS client; unknown chunk types are ignored.
    private static func textDelta(from chunk: JSONValue) -> String? {
        if case .string(let type) = chunk["type"] ?? .null {
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
        return nil
    }
}
#else
// Non-Apple fallback (no Observation framework available).
@MainActor
final class ChatController {
    private(set) var messages: [ChatMessage] = []
    private(set) var isStreaming: Bool = false
    private(set) var errorMessage: String?

    private let client: MastraClient
    private let agentId: String

    init(client: MastraClient, agentId: String) {
        self.client = client
        self.agentId = agentId
    }

    func send(_ text: String) {}
    func cancel() {}
}
#endif
