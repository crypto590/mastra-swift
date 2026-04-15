import Foundation

// MARK: - Conversation items

/// Mirrors JS `ConversationItemInputText` — `{ type: 'input_text', text: string }`.
public struct ConversationItemInputText: Sendable, Codable, Hashable {
    public var type: String
    public var text: String

    public init(type: String = "input_text", text: String) {
        self.type = type
        self.text = text
    }
}

/// Mirrors JS `ConversationItemMessage.content` — each element is either an
/// input_text or an output_text part.
public enum ConversationItemMessageContent: Sendable, Codable, Hashable {
    case inputText(ConversationItemInputText)
    case outputText(ResponseOutputText)
    case unknown(JSONValue)

    private enum TypeKey: String, CodingKey { case type }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: TypeKey.self)
        let type = (try? c.decode(String.self, forKey: .type)) ?? ""
        switch type {
        case "input_text":
            self = .inputText(try ConversationItemInputText(from: decoder))
        case "output_text":
            self = .outputText(try ResponseOutputText(from: decoder))
        default:
            self = .unknown(try JSONValue(from: decoder))
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .inputText(let v): try v.encode(to: encoder)
        case .outputText(let v): try v.encode(to: encoder)
        case .unknown(let v): try v.encode(to: encoder)
        }
    }
}

/// Mirrors JS `ConversationItemMessage`.
public struct ConversationItemMessage: Sendable, Codable, Hashable {
    public var id: String
    public var type: String
    public var role: String
    public var status: String
    public var content: [ConversationItemMessageContent]

    public init(
        id: String,
        type: String = "message",
        role: String,
        status: String = "completed",
        content: [ConversationItemMessageContent]
    ) {
        self.id = id
        self.type = type
        self.role = role
        self.status = status
        self.content = content
    }
}

/// Mirrors JS `ConversationItem`. Discriminated on `type` field.
public enum ConversationItem: Sendable, Codable, Hashable {
    case message(ConversationItemMessage)
    case functionCall(ResponseOutputFunctionCall)
    case functionCallOutput(ResponseOutputFunctionCallOutput)
    case unknown(JSONValue)

    private enum TypeKey: String, CodingKey { case type }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: TypeKey.self)
        let type = (try? c.decode(String.self, forKey: .type)) ?? ""
        switch type {
        case "message":
            self = .message(try ConversationItemMessage(from: decoder))
        case "function_call":
            self = .functionCall(try ResponseOutputFunctionCall(from: decoder))
        case "function_call_output":
            self = .functionCallOutput(try ResponseOutputFunctionCallOutput(from: decoder))
        default:
            self = .unknown(try JSONValue(from: decoder))
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .message(let m): try m.encode(to: encoder)
        case .functionCall(let f): try f.encode(to: encoder)
        case .functionCallOutput(let o): try o.encode(to: encoder)
        case .unknown(let v): try v.encode(to: encoder)
        }
    }
}

/// Mirrors JS `ConversationItemsPage`.
public struct ConversationItemsPage: Sendable, Codable, Hashable {
    public var object: String
    public var data: [ConversationItem]
    public var first_id: String?
    public var last_id: String?
    public var has_more: Bool

    public init(
        object: String = "list",
        data: [ConversationItem],
        first_id: String? = nil,
        last_id: String? = nil,
        has_more: Bool = false
    ) {
        self.object = object
        self.data = data
        self.first_id = first_id
        self.last_id = last_id
        self.has_more = has_more
    }
}

// MARK: - Conversation

/// Mirrors JS `Conversation`. The JS client types `thread` as `StorageThreadType`
/// (a memory package type); we preserve it as `JSONValue` to avoid cross-package
/// coupling — the memory resource owns the richer thread type.
public struct Conversation: Sendable, Codable, Hashable {
    public var id: String
    public var object: String
    public var thread: JSONValue

    public init(id: String, object: String = "conversation", thread: JSONValue) {
        self.id = id
        self.object = object
        self.thread = thread
    }
}

/// Mirrors JS `ConversationDeleted`.
public struct ConversationDeleted: Sendable, Codable, Hashable {
    public var id: String
    public var object: String
    public var deleted: Bool

    public init(id: String, object: String = "conversation.deleted", deleted: Bool = true) {
        self.id = id
        self.object = object
        self.deleted = deleted
    }
}

// MARK: - CreateConversationParams

/// Mirrors JS `CreateConversationParams`. JS destructures `requestContext`
/// out of the body and appends it as a query-string param instead.
public struct CreateConversationParams: Sendable {
    public var agent_id: String
    public var conversation_id: String?
    public var resource_id: String?
    public var title: String?
    public var metadata: [String: JSONValue]?
    public var requestContext: RequestContext?

    public init(
        agent_id: String,
        conversation_id: String? = nil,
        resource_id: String? = nil,
        title: String? = nil,
        metadata: [String: JSONValue]? = nil,
        requestContext: RequestContext? = nil
    ) {
        self.agent_id = agent_id
        self.conversation_id = conversation_id
        self.resource_id = resource_id
        self.title = title
        self.metadata = metadata
        self.requestContext = requestContext
    }

    func body() -> JSONValue {
        var obj: JSONObject = ["agent_id": .string(agent_id)]
        if let conversation_id { obj["conversation_id"] = .string(conversation_id) }
        if let resource_id { obj["resource_id"] = .string(resource_id) }
        if let title { obj["title"] = .string(title) }
        if let metadata { obj["metadata"] = .object(metadata) }
        return .object(obj)
    }
}
