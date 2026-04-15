import Foundation

// MARK: - Phase

/// Mirrors JS `ProcessorPhase` — the set of lifecycle phases a processor can run in.
public enum ProcessorPhase: String, Sendable, Codable, Hashable {
    case input
    case inputStep
    case outputStream
    case outputResult
    case outputStep
}

// MARK: - Attachment configuration

/// Mirrors JS `ProcessorConfiguration`.
public struct ProcessorConfiguration: Sendable, Codable, Hashable {
    public let agentId: String
    public let agentName: String
    public let type: AttachmentType

    public enum AttachmentType: String, Sendable, Codable, Hashable {
        case input
        case output
    }

    public init(agentId: String, agentName: String, type: AttachmentType) {
        self.agentId = agentId
        self.agentName = agentName
        self.type = type
    }
}

// MARK: - List / details responses

/// Mirrors JS `GetProcessorResponse` — the per-entry shape returned by
/// `client.listProcessors()`.
public struct GetProcessorResponse: Sendable, Codable {
    public let id: String
    public let name: String?
    public let description: String?
    public let phases: [ProcessorPhase]
    public let agentIds: [String]
    public let isWorkflow: Bool
}

/// Mirrors JS `GetProcessorDetailResponse` — the full detail shape returned
/// by `processor.details()`.
public struct GetProcessorDetailResponse: Sendable, Codable {
    public let id: String
    public let name: String?
    public let description: String?
    public let phases: [ProcessorPhase]
    public let configurations: [ProcessorConfiguration]
    public let isWorkflow: Bool
}

/// Mirrors JS `Record<string, GetProcessorResponse>` — wrapped for clarity.
public struct ListProcessorsResponse: Sendable {
    public let processors: [String: GetProcessorResponse]
    public init(_ processors: [String: GetProcessorResponse]) { self.processors = processors }
}

// MARK: - Execute

/// Mirrors JS `ExecuteProcessorParams`.
public struct ExecuteProcessorParams: Sendable {
    public var phase: ProcessorPhase
    /// `MastraDBMessage[]` in JS. Left as `JSONValue` (an array) because the
    /// message schema is deeply nested and better modeled by the caller.
    public var messages: JSONValue
    public var agentId: String?
    public var requestContext: RequestContext?

    public init(
        phase: ProcessorPhase,
        messages: JSONValue,
        agentId: String? = nil,
        requestContext: RequestContext? = nil
    ) {
        self.phase = phase
        self.messages = messages
        self.agentId = agentId
        self.requestContext = requestContext
    }

    /// JSON body matching the JS `processor.execute` payload shape.
    func body() -> JSONValue {
        var obj: JSONObject = [
            "phase": .string(phase.rawValue),
            "messages": messages,
        ]
        if let agentId {
            obj["agentId"] = .string(agentId)
        }
        if let requestContext {
            obj["requestContext"] = .object(requestContext.entries)
        }
        return .object(obj)
    }
}

/// Mirrors JS `ProcessorTripwireResult`.
public struct ProcessorTripwireResult: Sendable, Codable {
    public let triggered: Bool
    public let reason: String?
    public let metadata: JSONValue?
}

/// Mirrors JS `ExecuteProcessorResponse`.
public struct ExecuteProcessorResponse: Sendable, Codable {
    public let success: Bool
    public let phase: String
    public let messages: JSONValue?
    public let messageList: MessageList?
    public let tripwire: ProcessorTripwireResult?
    public let error: String?

    public struct MessageList: Sendable, Codable {
        public let messages: JSONValue
    }
}
