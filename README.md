# mastra-swift

Native Swift SDK for [Mastra](https://mastra.ai). Aims for full feature parity with the official `@mastra/client-js` package, idiomatically adapted for Apple platforms and Linux.

## Status

**0.1.0** — initial release. All resource APIs from `@mastra/client-js@1.13.3` are implemented (239 tests, parity tracked in [`parity-manifest.json`](./parity-manifest.json)). See [`CHANGELOG.md`](./CHANGELOG.md).

## Pinning

This repository tracks the public API of:

- Upstream repo: `mastra-ai/mastra` at git tag `@mastra/client-js@1.13.3` (commit `b5675bc`)
- npm: targeting `@mastra/client-js@1.13.4-alpha.2` for shipped behavior

> The `1.13.4-alpha.2` pre-release was published to npm but is not yet git-tagged in `mastra-ai/mastra`. We pin the source baseline to the most recent git tag (`1.13.3`) and reconcile alpha-only deltas in the parity manifest until upstream cuts a tag.

A generated [`parity-manifest.json`](./parity-manifest.json) maps every public JS method to its Swift equivalent (or to an explicit, documented exception). CI fails the build if a JS method has no Swift counterpart and is not allow-listed.

## Install

Swift Package Manager:

```swift
.package(url: "https://github.com/<org>/mastra-swift.git", from: "0.1.0"),
```

Add the `Mastra` library as a dependency on your target. For unit tests, also link `MastraTestingSupport` which ships a `FakeTransport`.

## Quick start

### Configure the client

```swift
import Mastra

let client = try MastraClient(
    baseURL: URL(string: "https://your-mastra-instance.example.com")!,
    auth: .bearer { try await tokenProvider.currentToken() }
)
```

### Stream an agent response

```swift
let agent = client.agent(id: "assistant")
let chunks = try await agent.stream(
    .init(messages: .array([
        .object([
            "role": .string("user"),
            "content": .string("Hello, world!"),
        ])
    ]))
)

for try await chunk in chunks {
    // chunk is JSONValue — inspect ["type"], ["textDelta"], etc.
    print(chunk)
}
```

### Run a workflow

```swift
let workflow = client.workflow(id: "onboard")
let run = try await workflow.createRun()
let result = try await run.startAsync(
    .init(inputData: .object(["email": .string("user@example.com")]))
)
print(result.status ?? "no status")
```

### Write and read memory

```swift
let thread = try await client.createMemoryThread(.init(
    title: "Session 1",
    metadata: [:],
    resourceId: "user-123"
))

_ = try await client.saveMessageToMemory(.init(
    messages: [
        .object([
            "role": .string("user"),
            "content": .string("Remember: my favorite color is green."),
        ])
    ],
    agentId: "assistant"
))

let messages = try await client.listThreadMessages(
    threadId: thread.id,
    agentId: "assistant"
)
print(messages)
```

## Resources

Every method on `MastraClient` either returns a resource handle or performs a collection-level call. The table below maps each JS resource family to its Swift counterpart.

| JS resource | Swift entry point | Swift type |
|---|---|---|
| `client.getAgent(id)` | `client.agent(id:version:)` | `Agent` |
| `client.getAgentBuilderAction(id)` | `client.agentBuilderAction(id:)` | `AgentBuilder` |
| `client.getWorkflow(id)` | `client.workflow(id:)` | `Workflow`, `Run` |
| `client.getMemoryThread({ threadId })` | `client.memoryThread(threadId:)` | `MemoryThread` |
| `client.getVector(name)` | `client.vector(name:)` | `Vector` |
| `client.responses` | `client.responses` | `Responses` |
| `client.conversations` | `client.conversations` | `Conversations` |
| `client.getTool(id)` | `client.tool(id:)` | `ToolResource` |
| `client.getToolProvider(id)` | `client.toolProvider(id:)` | `ToolProvider` |
| `client.getProcessor(id)` | `client.processor(id:)` | `Processor` |
| `client.getProcessorProvider(id)` | `client.processorProvider(id:)` | `ProcessorProvider` |
| `client.getA2A(agentId)` | `client.a2a(agentId:)` | `A2A` |
| `client.getMcpServerTool(serverId, toolId)` | `client.mcpServerTool(serverId:toolId:)` | `MCPTool` |
| `client.observability` | `client.observability` | `Observability` |
| `client.getWorkspace(id)` | `client.workspace(id:)` | `Workspace` |
| `client.getStoredAgent(id)` | `client.storedAgent(id:)` | `StoredAgent` |
| `client.getStoredPromptBlock(id)` | `client.storedPromptBlock(id:)` | `StoredPromptBlock` |
| `client.getStoredScorer(id)` | `client.storedScorer(id:)` | `StoredScorer` |
| `client.getStoredSkill(id)` | `client.storedSkill(id:)` | `StoredSkill` |
| `client.getStoredMCPClient(id)` | `client.storedMCPClient(id:)` | `StoredMCPClient` |
| `client.getDataset(id)` | `client.dataset(_:)` | — |
| `client.listExperiments()` | `client.listExperiments(_:)` | — |

The full machine-readable mapping is in [`parity-manifest.json`](./parity-manifest.json).

## Documentation

Full API reference is published as a DocC catalog in `Sources/Mastra/Mastra.docc/`. Landing page and articles:

- `Mastra.md` — top-level overview and topic index
- `Configuration.md` — client construction, transport, request context
- `Authentication.md` — bearer / header / custom auth schemes
- `Streaming.md` — the three stream wire formats and how to consume them
- `ResourceOverview.md` — full JS → Swift resource map

Generate docs locally with:

```sh
swift package --allow-writing-to-directory ./docs \
    generate-documentation --target Mastra \
    --output-path ./docs
```

## Examples

Two runnable example packages live under [`Examples/`](./Examples). Each declares its own `Package.swift` pointing at this repo via a relative path, so they are not pulled in as transitive dependencies of the library.

- [`Examples/SwiftUIChat`](./Examples/SwiftUIChat) — SwiftUI chat app using an `@Observable` controller that consumes `agent.stream(...)` into message bubbles.
- [`Examples/CLIPlayground`](./Examples/CLIPlayground) — `@main` executable exercising one method per major resource family (`list-agents`, `run-agent`, `list-workflows`, `start-workflow`, `list-memory-threads`, `vector-query`, `responses-create`, `mcp-servers`, `list-datasets`). Reads `MASTRA_BASE_URL` and `MASTRA_API_KEY` from the environment and prints responses as JSON.

```sh
cd Examples/CLIPlayground
MASTRA_BASE_URL=http://localhost:4111 swift run mastra-play list-agents
```

## Platforms

- iOS 16+, macOS 13+, tvOS 16+, watchOS 9+, visionOS 1+
- Linux (Swift 5.10+; streaming requires the optional NIO transport — coming in a later phase)

## Streaming

Mastra exposes three distinct stream wire formats. `mastra-swift` ships a decoder for each:

| Decoder | Used by | Wire format |
|---|---|---|
| `MastraAgentStreamDecoder` | Agent `stream`, `network` | SSE `data:` lines carrying JSON, `[DONE]` sentinel |
| `SSEDecoder` | Responses, A2A | Standard Server-Sent Events |
| `RecordSeparatorJSONDecoder` | Workflow runs | RS-delimited (`\x1E`) JSON records |

## Error model

```swift
do { ... }
catch let error as MastraClientError {
    error.status      // HTTP status code
    error.statusText  // HTTP status text
    error.body        // Parsed JSON body (JSONValue) if available
}
```

## License

Apache-2.0. See [LICENSE](./LICENSE).
