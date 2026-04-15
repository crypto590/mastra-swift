import Foundation

// MARK: - AgentCard
// Mirrors `AgentCard` from `@mastra/core/a2a`. The A2A AgentCard is a
// well-known public document describing an agent's metadata, skills, and
// transport endpoints. The shape matches the A2A protocol spec; we keep the
// open extension surfaces (`capabilities`, `authentication`, `metadata`,
// `skills[].metadata`, etc.) as `JSONValue` because the JS client uses
// `Record<string, any>` or loosely typed shapes for them.

/// Mirrors JS `AgentCard`.
public struct AgentCard: Sendable, Codable {
    public let name: String
    public let description: String?
    public let url: String?
    public let version: String?
    public let provider: AgentCardProvider?
    public let documentationUrl: String?
    public let capabilities: JSONValue?
    public let authentication: JSONValue?
    public let defaultInputModes: [String]?
    public let defaultOutputModes: [String]?
    public let skills: [AgentCardSkill]?
    public let metadata: JSONValue?

    public init(
        name: String,
        description: String? = nil,
        url: String? = nil,
        version: String? = nil,
        provider: AgentCardProvider? = nil,
        documentationUrl: String? = nil,
        capabilities: JSONValue? = nil,
        authentication: JSONValue? = nil,
        defaultInputModes: [String]? = nil,
        defaultOutputModes: [String]? = nil,
        skills: [AgentCardSkill]? = nil,
        metadata: JSONValue? = nil
    ) {
        self.name = name
        self.description = description
        self.url = url
        self.version = version
        self.provider = provider
        self.documentationUrl = documentationUrl
        self.capabilities = capabilities
        self.authentication = authentication
        self.defaultInputModes = defaultInputModes
        self.defaultOutputModes = defaultOutputModes
        self.skills = skills
        self.metadata = metadata
    }
}

public struct AgentCardProvider: Sendable, Codable {
    public let organization: String?
    public let url: String?

    public init(organization: String? = nil, url: String? = nil) {
        self.organization = organization
        self.url = url
    }
}

public struct AgentCardSkill: Sendable, Codable {
    public let id: String
    public let name: String
    public let description: String?
    public let tags: [String]?
    public let examples: [String]?
    public let inputModes: [String]?
    public let outputModes: [String]?
    public let metadata: JSONValue?

    public init(
        id: String,
        name: String,
        description: String? = nil,
        tags: [String]? = nil,
        examples: [String]? = nil,
        inputModes: [String]? = nil,
        outputModes: [String]? = nil,
        metadata: JSONValue? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.tags = tags
        self.examples = examples
        self.inputModes = inputModes
        self.outputModes = outputModes
        self.metadata = metadata
    }
}

// MARK: - Message / Part

/// Mirrors JS `A2AMessage` / `Message` from `@mastra/core/a2a`. Messages carry
/// `parts` which can be text, file, or data. The `role` is `user` | `agent`
/// in the A2A spec. `kind` is always `"message"` for messages.
public struct A2AMessage: Sendable, Codable {
    public var messageId: String
    public var kind: String
    public var role: String
    public var parts: [A2APart]
    public var taskId: String?
    public var contextId: String?
    public var referenceTaskIds: [String]?
    public var metadata: JSONValue?

    public init(
        messageId: String,
        kind: String = "message",
        role: String,
        parts: [A2APart],
        taskId: String? = nil,
        contextId: String? = nil,
        referenceTaskIds: [String]? = nil,
        metadata: JSONValue? = nil
    ) {
        self.messageId = messageId
        self.kind = kind
        self.role = role
        self.parts = parts
        self.taskId = taskId
        self.contextId = contextId
        self.referenceTaskIds = referenceTaskIds
        self.metadata = metadata
    }
}

/// Mirrors the A2A `Part` union: `TextPart | FilePart | DataPart`.
public enum A2APart: Sendable, Codable {
    case text(text: String, metadata: JSONValue? = nil)
    case file(file: JSONValue, metadata: JSONValue? = nil)
    case data(data: JSONValue, metadata: JSONValue? = nil)

    private enum CodingKeys: String, CodingKey {
        case kind, text, file, data, metadata
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(String.self, forKey: .kind)
        let metadata = try container.decodeIfPresent(JSONValue.self, forKey: .metadata)
        switch kind {
        case "text":
            let text = try container.decode(String.self, forKey: .text)
            self = .text(text: text, metadata: metadata)
        case "file":
            let file = try container.decode(JSONValue.self, forKey: .file)
            self = .file(file: file, metadata: metadata)
        case "data":
            let data = try container.decode(JSONValue.self, forKey: .data)
            self = .data(data: data, metadata: metadata)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .kind,
                in: container,
                debugDescription: "Unknown A2A part kind: \(kind)"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let text, let metadata):
            try container.encode("text", forKey: .kind)
            try container.encode(text, forKey: .text)
            try container.encodeIfPresent(metadata, forKey: .metadata)
        case .file(let file, let metadata):
            try container.encode("file", forKey: .kind)
            try container.encode(file, forKey: .file)
            try container.encodeIfPresent(metadata, forKey: .metadata)
        case .data(let data, let metadata):
            try container.encode("data", forKey: .kind)
            try container.encode(data, forKey: .data)
            try container.encodeIfPresent(metadata, forKey: .metadata)
        }
    }
}

// MARK: - Task

/// Mirrors JS `Task` from `@mastra/core/a2a`. `kind` is always `"task"`.
public struct A2ATask: Sendable, Codable {
    public let id: String
    public let contextId: String?
    public let kind: String?
    public let status: A2ATaskStatus
    public let artifacts: [JSONValue]?
    public let history: [A2AMessage]?
    public let metadata: JSONValue?

    public init(
        id: String,
        contextId: String? = nil,
        kind: String? = "task",
        status: A2ATaskStatus,
        artifacts: [JSONValue]? = nil,
        history: [A2AMessage]? = nil,
        metadata: JSONValue? = nil
    ) {
        self.id = id
        self.contextId = contextId
        self.kind = kind
        self.status = status
        self.artifacts = artifacts
        self.history = history
        self.metadata = metadata
    }
}

/// Mirrors JS `TaskStatus`. `state` is one of the A2A task states.
public struct A2ATaskStatus: Sendable, Codable {
    public let state: String
    public let message: A2AMessage?
    public let timestamp: String?

    public init(state: String, message: A2AMessage? = nil, timestamp: String? = nil) {
        self.state = state
        self.message = message
        self.timestamp = timestamp
    }
}

// MARK: - Request params

/// Mirrors JS `MessageSendParams`. Carries a message plus optional
/// `MessageSendConfiguration` and `metadata`.
public struct MessageSendParams: Sendable, Codable {
    public var message: A2AMessage
    public var configuration: JSONValue?
    public var metadata: JSONValue?

    public init(
        message: A2AMessage,
        configuration: JSONValue? = nil,
        metadata: JSONValue? = nil
    ) {
        self.message = message
        self.configuration = configuration
        self.metadata = metadata
    }
}

/// Mirrors JS `TaskQueryParams`. `id` is the task id to query/cancel.
public struct TaskQueryParams: Sendable, Codable {
    public var id: String
    public var historyLength: Int?
    public var metadata: JSONValue?

    public init(id: String, historyLength: Int? = nil, metadata: JSONValue? = nil) {
        self.id = id
        self.historyLength = historyLength
        self.metadata = metadata
    }
}

// MARK: - JSON-RPC responses

/// Mirrors JS `SendMessageResponse`: a JSON-RPC 2.0 response whose `result`
/// is either an `A2AMessage` or an `A2ATask`, with an optional `error`. We
/// keep `result` as `JSONValue` because the JS client treats the union
/// loosely and consumers downstream typically destructure manually.
public struct SendMessageResponse: Sendable, Codable {
    public let jsonrpc: String
    public let id: JSONValue?
    public let result: JSONValue?
    public let error: A2AJSONRPCError?

    public init(
        jsonrpc: String = "2.0",
        id: JSONValue? = nil,
        result: JSONValue? = nil,
        error: A2AJSONRPCError? = nil
    ) {
        self.jsonrpc = jsonrpc
        self.id = id
        self.result = result
        self.error = error
    }
}

/// Mirrors JS `GetTaskResponse`: a JSON-RPC 2.0 response whose `result` is
/// an `A2ATask`.
public struct GetTaskResponse: Sendable, Codable {
    public let jsonrpc: String
    public let id: JSONValue?
    public let result: A2ATask?
    public let error: A2AJSONRPCError?

    public init(
        jsonrpc: String = "2.0",
        id: JSONValue? = nil,
        result: A2ATask? = nil,
        error: A2AJSONRPCError? = nil
    ) {
        self.jsonrpc = jsonrpc
        self.id = id
        self.result = result
        self.error = error
    }
}

/// Mirrors JS JSON-RPC error shape.
public struct A2AJSONRPCError: Sendable, Codable {
    public let code: Int
    public let message: String
    public let data: JSONValue?

    public init(code: Int, message: String, data: JSONValue? = nil) {
        self.code = code
        self.message = message
        self.data = data
    }
}
