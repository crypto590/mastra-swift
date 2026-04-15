# Streaming

How `mastra-swift` decodes the three stream wire formats used by the
Mastra server.

## Overview

Mastra exposes three distinct stream formats. `mastra-swift` ships a
decoder for each; most callers only interact with them indirectly — the
resource methods return an `AsyncThrowingStream` already wired to the
correct decoder.

| Decoder | Used by | Wire format |
|---|---|---|
| ``MastraAgentStreamDecoder`` | ``Agent/stream(_:)``, ``Agent/network(_:)`` | SSE `data:` lines carrying JSON, `[DONE]` sentinel |
| ``SSEDecoder`` | ``Responses/stream(_:)``, ``A2A`` | Standard Server-Sent Events |
| ``RecordSeparatorJSONDecoder`` | ``Run/stream(_:)``, ``Run/resumeStream(_:)`` | RS-delimited (`\x1E`) JSON records |

## Consuming an agent stream

```swift
let agent = client.agent(id: "assistant")
let chunks = try await agent.stream(
    .init(messages: .string("What's the weather in SF?"))
)

for try await chunk in chunks {
    // chunk is a JSONValue; inspect .type, .textDelta, etc.
    print(chunk)
}
```

The stream finishes when the server emits the `[DONE]` sentinel or the
underlying HTTP response closes. Cancelling the enclosing `Task`
propagates cancellation to the underlying transport and closes the
socket.

## Consuming a workflow stream

Workflow runs use record-separator-delimited JSON. The ``Run`` handle
returns a stream of ``JSONValue`` events representing step transitions,
suspend events, and final results.

```swift
let run = try await client.workflow(id: "onboard").createRun()
let events = try await run.stream(
    .init(inputData: .object(["email": .string("user@example.com")]))
)
for try await event in events {
    print(event)
}
```

## Consuming a Responses stream

The Responses API uses standard SSE with typed events (`response.created`,
`response.output_text.delta`, etc.). ``Responses/stream(_:)`` returns a
sequence of typed `ResponseEvent` values.

```swift
let stream = try await client.responses.stream(
    .init(agent_id: "assistant", input: "Hello")
)
for try await event in stream {
    // event is a ResponseEvent (deltas, completions, errors)
}
```

## Cancellation

All three decoders respect Swift's structured concurrency. Wrapping
stream consumption in a `Task` and cancelling it terminates the
underlying `URLSession` data task and closes the stream without leaks.

```swift
let task = Task {
    for try await chunk in try await agent.stream(params) {
        process(chunk)
    }
}

// Later:
task.cancel()
```

## Topics

### Decoders

- ``MastraAgentStreamDecoder``
- ``SSEDecoder``
- ``RecordSeparatorJSONDecoder``

### Streaming methods

- ``Agent/stream(_:)``
- ``Agent/network(_:)``
- ``Run/stream(_:)``
- ``Run/resumeStream(_:)``
- ``Responses/stream(_:)``
