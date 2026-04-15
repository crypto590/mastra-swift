import Foundation
import Mastra

#if canImport(SwiftUI)
import SwiftUI
#endif

/// Shared configuration for the demo app. Reads `MASTRA_BASE_URL` and
/// `MASTRA_API_KEY` from the environment; falls back to localhost.
enum DemoConfig {
    static let agentId: String = ProcessInfo.processInfo
        .environment["MASTRA_AGENT_ID"] ?? "assistant"

    static func makeClient() throws -> MastraClient {
        let env = ProcessInfo.processInfo.environment
        let baseURLString = env["MASTRA_BASE_URL"] ?? "http://localhost:4111"
        guard let baseURL = URL(string: baseURLString) else {
            throw NSError(
                domain: "SwiftUIChat",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid MASTRA_BASE_URL: \(baseURLString)"]
            )
        }
        let apiKey = env["MASTRA_API_KEY"] ?? ""
        return try MastraClient(
            baseURL: baseURL,
            auth: .bearer { apiKey }
        )
    }
}

#if canImport(SwiftUI)
@available(iOS 17, macOS 14, tvOS 17, watchOS 10, visionOS 1, *)
@main
struct SwiftUIChatApp: App {
    @State private var controller: ChatController = {
        let client = (try? DemoConfig.makeClient())
            ?? (try! MastraClient(baseURL: URL(string: "http://localhost:4111")!))
        return ChatController(client: client, agentId: DemoConfig.agentId)
    }()

    var body: some Scene {
        WindowGroup("Mastra Chat") {
            ChatView(controller: controller)
                .frame(minWidth: 420, minHeight: 520)
        }
    }
}
#else
// Linux / environments without SwiftUI: print a manual-test stub.
@main
struct SwiftUIChatApp {
    static func main() {
        print("SwiftUIChat example")
        print("-------------------")
        print("SwiftUI is not available on this platform; this binary is")
        print("a link-check only. Build and run on iOS/macOS/tvOS/visionOS")
        print("to see the chat UI.")
        print("")
        print("Configuration:")
        print("  MASTRA_BASE_URL = \(ProcessInfo.processInfo.environment["MASTRA_BASE_URL"] ?? "http://localhost:4111")")
        print("  MASTRA_AGENT_ID = \(DemoConfig.agentId)")
    }
}
#endif
