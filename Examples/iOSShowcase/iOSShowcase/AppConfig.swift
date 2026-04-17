import Foundation

struct AppConfig {
    let baseURL: URL
    let apiKey: String
    let agentId: String

    static func load(bundle: Bundle = .main) throws -> AppConfig {
        let info = bundle.infoDictionary ?? [:]

        let rawBaseURL = (info["MASTRA_BASE_URL"] as? String) ?? ""
        let trimmedBaseURL = rawBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedBaseURL.isEmpty else {
            throw ConfigError(message: "MASTRA_BASE_URL is not set. Copy Secrets.xcconfig.example to Secrets.xcconfig and fill it in.")
        }
        guard let url = URL(string: trimmedBaseURL) else {
            throw ConfigError(message: "MASTRA_BASE_URL is not a valid URL: \(trimmedBaseURL)")
        }

        let agentId = ((info["MASTRA_AGENT_ID"] as? String) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !agentId.isEmpty else {
            throw ConfigError(message: "MASTRA_AGENT_ID is not set. Add it to Secrets.xcconfig.")
        }

        let apiKey = ((info["MASTRA_API_KEY"] as? String) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return AppConfig(baseURL: url, apiKey: apiKey, agentId: agentId)
    }
}

struct ConfigError: Error {
    let message: String
}
