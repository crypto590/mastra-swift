import Foundation
import Mastra

/// Tiny manual-test CLI for `mastra-swift`. Exercises one method per
/// major resource family so you can sanity-check a running server with
/// one command per flow.
@main
struct Main {
    static func main() async {
        let args = Array(CommandLine.arguments.dropFirst())

        guard let command = args.first else {
            printUsage()
            exit(2)
        }

        do {
            let client = try makeClient()
            let rest = Array(args.dropFirst())
            try await dispatch(command: command, args: rest, client: client)
        } catch {
            FileHandle.standardError.write(Data("error: \(error)\n".utf8))
            exit(1)
        }
    }

    // MARK: - Dispatch

    private static func dispatch(
        command: String,
        args: [String],
        client: MastraClient
    ) async throws {
        switch command {
        case "list-agents":
            try await Commands.listAgents(client: client)
        case "run-agent":
            guard let agentId = args.first else { throw CLIError.missingArg("agent-id") }
            let prompt = args.dropFirst().joined(separator: " ")
            try await Commands.runAgent(client: client, agentId: agentId, prompt: prompt)
        case "list-workflows":
            try await Commands.listWorkflows(client: client)
        case "start-workflow":
            guard let workflowId = args.first else { throw CLIError.missingArg("workflow-id") }
            let inputJSON = args.dropFirst().joined(separator: " ")
            try await Commands.startWorkflow(
                client: client,
                workflowId: workflowId,
                inputJSON: inputJSON
            )
        case "list-memory-threads":
            try await Commands.listMemoryThreads(
                client: client,
                resourceId: args.first
            )
        case "vector-query":
            guard args.count >= 2 else { throw CLIError.missingArg("vector-name index-name [dim]") }
            let vectorName = args[0]
            let indexName = args[1]
            let dim = Int(args.count >= 3 ? args[2] : "") ?? 4
            try await Commands.vectorQuery(
                client: client,
                vectorName: vectorName,
                indexName: indexName,
                dimension: dim
            )
        case "responses-create":
            let prompt = args.isEmpty ? "Hello, world!" : args.joined(separator: " ")
            try await Commands.responsesCreate(client: client, prompt: prompt)
        case "mcp-servers":
            try await Commands.mcpServers(client: client)
        case "list-datasets":
            try await Commands.listDatasets(client: client)
        case "help", "-h", "--help":
            printUsage()
        default:
            FileHandle.standardError.write(Data("unknown command: \(command)\n".utf8))
            printUsage()
            exit(2)
        }
    }

    // MARK: - Client

    private static func makeClient() throws -> MastraClient {
        let env = ProcessInfo.processInfo.environment
        let baseURLString = env["MASTRA_BASE_URL"] ?? "http://localhost:4111"
        guard let baseURL = URL(string: baseURLString) else {
            throw CLIError.invalidBaseURL(baseURLString)
        }
        let apiKey = env["MASTRA_API_KEY"] ?? ""
        return try MastraClient(
            baseURL: baseURL,
            auth: apiKey.isEmpty ? .none : .bearer { apiKey }
        )
    }

    // MARK: - Usage

    private static func printUsage() {
        let usage = """
        mastra-play — manual-test CLI for mastra-swift

        Environment:
          MASTRA_BASE_URL   (default: http://localhost:4111)
          MASTRA_API_KEY    (bearer token; empty = no auth)

        Commands:
          list-agents
          run-agent <agent-id> <prompt...>
          list-workflows
          start-workflow <workflow-id> [<json-input>]
          list-memory-threads [<resource-id>]
          vector-query <vector-name> <index-name> [<dim>]
          responses-create [<prompt...>]
          mcp-servers
          list-datasets
          help
        """
        print(usage)
    }
}

enum CLIError: Error, CustomStringConvertible {
    case missingArg(String)
    case invalidBaseURL(String)
    case invalidJSON(String)

    var description: String {
        switch self {
        case .missingArg(let name): return "missing required argument: \(name)"
        case .invalidBaseURL(let s): return "invalid MASTRA_BASE_URL: \(s)"
        case .invalidJSON(let s): return "invalid JSON: \(s)"
        }
    }
}
