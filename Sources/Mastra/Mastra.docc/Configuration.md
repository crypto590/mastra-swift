# Configuration

How to construct a ``MastraClient`` and tune its transport, headers,
retry policy, logging, and request context.

## Overview

``MastraClient`` is built from a ``Configuration`` value. You can either
construct the configuration explicitly or use the convenience initializer
on ``MastraClient`` that accepts the most common options inline.

```swift
import Mastra

let config = Configuration(
    baseURL: URL(string: "https://mastra.example.com")!,
    apiPrefix: "/api",
    retryPolicy: .default,
    headers: ["X-Tenant": "acme"],
    auth: .bearer { try await tokens.currentToken() }
)
let client = try MastraClient(configuration: config)
```

## API prefix

The Mastra server mounts its HTTP routes under a configurable prefix.
The default is `/api`, matching the JS client. Set
``Configuration/apiPrefix`` if your deployment uses a different mount.

```swift
let client = try MastraClient(
    baseURL: URL(string: "https://mastra.example.com")!,
    apiPrefix: "/v1/mastra"
)
```

## Custom transport

Tests and Linux hosts can swap the default `URLSession` transport for
any type conforming to ``Transport``. The `MastraTestingSupport` module
ships a `FakeTransport` for unit testing without network I/O.

```swift
import MastraTestingSupport

let transport = FakeTransport(responses: [
    .json(["ok": true])
])
let client = try MastraClient(
    baseURL: URL(string: "https://example.com")!,
    transport: transport
)
```

## Request context

Many resource methods accept a ``RequestContext`` that is base64-encoded
into the `requestContext` query parameter, matching the JS client. You
can also set a default context on ``Configuration/requestContext`` that
is applied to every call.

```swift
let ctx = RequestContext(entries: ["tenantId": .string("acme")])
let client = try MastraClient(configuration: Configuration(
    baseURL: url,
    requestContext: ctx
))
```

## Topics

### Types

- ``Configuration``
- ``MastraClient``
- ``Transport``
- ``RequestContext``
- ``RetryPolicy``

### Related

- <doc:Authentication>
- <doc:ResourceOverview>
