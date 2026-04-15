import Foundation

/// Equivalent of JS `Agent` resource. Every method maps to an endpoint on the
/// Mastra agent API; paths match the JS client exactly. Acquire an instance
/// via `MastraClient.agent(id:version:)`.
public struct Agent: Sendable {
    public let agentId: String
    public let version: AgentVersionIdentifier?
    public let voice: AgentVoice
    let base: BaseResource

    init(base: BaseResource, agentId: String, version: AgentVersionIdentifier?) {
        self.base = base
        self.agentId = agentId
        self.version = version
        self.voice = AgentVoice(base: base, agentId: agentId, version: version)
    }

    // MARK: - Query helpers

    private func versionQuery() -> [URLQueryItem] { version?.queryItems ?? [] }

    // MARK: - Details / instructions / clone

    /// Mirrors JS `agent.details()` → `GET /agents/:id`.
    public func details() async throws -> GetAgentResponse {
        try await base.request(
            "/agents/\(agentId)",
            query: versionQuery()
        )
    }

    /// Mirrors JS `agent.enhanceInstructions(instructions, comment)`.
    public func enhanceInstructions(
        instructions: String,
        comment: String
    ) async throws -> EnhanceInstructionsResponse {
        let body: JSONValue = .object([
            "instructions": .string(instructions),
            "comment": .string(comment),
        ])
        return try await base.request(
            "/agents/\(agentId)/instructions/enhance",
            method: .POST,
            body: .json(body)
        )
    }

    /// Mirrors JS `agent.clone(params?)` → `POST /agents/:id/clone`.
    public func clone(_ params: CloneAgentParams = .init()) async throws -> StoredAgentResponse {
        try await base.request(
            "/agents/\(agentId)/clone",
            method: .POST,
            body: .json(params.body())
        )
    }

    // MARK: - Versions (stored-agent overrides)

    private var versionsPath: String { "/stored/agents/\(agentId)/versions" }

    public func listVersions(
        _ params: ListAgentVersionsParams = .init()
    ) async throws -> ListAgentVersionsResponse {
        try await base.request(versionsPath, query: params.queryItems)
    }

    public func createVersion(
        _ params: CreateCodeAgentVersionParams = .init()
    ) async throws -> AgentVersionResponse {
        let body: JSONValue
        do {
            let data = try JSONEncoder().encode(params)
            body = try JSONDecoder().decode(JSONValue.self, from: data)
        } catch {
            body = .object([:])
        }
        return try await base.request(
            versionsPath,
            method: .POST,
            body: .json(body)
        )
    }

    public func getVersion(versionId: String) async throws -> AgentVersionResponse {
        try await base.request("\(versionsPath)/\(versionId)")
    }

    public func activateVersion(versionId: String) async throws -> ActivateAgentVersionResponse {
        try await base.request("\(versionsPath)/\(versionId)/activate", method: .POST)
    }

    public func restoreVersion(versionId: String) async throws -> RestoreAgentVersionResponse {
        try await base.request("\(versionsPath)/\(versionId)/restore", method: .POST)
    }

    public func deleteVersion(versionId: String) async throws -> DeleteAgentVersionResponse {
        try await base.request("\(versionsPath)/\(versionId)", method: .DELETE)
    }

    public func compareVersions(
        fromId: String,
        toId: String
    ) async throws -> CompareAgentVersionsResponse {
        try await base.request(
            "\(versionsPath)/compare",
            query: [
                URLQueryItem(name: "from", value: fromId),
                URLQueryItem(name: "to", value: toId),
            ]
        )
    }

    // MARK: - Generate (legacy / current)

    /// Mirrors JS `agent.generateLegacy(params)` → `POST /agents/:id/generate-legacy`.
    /// Includes the client-tools recursive loop: when the response's
    /// `finishReason` is `tool-calls`, each requested call is dispatched to the
    /// matching local `ClientTool`, and the function recurses with updated
    /// messages.
    public func generateLegacy(_ params: GenerateParams) async throws -> JSONValue {
        try await runGenerate(path: "/agents/\(agentId)/generate-legacy", params: params)
    }

    /// Mirrors JS `agent.generate(messages, options?)` → `POST /agents/:id/generate`.
    /// Includes the client-tools recursive loop.
    public func generate(_ params: GenerateParams) async throws -> JSONValue {
        try await runGenerate(path: "/agents/\(agentId)/generate", params: params)
    }

    /// Implements the JS client-tools loop for generate.
    /// Protects against infinite recursion with a hard depth cap.
    private func runGenerate(
        path: String,
        params: GenerateParams,
        depth: Int = 0,
        maxDepth: Int = 8
    ) async throws -> JSONValue {
        let response: JSONValue = try await base.request(
            path,
            method: .POST,
            body: .json(params.body())
        )

        guard depth < maxDepth else { return response }
        guard response["finishReason"]?.stringValue == "tool-calls" else { return response }
        guard let clientTools = params.clientTools, !clientTools.isEmpty else { return response }
        guard let toolCalls = response["toolCalls"]?.arrayValue else { return response }

        let byId = Dictionary(uniqueKeysWithValues: clientTools.map { ($0.id, $0) })

        for toolCall in toolCalls {
            // JS supports both shapes: payload-nested (v5) and flat (legacy).
            let toolName = toolCall["payload"]?["toolName"]?.stringValue
                ?? toolCall["toolName"]?.stringValue
            let args = toolCall["payload"]?["args"] ?? toolCall["args"] ?? .null
            let toolCallId = toolCall["payload"]?["toolCallId"]?.stringValue
                ?? toolCall["toolCallId"]?.stringValue

            guard let toolName, let clientTool = byId[toolName], let toolCallId else {
                continue
            }

            let result = try await clientTool.execute(args)

            let updatedMessages = Self.appendToolResult(
                to: params,
                response: response,
                toolCallId: toolCallId,
                toolName: toolName,
                result: result
            )

            var next = params
            next.messages = updatedMessages
            return try await runGenerate(
                path: path,
                params: next,
                depth: depth + 1,
                maxDepth: maxDepth
            )
        }

        return response
    }

    /// Builds the updated messages array for a recursive generate call. Mirrors
    /// JS behavior: when `threadId` is present the server has memory, so we
    /// only include the fresh response messages; otherwise we prepend the
    /// original user messages.
    private static func appendToolResult(
        to params: GenerateParams,
        response: JSONValue,
        toolCallId: String,
        toolName: String,
        result: JSONValue
    ) -> JSONValue {
        let responseMessages = response["response"]?["messages"]?.arrayValue ?? []
        let toolMessage: JSONValue = .object([
            "role": .string("tool"),
            "content": .array([
                .object([
                    "type": .string("tool-result"),
                    "toolCallId": .string(toolCallId),
                    "toolName": .string(toolName),
                    "result": result,
                ])
            ]),
        ])
        var newMessages = responseMessages
        newMessages.append(toolMessage)

        let hasThread = params.threadId != nil || (params.memory?["thread"] != nil)
        if hasThread { return .array(newMessages) }

        // Stateless: prefix with original user messages.
        if case .array(let originals) = params.messages {
            return .array(originals + newMessages)
        }
        return .array(newMessages)
    }

    // MARK: - Stream / network (MDS)

    /// Mirrors JS `agent.stream(messages, options)` → `POST /agents/:id/stream`.
    /// Returns the decoded Mastra Data Stream as an async sequence of
    /// `JSONValue` chunks. Client-side tool execution over the stream is not
    /// performed here — call `generate` if you need the tool-calls loop, or
    /// observe the stream and recurse from the caller.
    public func stream(_ params: GenerateParams) async throws -> AsyncThrowingStream<JSONValue, Error> {
        try await openStream(path: "/agents/\(agentId)/stream", body: .json(params.body()))
    }

    /// Mirrors JS `agent.network(messages, options)` → `POST /agents/:id/network`.
    public func network(_ params: GenerateParams) async throws -> AsyncThrowingStream<JSONValue, Error> {
        try await openStream(path: "/agents/\(agentId)/network", body: .json(params.body()))
    }

    private func openStream(
        path: String,
        body: HTTPBody
    ) async throws -> AsyncThrowingStream<JSONValue, Error> {
        let response = try await base.streamingRequest(path, method: .POST, body: body)
        return MastraAgentStreamDecoder.chunks(from: response.bytes)
    }

    // MARK: - Tool approval (stream-based)

    public struct ToolApprovalParams: Sendable {
        public var runId: String
        public var toolCallId: String
        public var requestContext: RequestContext?

        public init(
            runId: String,
            toolCallId: String,
            requestContext: RequestContext? = nil
        ) {
            self.runId = runId
            self.toolCallId = toolCallId
            self.requestContext = requestContext
        }

        func body() -> JSONValue {
            var obj: JSONObject = [
                "runId": .string(runId),
                "toolCallId": .string(toolCallId),
            ]
            if let requestContext {
                obj["requestContext"] = .object(requestContext.entries)
            }
            return .object(obj)
        }
    }

    /// Mirrors JS `approveToolCall(params)` → `POST /agents/:id/approve-tool-call` (streamed).
    public func approveToolCall(
        _ params: ToolApprovalParams
    ) async throws -> AsyncThrowingStream<JSONValue, Error> {
        try await openStream(
            path: "/agents/\(agentId)/approve-tool-call",
            body: .json(params.body())
        )
    }

    /// Mirrors JS `declineToolCall(params)` → `POST /agents/:id/decline-tool-call` (streamed).
    public func declineToolCall(
        _ params: ToolApprovalParams
    ) async throws -> AsyncThrowingStream<JSONValue, Error> {
        try await openStream(
            path: "/agents/\(agentId)/decline-tool-call",
            body: .json(params.body())
        )
    }

    /// Mirrors JS `approveToolCallGenerate(params)` (non-streaming).
    public func approveToolCallGenerate(
        _ params: ToolApprovalParams
    ) async throws -> JSONValue {
        try await base.request(
            "/agents/\(agentId)/approve-tool-call-generate",
            method: .POST,
            body: .json(params.body())
        )
    }

    /// Mirrors JS `declineToolCallGenerate(params)` (non-streaming).
    public func declineToolCallGenerate(
        _ params: ToolApprovalParams
    ) async throws -> JSONValue {
        try await base.request(
            "/agents/\(agentId)/decline-tool-call-generate",
            method: .POST,
            body: .json(params.body())
        )
    }

    public struct NetworkApprovalParams: Sendable {
        public var runId: String
        public var requestContext: RequestContext?

        public init(runId: String, requestContext: RequestContext? = nil) {
            self.runId = runId
            self.requestContext = requestContext
        }

        func body() -> JSONValue {
            var obj: JSONObject = ["runId": .string(runId)]
            if let requestContext {
                obj["requestContext"] = .object(requestContext.entries)
            }
            return .object(obj)
        }
    }

    /// Mirrors JS `approveNetworkToolCall(params)` (streamed).
    public func approveNetworkToolCall(
        _ params: NetworkApprovalParams
    ) async throws -> AsyncThrowingStream<JSONValue, Error> {
        try await openStream(
            path: "/agents/\(agentId)/approve-network-tool-call",
            body: .json(params.body())
        )
    }

    /// Mirrors JS `declineNetworkToolCall(params)` (streamed).
    public func declineNetworkToolCall(
        _ params: NetworkApprovalParams
    ) async throws -> AsyncThrowingStream<JSONValue, Error> {
        try await openStream(
            path: "/agents/\(agentId)/decline-network-tool-call",
            body: .json(params.body())
        )
    }

    // MARK: - Tool access

    /// Mirrors JS `getTool(toolId)` → `GET /agents/:id/tools/:toolId`.
    public func getTool(toolId: String) async throws -> GetToolResponse {
        try await base.request(
            "/agents/\(agentId)/tools/\(toolId)",
            query: versionQuery()
        )
    }

    /// Mirrors JS `executeTool(toolId, { data, requestContext })`.
    public func executeTool(
        toolId: String,
        data: JSONValue,
        requestContext: RequestContext? = nil
    ) async throws -> JSONValue {
        var body: JSONObject = ["data": data]
        if let requestContext {
            body["requestContext"] = .object(requestContext.entries)
        }
        return try await base.request(
            "/agents/\(agentId)/tools/\(toolId)/execute",
            method: .POST,
            body: .json(.object(body))
        )
    }

    // MARK: - Model management

    /// Mirrors JS `updateModel(params)` → `POST /agents/:id/model`.
    public func updateModel(_ params: UpdateModelParams) async throws -> UpdateModelResponse {
        let data = try JSONEncoder().encode(params)
        let body = try JSONDecoder().decode(JSONValue.self, from: data)
        return try await base.request(
            "/agents/\(agentId)/model",
            method: .POST,
            body: .json(body)
        )
    }

    /// Mirrors JS `resetModel()` → `POST /agents/:id/model/reset`.
    public func resetModel() async throws -> UpdateModelResponse {
        try await base.request(
            "/agents/\(agentId)/model/reset",
            method: .POST,
            body: .json(.object([:]))
        )
    }

    /// Mirrors JS `updateModelInModelList({ modelConfigId, ... })` →
    /// `POST /agents/:id/models/:modelConfigId`.
    public func updateModelInModelList(
        _ params: UpdateModelInModelListParams
    ) async throws -> UpdateModelResponse {
        // JS destructures out `modelConfigId` from the body.
        var obj: JSONObject = [:]
        if let model = params.model {
            obj["model"] = .object([
                "modelId": .string(model.modelId),
                "provider": .string(model.provider),
            ])
        }
        if let maxRetries = params.maxRetries { obj["maxRetries"] = .int(Int64(maxRetries)) }
        if let enabled = params.enabled { obj["enabled"] = .bool(enabled) }
        return try await base.request(
            "/agents/\(agentId)/models/\(params.modelConfigId)",
            method: .POST,
            body: .json(.object(obj))
        )
    }

    /// Mirrors JS `reorderModelList(params)` → `POST /agents/:id/models/reorder`.
    public func reorderModelList(
        _ params: ReorderModelListParams
    ) async throws -> UpdateModelResponse {
        let ids: [JSONValue] = params.reorderedModelIds.map { .string($0) }
        let body: JSONValue = .object(["reorderedModelIds": .array(ids)])
        return try await base.request(
            "/agents/\(agentId)/models/reorder",
            method: .POST,
            body: .json(body)
        )
    }
}
