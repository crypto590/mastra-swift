import Foundation

// MARK: - Input

/// Mirrors JS `ResponseInputTextPart` — `{ type: 'input_text' | 'text' | 'output_text', text: string }`.
public struct ResponseInputTextPart: Sendable, Codable, Hashable {
    public var type: String
    public var text: String

    public init(type: String = "input_text", text: String) {
        self.type = type
        self.text = text
    }
}

/// Mirrors JS `ResponseInputMessage`. `content` is either a string or an array
/// of `ResponseInputTextPart` — modelled as an enum for serialization fidelity.
public struct ResponseInputMessage: Sendable, Codable, Hashable {
    public var role: String
    public var content: Content

    public enum Content: Sendable, Codable, Hashable {
        case text(String)
        case parts([ResponseInputTextPart])

        public init(from decoder: Decoder) throws {
            let c = try decoder.singleValueContainer()
            if let s = try? c.decode(String.self) { self = .text(s); return }
            self = .parts(try c.decode([ResponseInputTextPart].self))
        }

        public func encode(to encoder: Encoder) throws {
            var c = encoder.singleValueContainer()
            switch self {
            case .text(let s): try c.encode(s)
            case .parts(let p): try c.encode(p)
            }
        }
    }

    public init(role: String, content: Content) {
        self.role = role
        self.content = content
    }
}

// MARK: - Text format

/// Mirrors JS `ResponseTextFormat = { type: 'json_object' } | { type: 'json_schema', name, schema, strict?, description? }`.
public enum ResponseTextFormat: Sendable, Codable, Hashable {
    case jsonObject
    case jsonSchema(name: String, schema: JSONValue, strict: Bool? = nil, description: String? = nil)

    private enum CodingKeys: String, CodingKey {
        case type, name, schema, strict, description
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let type = try c.decode(String.self, forKey: .type)
        switch type {
        case "json_object":
            self = .jsonObject
        case "json_schema":
            let name = try c.decode(String.self, forKey: .name)
            let schema = try c.decode(JSONValue.self, forKey: .schema)
            let strict = try c.decodeIfPresent(Bool.self, forKey: .strict)
            let description = try c.decodeIfPresent(String.self, forKey: .description)
            self = .jsonSchema(name: name, schema: schema, strict: strict, description: description)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: c,
                debugDescription: "Unknown ResponseTextFormat type: \(type)"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .jsonObject:
            try c.encode("json_object", forKey: .type)
        case .jsonSchema(let name, let schema, let strict, let description):
            try c.encode("json_schema", forKey: .type)
            try c.encode(name, forKey: .name)
            try c.encode(schema, forKey: .schema)
            try c.encodeIfPresent(description, forKey: .description)
            try c.encodeIfPresent(strict, forKey: .strict)
        }
    }
}

/// Mirrors JS `ResponseTextConfig`.
public struct ResponseTextConfig: Sendable, Codable, Hashable {
    public var format: ResponseTextFormat
    public init(format: ResponseTextFormat) { self.format = format }
}

// MARK: - Output primitives

/// Mirrors JS `ResponseOutputText` — a single text content part in the output.
public struct ResponseOutputText: Sendable, Codable, Hashable {
    public var type: String
    public var text: String
    public var annotations: [JSONValue]?
    public var logprobs: [JSONValue]?

    public init(
        type: String = "output_text",
        text: String,
        annotations: [JSONValue]? = nil,
        logprobs: [JSONValue]? = nil
    ) {
        self.type = type
        self.text = text
        self.annotations = annotations
        self.logprobs = logprobs
    }
}

/// Mirrors JS `ResponseOutputMessage`.
public struct ResponseOutputMessage: Sendable, Codable, Hashable {
    public var id: String
    public var type: String
    public var role: String
    public var status: String
    public var content: [ResponseOutputText]

    public init(
        id: String,
        type: String = "message",
        role: String = "assistant",
        status: String,
        content: [ResponseOutputText]
    ) {
        self.id = id
        self.type = type
        self.role = role
        self.status = status
        self.content = content
    }
}

/// Mirrors JS `ResponseOutputFunctionCall`.
public struct ResponseOutputFunctionCall: Sendable, Codable, Hashable {
    public var id: String
    public var type: String
    public var call_id: String
    public var name: String
    public var arguments: String
    public var status: String?

    public init(
        id: String,
        type: String = "function_call",
        call_id: String,
        name: String,
        arguments: String,
        status: String? = nil
    ) {
        self.id = id
        self.type = type
        self.call_id = call_id
        self.name = name
        self.arguments = arguments
        self.status = status
    }
}

/// Mirrors JS `ResponseOutputFunctionCallOutput`.
public struct ResponseOutputFunctionCallOutput: Sendable, Codable, Hashable {
    public var id: String
    public var type: String
    public var call_id: String
    public var output: String

    public init(
        id: String,
        type: String = "function_call_output",
        call_id: String,
        output: String
    ) {
        self.id = id
        self.type = type
        self.call_id = call_id
        self.output = output
    }
}

/// Mirrors JS `ResponseOutputItem = ResponseOutputMessage | ResponseOutputFunctionCall | ResponseOutputFunctionCallOutput`.
public enum ResponseOutputItem: Sendable, Codable, Hashable {
    case message(ResponseOutputMessage)
    case functionCall(ResponseOutputFunctionCall)
    case functionCallOutput(ResponseOutputFunctionCallOutput)
    /// Forward-compat fallback: preserves unknown output shapes without erroring.
    case unknown(JSONValue)

    private enum TypeKey: String, CodingKey { case type }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: TypeKey.self)
        let type = (try? c.decode(String.self, forKey: .type)) ?? ""
        switch type {
        case "message":
            self = .message(try ResponseOutputMessage(from: decoder))
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

    public var asMessage: ResponseOutputMessage? {
        if case .message(let m) = self { return m } else { return nil }
    }
}

// MARK: - Usage / tools / response payload

/// Mirrors JS `ResponseUsage`.
public struct ResponseUsage: Sendable, Codable, Hashable {
    public var input_tokens: Int
    public var output_tokens: Int
    public var total_tokens: Int
    public var input_tokens_details: InputTokensDetails?
    public var output_tokens_details: OutputTokensDetails?

    public struct InputTokensDetails: Sendable, Codable, Hashable {
        public var cached_tokens: Int
        public init(cached_tokens: Int) { self.cached_tokens = cached_tokens }
    }

    public struct OutputTokensDetails: Sendable, Codable, Hashable {
        public var reasoning_tokens: Int
        public init(reasoning_tokens: Int) { self.reasoning_tokens = reasoning_tokens }
    }

    public init(
        input_tokens: Int,
        output_tokens: Int,
        total_tokens: Int,
        input_tokens_details: InputTokensDetails? = nil,
        output_tokens_details: OutputTokensDetails? = nil
    ) {
        self.input_tokens = input_tokens
        self.output_tokens = output_tokens
        self.total_tokens = total_tokens
        self.input_tokens_details = input_tokens_details
        self.output_tokens_details = output_tokens_details
    }
}

/// Mirrors JS `ResponseTool`.
public struct ResponseTool: Sendable, Codable, Hashable {
    public var type: String
    public var name: String
    public var description: String?
    public var parameters: JSONValue?

    public init(
        type: String = "function",
        name: String,
        description: String? = nil,
        parameters: JSONValue? = nil
    ) {
        self.type = type
        self.name = name
        self.description = description
        self.parameters = parameters
    }
}

/// Mirrors JS `ResponsesResponse.error`.
public struct ResponseError: Sendable, Codable, Hashable {
    public var code: String?
    public var message: String?
    public init(code: String? = nil, message: String? = nil) {
        self.code = code
        self.message = message
    }
}

/// Mirrors JS `ResponsesResponse.incomplete_details`.
public struct ResponseIncompleteDetails: Sendable, Codable, Hashable {
    public var reason: String?
    public init(reason: String? = nil) { self.reason = reason }
}

/// Mirrors JS `ResponsesResponse`. The JS client attaches a convenience
/// `output_text` derived from message parts; we preserve that field.
public struct ResponsesResponse: Sendable, Codable, Hashable {
    public var id: String
    public var object: String
    public var created_at: Int64
    public var completed_at: Int64?
    public var model: String
    public var status: String
    public var output: [ResponseOutputItem]
    public var usage: ResponseUsage?
    public var error: ResponseError?
    public var incomplete_details: ResponseIncompleteDetails?
    public var instructions: String?
    public var text: ResponseTextConfig?
    public var previous_response_id: String?
    public var conversation_id: String?
    public var providerOptions: JSONValue?
    public var tools: [ResponseTool]?
    public var store: Bool?
    public var output_text: String

    public init(
        id: String,
        object: String = "response",
        created_at: Int64,
        completed_at: Int64? = nil,
        model: String,
        status: String,
        output: [ResponseOutputItem],
        usage: ResponseUsage? = nil,
        error: ResponseError? = nil,
        incomplete_details: ResponseIncompleteDetails? = nil,
        instructions: String? = nil,
        text: ResponseTextConfig? = nil,
        previous_response_id: String? = nil,
        conversation_id: String? = nil,
        providerOptions: JSONValue? = nil,
        tools: [ResponseTool]? = nil,
        store: Bool? = nil,
        output_text: String = ""
    ) {
        self.id = id
        self.object = object
        self.created_at = created_at
        self.completed_at = completed_at
        self.model = model
        self.status = status
        self.output = output
        self.usage = usage
        self.error = error
        self.incomplete_details = incomplete_details
        self.instructions = instructions
        self.text = text
        self.previous_response_id = previous_response_id
        self.conversation_id = conversation_id
        self.providerOptions = providerOptions
        self.tools = tools
        self.store = store
        self.output_text = output_text
    }
}

/// Mirrors JS `ResponsesDeleteResponse`.
public struct ResponsesDeleteResponse: Sendable, Codable, Hashable {
    public var id: String
    public var object: String
    public var deleted: Bool

    public init(id: String, object: String = "response", deleted: Bool = true) {
        self.id = id
        self.object = object
        self.deleted = deleted
    }
}

// MARK: - CreateResponseParams

/// Mirrors JS `CreateResponseParams`. Input is either a plain string or an
/// array of `ResponseInputMessage`.
public struct CreateResponseParams: Sendable {
    public enum Input: Sendable, Hashable {
        case text(String)
        case messages([ResponseInputMessage])

        func jsonValue() -> JSONValue {
            switch self {
            case .text(let s): return .string(s)
            case .messages(let m):
                let data = (try? JSONEncoder().encode(m)) ?? Data()
                return (try? JSONDecoder().decode(JSONValue.self, from: data)) ?? .array([])
            }
        }
    }

    public var model: String?
    public var agent_id: String?
    public var input: Input
    public var instructions: String?
    public var text: ResponseTextConfig?
    public var conversation_id: String?
    public var providerOptions: JSONValue?
    public var store: Bool?
    public var previous_response_id: String?
    public var requestContext: RequestContext?

    public init(
        model: String? = nil,
        agent_id: String? = nil,
        input: Input,
        instructions: String? = nil,
        text: ResponseTextConfig? = nil,
        conversation_id: String? = nil,
        providerOptions: JSONValue? = nil,
        store: Bool? = nil,
        previous_response_id: String? = nil,
        requestContext: RequestContext? = nil
    ) {
        self.model = model
        self.agent_id = agent_id
        self.input = input
        self.instructions = instructions
        self.text = text
        self.conversation_id = conversation_id
        self.providerOptions = providerOptions
        self.store = store
        self.previous_response_id = previous_response_id
        self.requestContext = requestContext
    }

    /// Convenience init for a plain-text input.
    public init(
        model: String? = nil,
        agent_id: String? = nil,
        input: String,
        instructions: String? = nil,
        text: ResponseTextConfig? = nil,
        conversation_id: String? = nil,
        providerOptions: JSONValue? = nil,
        store: Bool? = nil,
        previous_response_id: String? = nil,
        requestContext: RequestContext? = nil
    ) {
        self.init(
            model: model,
            agent_id: agent_id,
            input: .text(input),
            instructions: instructions,
            text: text,
            conversation_id: conversation_id,
            providerOptions: providerOptions,
            store: store,
            previous_response_id: previous_response_id,
            requestContext: requestContext
        )
    }

    /// JS destructures `requestContext` out of the body. Streaming mode is
    /// set via the Swift API surface rather than a `stream` body field; JS
    /// omits the field from the wire body when starting a stream.
    func body(stream: Bool = false) -> JSONValue {
        var obj: JSONObject = [:]
        if let model { obj["model"] = .string(model) }
        if let agent_id { obj["agent_id"] = .string(agent_id) }
        obj["input"] = input.jsonValue()
        if let instructions { obj["instructions"] = .string(instructions) }
        if let text {
            let data = (try? JSONEncoder().encode(text)) ?? Data()
            if let v = try? JSONDecoder().decode(JSONValue.self, from: data) {
                obj["text"] = v
            }
        }
        if let conversation_id { obj["conversation_id"] = .string(conversation_id) }
        if let providerOptions { obj["providerOptions"] = providerOptions }
        if let store { obj["store"] = .bool(store) }
        if let previous_response_id { obj["previous_response_id"] = .string(previous_response_id) }
        if stream { obj["stream"] = .bool(true) }
        return .object(obj)
    }
}

// MARK: - Streaming events

/// Typed mirror of JS `ResponsesStreamEvent`. The JS union is open-ended; we
/// enumerate the named events and preserve an `.other(type, payload)` escape
/// hatch for forward-compat.
public enum ResponseEvent: Sendable, Hashable {
    case created(response: ResponsesResponse, sequence_number: Int?)
    case inProgress(response: ResponsesResponse, sequence_number: Int?)
    case outputItemAdded(output_index: Int, item: ResponseOutputItem, sequence_number: Int?)
    case contentPartAdded(
        output_index: Int,
        content_index: Int,
        item_id: String,
        part: ResponseOutputText,
        sequence_number: Int?
    )
    case outputTextDelta(
        output_index: Int,
        content_index: Int,
        item_id: String,
        delta: String,
        sequence_number: Int?
    )
    case outputTextDone(
        output_index: Int,
        content_index: Int,
        item_id: String,
        text: String,
        sequence_number: Int?
    )
    case contentPartDone(
        output_index: Int,
        content_index: Int,
        item_id: String,
        part: ResponseOutputText,
        sequence_number: Int?
    )
    case outputItemDone(output_index: Int, item: ResponseOutputItem, sequence_number: Int?)
    case completed(response: ResponsesResponse, sequence_number: Int?)
    /// Unknown or forward-compat event — raw payload is preserved as JSON.
    case other(type: String, payload: JSONValue)

    /// The discriminator value, matching the JS `type` field.
    public var type: String {
        switch self {
        case .created: return "response.created"
        case .inProgress: return "response.in_progress"
        case .outputItemAdded: return "response.output_item.added"
        case .contentPartAdded: return "response.content_part.added"
        case .outputTextDelta: return "response.output_text.delta"
        case .outputTextDone: return "response.output_text.done"
        case .contentPartDone: return "response.content_part.done"
        case .outputItemDone: return "response.output_item.done"
        case .completed: return "response.completed"
        case .other(let t, _): return t
        }
    }

    /// Builds a typed event from decoded JSON. `attachOutputText` mirrors
    /// the JS `hydrateStreamEvent` behavior for response-bearing events.
    static func from(json: JSONValue) -> ResponseEvent? {
        guard case .object(let obj) = json else { return nil }
        let type = obj["type"]?.stringValue ?? ""
        let seq = obj["sequence_number"]?.intValue.map(Int.init)

        func decode<T: Decodable>(_ value: JSONValue, as: T.Type = T.self) -> T? {
            guard let data = try? JSONEncoder().encode(value) else { return nil }
            return try? JSONDecoder().decode(T.self, from: data)
        }

        func decodeResponse(_ key: String) -> ResponsesResponse? {
            guard let raw = obj[key] else { return nil }
            let hydrated = attachOutputText(raw)
            return decode(hydrated)
        }

        switch type {
        case "response.created":
            guard let r = decodeResponse("response") else { return .other(type: type, payload: json) }
            return .created(response: r, sequence_number: seq)
        case "response.in_progress":
            guard let r = decodeResponse("response") else { return .other(type: type, payload: json) }
            return .inProgress(response: r, sequence_number: seq)
        case "response.completed":
            guard let r = decodeResponse("response") else { return .other(type: type, payload: json) }
            return .completed(response: r, sequence_number: seq)
        case "response.output_item.added":
            guard let idx = obj["output_index"]?.intValue.map(Int.init),
                  let itemRaw = obj["item"],
                  let item: ResponseOutputItem = decode(hydrateOutputItem(itemRaw))
            else { return .other(type: type, payload: json) }
            return .outputItemAdded(output_index: idx, item: item, sequence_number: seq)
        case "response.output_item.done":
            guard let idx = obj["output_index"]?.intValue.map(Int.init),
                  let itemRaw = obj["item"],
                  let item: ResponseOutputItem = decode(hydrateOutputItem(itemRaw))
            else { return .other(type: type, payload: json) }
            return .outputItemDone(output_index: idx, item: item, sequence_number: seq)
        case "response.content_part.added":
            guard let oi = obj["output_index"]?.intValue.map(Int.init),
                  let ci = obj["content_index"]?.intValue.map(Int.init),
                  let iid = obj["item_id"]?.stringValue,
                  let partRaw = obj["part"],
                  let part: ResponseOutputText = decode(partRaw)
            else { return .other(type: type, payload: json) }
            return .contentPartAdded(
                output_index: oi,
                content_index: ci,
                item_id: iid,
                part: part,
                sequence_number: seq
            )
        case "response.content_part.done":
            guard let oi = obj["output_index"]?.intValue.map(Int.init),
                  let ci = obj["content_index"]?.intValue.map(Int.init),
                  let iid = obj["item_id"]?.stringValue,
                  let partRaw = obj["part"],
                  let part: ResponseOutputText = decode(partRaw)
            else { return .other(type: type, payload: json) }
            return .contentPartDone(
                output_index: oi,
                content_index: ci,
                item_id: iid,
                part: part,
                sequence_number: seq
            )
        case "response.output_text.delta":
            guard let oi = obj["output_index"]?.intValue.map(Int.init),
                  let ci = obj["content_index"]?.intValue.map(Int.init),
                  let iid = obj["item_id"]?.stringValue,
                  let delta = obj["delta"]?.stringValue
            else { return .other(type: type, payload: json) }
            return .outputTextDelta(
                output_index: oi,
                content_index: ci,
                item_id: iid,
                delta: delta,
                sequence_number: seq
            )
        case "response.output_text.done":
            guard let oi = obj["output_index"]?.intValue.map(Int.init),
                  let ci = obj["content_index"]?.intValue.map(Int.init),
                  let iid = obj["item_id"]?.stringValue,
                  let text = obj["text"]?.stringValue
            else { return .other(type: type, payload: json) }
            return .outputTextDone(
                output_index: oi,
                content_index: ci,
                item_id: iid,
                text: text,
                sequence_number: seq
            )
        default:
            return .other(type: type, payload: json)
        }
    }
}

// MARK: - Hydration helpers (mirror JS `attachOutputText` / `hydrateOutputItem`)

/// Concatenates text across all `message`-typed output items, matching JS
/// `getOutputText`. Non-text items contribute nothing.
func computeOutputText(from output: [JSONValue]) -> String {
    var parts: [String] = []
    for item in output {
        guard item["type"]?.stringValue == "message",
              let content = item["content"]?.arrayValue else { continue }
        for part in content {
            if let text = part["text"]?.stringValue, !text.isEmpty {
                parts.append(text)
            }
        }
    }
    return parts.joined()
}

/// Adds an `output_text` field to a response JSON payload. Mirrors JS
/// `attachOutputText`.
func attachOutputText(_ response: JSONValue) -> JSONValue {
    guard case .object(var obj) = response else { return response }
    let output = obj["output"]?.arrayValue ?? []
    obj["output_text"] = .string(computeOutputText(from: output))
    return .object(obj)
}

/// If `item` is a message without `content`, backfills `content: []`.
/// Mirrors JS `hydrateOutputItem`.
func hydrateOutputItem(_ item: JSONValue) -> JSONValue {
    guard case .object(var obj) = item, obj["type"]?.stringValue == "message" else { return item }
    if obj["content"] == nil || obj["content"] == .some(.null) {
        obj["content"] = .array([])
    }
    return .object(obj)
}
