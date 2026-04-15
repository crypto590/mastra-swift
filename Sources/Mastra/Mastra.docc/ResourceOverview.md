# Resource Overview

Map from the JS `@mastra/client-js` resource families to their Swift
counterparts. A machine-readable version lives in
`parity-manifest.json` at the repo root.

## Overview

Every method on ``MastraClient`` either returns a resource handle
(`.agent(id:)`, `.workflow(id:)`, `.memoryThread(threadId:)`, …) or
performs a collection-level operation (`.listAgents()`,
`.listWorkflows()`, …). Resource handles are cheap `Sendable` structs
holding the client's ``BaseResource`` plus any path parameters — no
network calls happen until you invoke a method.

## Resource map

| JS client family | Swift entry points | Key types |
|---|---|---|
| Agents | ``MastraClient/agent(id:version:)``, ``MastraClient/listAgents(requestContext:partial:)`` | ``Agent``, ``AgentBuilder``, ``AgentVoice`` |
| Workflows | ``MastraClient/workflow(id:)``, ``MastraClient/listWorkflows(requestContext:partial:)`` | ``Workflow``, ``Run`` |
| Memory | ``MastraClient/memoryThread(threadId:agentId:)``, ``MastraClient/listMemoryThreads(_:)`` | ``MemoryThread`` |
| Vector | ``MastraClient/vector(name:)`` | ``Vector`` |
| Responses | ``MastraClient/responses`` | ``Responses``, ``CreateResponseParams`` |
| Conversations | ``MastraClient/conversations`` | ``Conversations`` |
| Tools | ``MastraClient/tool(id:)`` | ``ToolResource`` |
| Tool providers | ``MastraClient/toolProvider(id:)``, ``MastraClient/listToolProviders()`` | ``ToolProvider`` |
| Processors | ``MastraClient/processor(id:)``, ``MastraClient/listProcessors(_:)`` | ``Processor``, ``ProcessorProvider`` |
| A2A | ``MastraClient/a2a(agentId:)`` | ``A2A`` |
| MCP | ``MastraClient/mcpServer(id:)``, ``MastraClient/mcpServerTool(serverId:toolId:)`` | ``MCPTool`` |
| Observability | ``MastraClient/observability`` | ``Observability`` |
| Scorers | ``MastraClient/scorer(id:)``, ``MastraClient/listScorers(_:)`` | |
| Workspaces | ``MastraClient/workspace(id:)`` | ``Workspace`` |
| Stored agents | ``MastraClient/storedAgent(id:)``, ``MastraClient/listStoredAgents(_:)`` | ``StoredAgent`` |
| Stored prompts | ``MastraClient/storedPromptBlock(id:)`` | ``StoredPromptBlock`` |
| Stored scorers | ``MastraClient/storedScorer(id:)`` | ``StoredScorer`` |
| Stored skills | ``MastraClient/storedSkill(id:)`` | ``StoredSkill`` |
| Stored MCP clients | ``MastraClient/storedMCPClient(id:)`` | ``StoredMCPClient`` |
| Datasets | ``MastraClient/dataset(_:)``, ``MastraClient/listDatasets(_:)`` | |
| Experiments | ``MastraClient/listExperiments(_:)`` | |
| Logs | ``MastraClient/listLogs(_:)``, ``MastraClient/logForRun(_:)`` | |

## Request / response shape

All types are fully `Sendable`. Response models are `Codable` structs
with the same field names and nesting as the JS types (snake_case
preserved where the JS wire shape is snake_case). Request params accept
a ``JSONValue`` in the slots where the JS API is open-ended — this
keeps the Swift surface honest about the server's actual contract.

## Parity manifest

See `parity-manifest.json` at the repo root for the full machine-readable
map from each JS method to its Swift equivalent (or to an explicit,
documented exception). CI fails the build if any JS method has no Swift
counterpart and is not allow-listed.

## Topics

### Related

- <doc:Configuration>
- <doc:Streaming>
