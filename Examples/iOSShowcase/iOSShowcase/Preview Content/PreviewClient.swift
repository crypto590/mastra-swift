#if DEBUG
import Foundation
import Mastra

enum PreviewClient {
    @MainActor
    static func populatedController() -> ChatController {
        let client = try! MastraClient(baseURL: URL(string: "http://localhost:4111")!)
        return ChatController.previewSeed(
            client: client,
            agentId: "assistant",
            messages: [
                ChatMessage(role: .user, text: "What's Mastra?"),
                ChatMessage(role: .assistant, text: "Mastra is an open-source TypeScript framework for building agentic systems. This app talks to one of those agents over its streaming HTTP API."),
                ChatMessage(role: .user, text: "And this is a Swift client?"),
                ChatMessage(role: .assistant, text: "Yep — the mastra-swift SDK mirrors the JS client. This chat uses agent.stream() plus a persistent memory thread.", isStreaming: true),
            ],
            threadId: "thread_preview_7f3a91c2"
        )
    }
}
#endif
