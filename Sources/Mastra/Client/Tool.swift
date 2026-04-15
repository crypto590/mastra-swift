import Foundation

/// Client-side tool, equivalent of JS `ClientTool` from `client-js/src/tools.ts`.
///
/// The server receives a serialized description of each tool (`id`, `description`,
/// `inputSchema`, `outputSchema`) and asks the client to execute them when the
/// model calls one of them. The `execute` closure implements that execution
/// locally; its result is fed back into a recursive `generate`/`stream` call.
public struct ClientTool: Sendable {
    public let id: String
    public let description: String
    /// JSON-Schema for the tool input (matches JS `inputSchema` after
    /// `zodToJsonSchema`). Use `JSONValue` because schemas are open-typed.
    public let inputSchema: JSONValue?
    /// JSON-Schema for the tool output.
    public let outputSchema: JSONValue?
    /// Executes the tool with model-provided arguments. The returned value is
    /// serialized and sent back to the server as the tool result.
    public let execute: @Sendable (JSONValue) async throws -> JSONValue

    public init(
        id: String,
        description: String,
        inputSchema: JSONValue? = nil,
        outputSchema: JSONValue? = nil,
        execute: @escaping @Sendable (JSONValue) async throws -> JSONValue
    ) {
        self.id = id
        self.description = description
        self.inputSchema = inputSchema
        self.outputSchema = outputSchema
        self.execute = execute
    }

    /// Server wire-format for a single tool. Mirrors the JS `processClientTools`
    /// output: `{ id, description, inputSchema, outputSchema }` where the
    /// schemas are already JSON-Schema objects (the client does not run Zod).
    func wireDescription() -> JSONValue {
        var out: JSONObject = [
            "id": .string(id),
            "description": .string(description),
        ]
        if let inputSchema { out["inputSchema"] = inputSchema }
        if let outputSchema { out["outputSchema"] = outputSchema }
        return .object(out)
    }
}

extension Array where Element == ClientTool {
    /// Produces the `clientTools` map (keyed by tool id) the server expects.
    /// Mirrors JS `processClientTools` which returns `Record<string, Tool>`.
    func wireMap() -> JSONValue {
        var map: JSONObject = [:]
        for tool in self { map[tool.id] = tool.wireDescription() }
        return .object(map)
    }
}
