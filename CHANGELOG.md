# Changelog

All notable changes to `mastra-swift` are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-04-15

Initial release. Full feature parity with `@mastra/client-js@1.13.3`
(with `1.13.4-alpha.2` delta reconciliation). 242 tests passing.
Surface tracked in [`parity-manifest.json`](./parity-manifest.json).

### Added

**Phase 1 — Foundation**
- `MastraClient` actor with `Configuration`, `AuthScheme`
  (`.none`, `.bearer`, `.header`, `.custom`), `Interceptor` protocol,
  `RetryPolicy`, `RequestContext`.
- `Transport` protocol + `URLSessionTransport`. `MastraTestingSupport`
  ships `FakeTransport` for deterministic unit tests.
- `HTTPRequest`, `MastraClientError` with parsed JSON body, `MastraLogger`
  protocol + `NoopLogger`.
- `JSONValue` sum type with `Codable`, subscript accessors,
  pretty-printing-friendly encoding.
- Three stream decoders: `MastraAgentStreamDecoder` (SSE + `[DONE]`),
  `SSEDecoder` (standard SSE), `RecordSeparatorJSONDecoder`
  (`\x1E`-delimited JSON).

**Phase 2 — Agents, Workflows, Memory, Vector**
- `Agent` resource: `details`, `generate`, `generateVNext`, `stream`,
  `network`, `approveToolCall`, `declineToolCall`, `enhanceInstructions`,
  `clone`, version CRUD (`listVersions`, `createVersion`, `getVersion`,
  `activateVersion`, `restoreVersion`, `deleteVersion`), voice via
  `AgentVoice`, agent-builder actions via `AgentBuilder`.
- `Workflow` + `Run` resources: `details`, `runs`, `runById`,
  `deleteRunById`, `getSchema`, `createRun`, `start`, `startAsync`,
  `stream`, `observeStream`, `resume`, `resumeAsync`, `resumeStream`,
  `cancel`.
- `MemoryThread` resource with full CRUD + messages
  (`get`, `update`, `delete`, `listMessages`, `deleteMessages`,
  `deleteMessage`, `clone`). `MastraClient` memory helpers:
  `listMemoryThreads`, `memoryConfig`, `createMemoryThread`,
  `listThreadMessages`, `deleteThread`, `saveMessageToMemory`,
  `memoryStatus`, `observationalMemory`, `awaitBufferStatus`,
  `workingMemory`, `updateWorkingMemory`, `searchMemory`.
- `Vector` resource: `details`, `delete`, `getIndexes`, `createIndex`,
  `upsert`, `query` (path-preserved `encodeURIComponent` parity).

**Phase 3 — Responses, Conversations, Tools, Processors, A2A**
- `Responses` resource: `create`, `stream` (typed `ResponseEvent`),
  `retrieve`, `delete`. `CreateResponseParams` with `.text` /
  `.messages` input variants.
- `Conversations` resource with the full JS surface.
- `ToolResource`, `ToolProvider`, `Processor`, `ProcessorProvider`
  resources plus client-level list helpers.
- `A2A` resource (agent-to-agent JSON-RPC over SSE).

**Phase 4 — MCP, Observability, Scorers**
- MCP: `mcpServers`, `mcpServer`, `mcpServerTools`, `mcpServerTool` +
  `MCPTool` handle (`execute`, `resources`, `prompts`, …).
- `Observability` resource and client convenience methods.
- Scorers: `listScorers`, `scorer`, `listScoresByScorerId`,
  `listScoresByRunId`, `listScoresByEntityId`, `saveScore`.
- Logs: `listLogs`, `logForRun`, `listLogTransports`.

**Phase 5 — Workspaces, Providers, Stored, Datasets, Experiments**
- `Workspace` resource and workspace-scoped operations.
- Provider listing: `listAgentsModelProviders`, `listToolProviders`,
  `processorProviders`.
- Stored resources: `StoredAgent`, `StoredPromptBlock`, `StoredScorer`,
  `StoredSkill`, `StoredMCPClient` with list/create/update/delete.
- Datasets: `listDatasets`, `dataset`, `createDataset`, `updateDataset`,
  `deleteDataset`, dataset items (list/CRUD/batch), `generateDatasetItems`,
  `clusterFailures`, item history + versions, dataset versions.
- Experiments: `listExperiments`, `experimentReviewSummary`,
  `listDatasetExperiments`, `datasetExperiment`,
  `listDatasetExperimentResults`, `updateDatasetExperimentResult`,
  `triggerDatasetExperiment`, `updateExperimentResult`,
  `compareExperiments`.

**Phase 6 — Docs, Examples, Polish**
- DocC catalog at `Sources/Mastra/Mastra.docc/` with top-level
  `Mastra.md` and articles: `Configuration`, `Authentication`,
  `Streaming`, `ResourceOverview`.
- `Examples/SwiftUIChat` — SwiftUI app depending on `mastra-swift` by
  relative path; `@Observable` `ChatController` consumes `agent.stream`
  into message bubbles.
- `Examples/CLIPlayground` — `@main` executable (`mastra-play`) with
  subcommands `list-agents`, `run-agent`, `list-workflows`,
  `start-workflow`, `list-memory-threads`, `vector-query`,
  `responses-create`, `mcp-servers`, `list-datasets`. Reads
  `MASTRA_BASE_URL` + `MASTRA_API_KEY` from the environment.
- README extended with Quick Start, Resources table, Examples section,
  DocC pointer.

### Tested

- 242 tests (`swift test`) covering all resource surfaces, the three
  stream decoders, auth / interceptor / retry behaviour, request-context
  encoding, error mapping, and JSON-value round-trips.

### Platform support

- iOS 16+, macOS 13+, tvOS 16+, watchOS 9+, visionOS 1+.
- Linux builds against `URLSession`; streaming on Linux via the bundled
  decoder requires a non-default transport (NIO-based transport is
  reserved for a future release).

[0.1.0]: https://github.com/crypto590/mastra-swift/releases/tag/0.1.0
