import Foundation

/// Equivalent of JS `AgentVoice`. Exposes voice provider endpoints for a
/// specific agent; instances are obtained via `Agent.voice`.
public struct AgentVoice: Sendable {
    public let agentId: String
    public let version: AgentVersionIdentifier?
    let base: BaseResource

    init(base: BaseResource, agentId: String, version: AgentVersionIdentifier?) {
        self.base = base
        self.agentId = agentId
        self.version = version
    }

    private func versionQuery() -> [URLQueryItem] { version?.queryItems ?? [] }

    /// Convert text to speech. Returns the raw audio byte stream. Mirrors JS
    /// `voice.speak(text, options?)` which also returns a `Response` with a
    /// streaming body.
    public func speak(
        text: String,
        options: JSONValue? = nil
    ) async throws -> HTTPStreamingResponse {
        var body: JSONObject = ["text": .string(text)]
        if let options { body["options"] = options }
        return try await base.streamingRequest(
            "/agents/\(agentId)/voice/speak",
            method: .POST,
            query: versionQuery(),
            body: .json(.object(body))
        )
    }

    /// Transcribe audio using the agent's voice provider. Mirrors JS
    /// `voice.listen(audio, options?)` which posts multipart form data.
    public func listen(
        audio: Data,
        mimeType: String = "audio/wav",
        filename: String = "audio.wav",
        options: JSONValue? = nil
    ) async throws -> ListenResponse {
        var parts: [MultipartPart] = [
            MultipartPart(name: "audio", filename: filename, contentType: mimeType, data: audio)
        ]
        if let options {
            let json = try JSONEncoder().encode(options)
            parts.append(MultipartPart(name: "options", data: json))
        }
        return try await base.request(
            "/agents/\(agentId)/voice/listen",
            method: .POST,
            query: versionQuery(),
            body: .multipart(parts)
        )
    }

    public struct ListenResponse: Sendable, Codable {
        public let text: String
    }

    /// Mirrors JS `voice.getSpeakers()`. Returns an array of speaker entries.
    public func getSpeakers() async throws -> [JSONValue] {
        try await base.request(
            "/agents/\(agentId)/voice/speakers",
            method: .GET,
            query: versionQuery()
        )
    }

    /// Mirrors JS `voice.getListener()` → `{ enabled: boolean }`.
    public func getListener() async throws -> ListenerResponse {
        try await base.request(
            "/agents/\(agentId)/voice/listener",
            method: .GET,
            query: versionQuery()
        )
    }

    public struct ListenerResponse: Sendable, Codable {
        public let enabled: Bool
    }
}
