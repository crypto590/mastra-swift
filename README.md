# mastra-swift

Native Swift SDK for [Mastra](https://mastra.ai). Aims for full feature parity with the official `@mastra/client-js` package, idiomatically adapted for Apple platforms and Linux.

## Status

**Pre-1.0.** Phase 1 (foundation) only. Resource APIs land progressively in Phases 2-5.

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

```swift
import Mastra

let client = MastraClient(
    baseURL: URL(string: "https://your-mastra-instance.example.com")!,
    auth: .bearer { try await tokenProvider.currentToken() }
)
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
