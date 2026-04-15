import Foundation
import Mastra

enum Commands {
    // MARK: - Agents

    static func listAgents(client: MastraClient) async throws {
        let agents = try await client.listAgents()
        JSONPrinter.print(Array(agents.keys).sorted())
    }

    static func runAgent(
        client: MastraClient,
        agentId: String,
        prompt: String
    ) async throws {
        let agent = client.agent(id: agentId)
        let text = prompt.isEmpty ? "Hello!" : prompt
        let params = GenerateParams(
            messages: .array([
                .object([
                    "role": .string("user"),
                    "content": .string(text),
                ])
            ])
        )
        let stream = try await agent.stream(params)
        for try await chunk in stream {
            if let line = Self.line(from: chunk) {
                print(line)
            }
        }
    }

    // MARK: - Workflows

    static func listWorkflows(client: MastraClient) async throws {
        let workflows = try await client.listWorkflows()
        JSONPrinter.print(Array(workflows.keys).sorted())
    }

    static func startWorkflow(
        client: MastraClient,
        workflowId: String,
        inputJSON: String
    ) async throws {
        let input: JSONValue = try parseJSONOrEmpty(inputJSON)
        let workflow = client.workflow(id: workflowId)
        let run = try await workflow.createRun()
        let result = try await run.startAsync(.init(inputData: input))
        JSONPrinter.print(result.raw)
    }

    // MARK: - Memory

    static func listMemoryThreads(
        client: MastraClient,
        resourceId: String?
    ) async throws {
        let params = ListMemoryThreadsParams(resourceId: resourceId)
        let threads = try await client.listMemoryThreads(params)
        JSONPrinter.print(threads)
    }

    // MARK: - Vector

    static func vectorQuery(
        client: MastraClient,
        vectorName: String,
        indexName: String,
        dimension: Int
    ) async throws {
        let vector = client.vector(name: vectorName)
        let queryVector = Array(repeating: 0.0, count: dimension)
        let response = try await vector.query(
            .init(indexName: indexName, queryVector: queryVector, topK: 5)
        )
        JSONPrinter.print(response)
    }

    // MARK: - Responses

    static func responsesCreate(
        client: MastraClient,
        prompt: String
    ) async throws {
        let response = try await client.responses.create(
            .init(input: prompt)
        )
        JSONPrinter.print(response)
    }

    // MARK: - MCP

    static func mcpServers(client: MastraClient) async throws {
        let response = try await client.mcpServers()
        JSONPrinter.print(response)
    }

    // MARK: - Datasets

    static func listDatasets(client: MastraClient) async throws {
        let response = try await client.listDatasets()
        JSONPrinter.print(response)
    }

    // MARK: - Helpers

    private static func parseJSONOrEmpty(_ s: String) throws -> JSONValue {
        let trimmed = s.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return .object([:]) }
        guard let data = trimmed.data(using: .utf8) else {
            throw CLIError.invalidJSON(s)
        }
        do {
            return try JSONDecoder().decode(JSONValue.self, from: data)
        } catch {
            throw CLIError.invalidJSON(s)
        }
    }

    /// Extract a human-readable line from a Mastra Data Stream chunk.
    private static func line(from chunk: JSONValue) -> String? {
        if let type = chunk["type"]?.stringValue {
            switch type {
            case "text-delta":
                return chunk["textDelta"]?.stringValue
                    ?? chunk["payload"]?["text"]?.stringValue
            case "text":
                return chunk["text"]?.stringValue
            default:
                return "[\(type)]"
            }
        }
        return nil
    }
}
