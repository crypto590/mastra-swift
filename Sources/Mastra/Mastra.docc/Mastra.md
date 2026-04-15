# ``Mastra``

Native Swift SDK for [Mastra](https://mastra.ai). Full feature parity with
`@mastra/client-js`, idiomatically adapted for Apple platforms and Linux.

## Overview

`Mastra` is a single-entry-point client for the Mastra server HTTP API.
Configure a ``MastraClient`` once, then acquire per-resource handles for
agents, workflows, memory, vector stores, responses, conversations, MCP
servers, A2A, observability, scorers, workspaces, providers, stored
resources, datasets, and experiments.

```swift
import Mastra

let client = try MastraClient(
    baseURL: URL(string: "https://mastra.example.com")!,
    auth: .bearer { try await tokenProvider.currentToken() }
)

let agent = client.agent(id: "assistant")
let stream = try await agent.stream(
    .init(messages: .string("Hello, world!"))
)
for try await chunk in stream {
    print(chunk)
}
```

All resource methods map 1:1 to their JS-client counterparts; paths,
query items, and body shapes are preserved exactly. See
``MastraClient`` and the linked resource types for the complete surface.

## Topics

### Essentials

- <doc:Configuration>
- <doc:Authentication>
- <doc:Streaming>
- <doc:ResourceOverview>

### Client

- ``MastraClient``
- ``Configuration``
- ``AuthScheme``
- ``Interceptor``
- ``RetryPolicy``
- ``Transport``
- ``HTTPRequest``
- ``MastraClientError``
- ``MastraLogger``
- ``RequestContext``
- ``JSONValue``

### Agents

- ``Agent``
- ``AgentBuilder``
- ``AgentVoice``
- ``AgentVersionIdentifier``
- ``GenerateParams``

### Workflows

- ``Workflow``
- ``Run``

### Memory

- ``MemoryThread``

### Vector

- ``Vector``

### Responses

- ``Responses``
- ``CreateResponseParams``

### Conversations

- ``Conversations``

### Tools, Processors, Providers

- ``ToolResource``
- ``ToolProvider``
- ``Processor``
- ``ProcessorProvider``

### Agent-to-Agent & MCP

- ``A2A``
- ``MCPTool``

### Observability & Scorers

- ``Observability``

### Stored Resources

- ``StoredAgent``
- ``StoredPromptBlock``
- ``StoredScorer``
- ``StoredSkill``
- ``StoredMCPClient``

### Workspaces

- ``Workspace``

### Streaming

- ``MastraAgentStreamDecoder``
- ``SSEDecoder``
- ``RecordSeparatorJSONDecoder``
