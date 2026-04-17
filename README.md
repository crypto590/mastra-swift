# mastra-swift

> Native Swift SDK for [Mastra](https://mastra.ai) — build agents, workflows, memory, RAG, and evals on Apple platforms and Linux.

[![Swift 5.10+](https://img.shields.io/badge/swift-5.10%2B-F05138?logo=swift&logoColor=white)](https://swift.org)
[![Platforms](https://img.shields.io/badge/platforms-iOS%2016%20%7C%20macOS%2013%20%7C%20tvOS%2016%20%7C%20watchOS%209%20%7C%20visionOS%201%20%7C%20Linux-blue)](#platforms)
[![SPM](https://img.shields.io/badge/SwiftPM-compatible-success)](#install)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](./LICENSE)
[![Tests](https://img.shields.io/badge/tests-242%20passing-success)](#status)
[![Parity](https://img.shields.io/badge/parity-%40mastra%2Fclient--js%401.13.3-informational)](./parity-manifest.json)

A first-class Swift port of [`@mastra/client-js`](https://www.npmjs.com/package/@mastra/client-js). Every public method in the JS client maps to a Swift equivalent — or to an explicit, documented exception — tracked in a [machine-readable parity manifest](./parity-manifest.json) that CI enforces.

---

## Why mastra-swift?

- **Feature parity, not feature parity *eventually***. All 12 resource families from the upstream client — agents, workflows, memory, vector, responses, conversations, MCP, A2A, observability, scorers, workspaces, datasets — ship in v0.1.
- **Three streaming formats done right**: agent MDS (`data:` + `[DONE]`), SSE (Responses, A2A), and record-separator JSON (`\x1E`, workflow runs) each get a dedicated decoder returning `AsyncThrowingStream`.
- **Idiomatic Swift**: `MastraClient` is an `actor`; resources are `Sendable` structs; all errors are `MastraClientError`; cancellation is `Task`-based.
- **Pluggable auth**: `.bearer { … }`, `.header(name:value:)`, `.custom { … }`, or `.none`. Bring your own token refresh, no retry-on-401 wiring required.
- **Testable by default**: ships `MastraTestingSupport` with a `MockTransport` for deterministic unit tests — no network required.
- **Client-side tools**: `generate(..., clientTools: […])` runs the full server ↔ client tool-call loop natively, including JSON-Schema pass-through.

## Install

Add to `Package.swift`:

```swift
.package(url: "https://github.com/crypto590/mastra-swift.git", from: "0.1.0"),
```

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "Mastra", package: "mastra-swift"),
    ]
),
```

For unit tests, also link `MastraTestingSupport`.

## Quick start

```swift
import Mastra

let client = try MastraClient(
    baseURL: URL(string: "https://your-mastra-instance.example.com")!,
    auth: .bearer { try await tokenProvider.currentToken() }
)
```

### Stream an agent

```swift
let agent = client.agent(id: "assistant")

for try await chunk in try await agent.stream(.init(
    messages: .array([
        .object([
            "role": .string("user"),
            "content": .string("Summarize today's standup notes."),
        ])
    ])
)) {
    print(chunk) // JSONValue — inspect ["type"], ["textDelta"], etc.
}
```

### Run a workflow

```swift
let workflow = client.workflow(id: "onboard")
let run = try await workflow.createRun()
let result = try await run.startAsync(.init(
    inputData: .object(["email": .string("user@example.com")])
))
print(result.status ?? "no status")
```

### Persist memory

```swift
let thread = try await client.createMemoryThread(.init(
    title: "Session 1",
    metadata: [:],
    resourceId: "user-123"
))

_ = try await client.saveMessageToMemory(.init(
    messages: [.object([
        "role": .string("user"),
        "content": .string("Remember: my favorite color is green."),
    ])],
    agentId: "assistant"
))
```

### Query a vector index

```swift
let vector = client.vector(name: "kb")
let hits = try await vector.query(.init(
    indexName: "articles",
    queryVector: embedding,
    topK: 5
))
```

More recipes in the [DocC catalog](./Sources/Mastra/Mastra.docc) and the [CLI playground](./Examples/CLIPlayground).

## Resource coverage

| Resource family | Swift entry point | Notes |
|---|---|---|
| Agents | `client.agent(id:)` | generate, stream (MDS), network, version CRUD, client-side tool loop, model ops |
| Voice | `agent.voice` | speak, listen, speakers, listener |
| Agent builder | `client.agentBuilder()` | action runs, streams (RS-JSON) |
| Workflows | `client.workflow(id:)` | details, runs, schema; `Run` handles all 3 streaming variants |
| Memory | `client.createMemoryThread(…)` | threads, working memory, search, observational, buffer status |
| Vector | `client.vector(name:)` | indexes, upsert, query; plus `listVectors` / `listEmbedders` |
| Responses | `client.responses` | create / stream / retrieve / delete, typed `ResponseEvent` enum |
| Conversations | `client.conversations` | create / retrieve / delete + `items.list` |
| Tool / Processor (server) | `client.tool(id:)` / `client.processor(id:)` | details, execute |
| Tool / Processor providers | `client.toolProvider(id:)` | toolkits, tool schemas |
| MCP | `client.mcpServer(id:)` / `client.mcpServerTool(…)` | servers, tools, execute |
| A2A | `client.a2a(agentId:)` | JSON-RPC envelope, SSE `sendStreamingMessage` |
| Observability | `client.observability` | 29 methods: traces, scores, feedback, metrics, discovery |
| Scorers & scores | `client.listScorers()` / `client.saveScore(…)` | scores by scorer/run/entity |
| Logs | `client.listLogs(…)` | filters, transports, per-run logs |
| Workspaces | `client.workspace(id:)` | info, fs, search, index, skills, skill references |
| Stored resources | `client.storedAgent(id:)` + 4 more | full version CRUD/activate/restore/compare |
| Datasets & experiments | `client.dataset(…)` / `client.compareExperiments(…)` | items, batch ops, versions, trigger, review summary |
| System | `client.systemPackages()` | installed packages |

The complete JS-to-Swift mapping lives in [`parity-manifest.json`](./parity-manifest.json). CI fails if a JS method lacks a Swift mapping and isn't allow-listed as an exception.

## Streaming

Mastra exposes three distinct wire formats. `mastra-swift` ships a decoder for each and returns `AsyncThrowingStream` in every case:

| Decoder | Used by | Wire format |
|---|---|---|
| `MastraAgentStreamDecoder` | Agent `stream`, `network` | SSE `data:` lines carrying JSON + `[DONE]` sentinel |
| `SSEDecoder` | Responses, A2A | Standard Server-Sent Events |
| `RecordSeparatorJSONDecoder` | Workflow runs (all variants) | RS-delimited (`\x1E`) JSON records |

## Error handling

```swift
do {
    _ = try await client.agent(id: "does-not-exist").details()
} catch let error as MastraClientError {
    error.status      // HTTP status code
    error.statusText  // HTTP status text
    error.body        // Parsed JSONValue? body
    error.rawBody     // Raw string body
}
```

Retries follow the upstream JS semantics exactly: exponential backoff with a 1s cap, no retries on 4xx, configurable via `RetryPolicy`.

## Testing

```swift
import XCTest
import Mastra
import MastraTestingSupport

final class MyServiceTests: XCTestCase {
    func testItCallsListAgents() async throws {
        let mock = MockTransport { _ in
            HTTPResponse(status: 200, statusText: "OK", headers: [:], body: Data("{}".utf8))
        }
        let client = try MastraClient(configuration: .init(
            baseURL: URL(string: "https://example.com")!,
            transport: mock
        ))
        _ = try await client.listAgents()
        XCTAssertEqual(mock.requests.first?.fullPath, "/api/agents")
    }
}
```

## Platforms

- iOS 16+, macOS 13+, tvOS 16+, watchOS 9+, visionOS 1+
- Linux (Swift 5.10+; streaming via an optional NIO transport lands in a later release)

## Examples

Three runnable samples under [`Examples/`](./Examples), each with its own build graph (not pulled in as transitive deps):

- **[`iOSShowcase`](./Examples/iOSShowcase)** — iOS 26 chat app template. Xcode project, streaming via `agent.stream(...)`, persistent memory threads via `createMemoryThread` + `listThreadMessages`, SwiftUI Previews. Point it at any Mastra server and run on the Simulator.
- **[`SwiftUIChat`](./Examples/SwiftUIChat)** — SwiftPM-only SwiftUI chat, minimal. Good as a link-check target and for macOS.
- **[`CLIPlayground`](./Examples/CLIPlayground)** — `@main` executable exercising one method per major resource family.

```sh
cd Examples/CLIPlayground
MASTRA_BASE_URL=http://localhost:4111 swift run mastra-play list-agents
MASTRA_BASE_URL=http://localhost:4111 swift run mastra-play list-workflows
MASTRA_BASE_URL=http://localhost:4111 swift run mastra-play tool-execute get-weather '{"location":"Chicago"}'
```

## Documentation

Generate the DocC catalog locally:

```sh
swift package --allow-writing-to-directory ./docs \
    generate-documentation --target Mastra \
    --output-path ./docs
```

Articles: `Mastra.md`, `Configuration.md`, `Authentication.md`, `Streaming.md`, `ResourceOverview.md`.

## Pinning

This release tracks:

- Upstream repo: `mastra-ai/mastra` at git tag `@mastra/client-js@1.13.3` (commit [`b5675bc`](https://github.com/mastra-ai/mastra/tree/b5675bcc6b9763925d908e050aa1dcd0cdc3cc00))
- npm: targeting `@mastra/client-js@1.13.4-alpha.2` for shipped behavior

> `1.13.4-alpha.2` is an npm-only pre-release and is not yet git-tagged upstream. We pin the source baseline to `1.13.3` and reconcile alpha-only deltas in [`parity-manifest.json`](./parity-manifest.json) until upstream cuts a tag.

## Contributing

- Every upstream JS method must have a Swift mapping in `parity-manifest.json` or an explicit exception.
- Resources are `public struct`s; `MastraClient` is the only `actor`. All public types are `Sendable`.
- Tests must accompany every new resource. Use `MockTransport` from `MastraTestingSupport`.
- Run `swift build && swift test && node Scripts/check-parity.mjs` before opening a PR.

See [`CONTRIBUTING.md`](./CONTRIBUTING.md) for the full checklist.

## Status

**v0.1.0** — all resource APIs from `@mastra/client-js@1.13.3` are implemented. 242 tests passing. The shipped CLI playground has also been smoke-tested against a live Mastra server for agent listing, workflow listing, and direct tool execution. Expect minor API tweaks in 0.x. See [`CHANGELOG.md`](./CHANGELOG.md).

## License

Apache-2.0. See [`LICENSE`](./LICENSE).

## Acknowledgments

Built against the excellent Mastra framework by the [mastra-ai](https://github.com/mastra-ai/mastra) team. This SDK is community-maintained and not officially affiliated with Mastra.
