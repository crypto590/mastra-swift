import SwiftUI
import Mastra

@main
struct iOSShowcaseApp: App {
    @State private var appState: AppState = .loading

    var body: some Scene {
        WindowGroup {
            switch appState {
            case .loading:
                ProgressView()
                    .task { await bootstrap() }
            case .ready(let controller):
                NavigationStack {
                    ChatView(controller: controller)
                }
            case .misconfigured(let message):
                MisconfiguredView(message: message)
            }
        }
    }

    private func bootstrap() async {
        do {
            let config = try AppConfig.load()
            let client = try MastraClient(
                baseURL: config.baseURL,
                auth: config.apiKey.isEmpty ? .none : .bearer { config.apiKey }
            )
            let controller = ChatController(
                client: client,
                agentId: config.agentId,
                threadStore: UserDefaultsThreadStore()
            )
            appState = .ready(controller)
        } catch let error as ConfigError {
            appState = .misconfigured(error.message)
        } catch {
            appState = .misconfigured(String(describing: error))
        }
    }
}

private enum AppState {
    case loading
    case ready(ChatController)
    case misconfigured(String)
}
