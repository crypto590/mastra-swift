# Contributing

Thanks for your interest in contributing to `mastra-swift`.

## Development

```bash
swift build
swift test
```

## Parity rules

Every method in the upstream `@mastra/client-js` public surface must either:

1. Have a matching Swift implementation listed in `parity-manifest.json`, or
2. Be explicitly listed under `exceptions` with a justification (browser-only API, runtime-incompatible behavior, etc.)

The parity test in `Tests/MastraTests/Parity/` reads the manifest and verifies coverage. A PR that adds a new resource method to the JS side must also update the manifest in this repo before it can merge.

## Style

- Match upstream JS naming where ergonomic; rename when Swift idioms demand it (document in the manifest).
- Resources are value types (`struct`); `MastraClient` is the only `actor`.
- Async streaming returns `AsyncThrowingStream<Chunk, Error>`.
- All public types are `Sendable`.

## Commits

Conventional commits preferred (`feat:`, `fix:`, `docs:`, `chore:`).
