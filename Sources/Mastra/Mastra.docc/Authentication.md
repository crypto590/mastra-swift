# Authentication

Attach credentials to every request via ``AuthScheme``.

## Overview

``AuthScheme`` is a ``Interceptor`` that mutates each outgoing
``HTTPRequest`` just before it is sent. Four variants are provided; pick
the one that matches your server's expectations.

### Bearer token

The most common flow. The async closure is invoked on every request, so
you can refresh short-lived tokens transparently.

```swift
let client = try MastraClient(
    baseURL: url,
    auth: .bearer {
        try await tokenProvider.currentToken()
    }
)
```

### Custom header

Use ``AuthScheme/header(name:value:)`` when your server expects an API
key in a non-`Authorization` header (e.g. `X-API-Key`).

```swift
let client = try MastraClient(
    baseURL: url,
    auth: .header(name: "X-API-Key") {
        ProcessInfo.processInfo.environment["MASTRA_API_KEY"] ?? ""
    }
)
```

### Fully custom

Use ``AuthScheme/custom(_:)`` to sign requests, set cookies, or add
multiple headers atomically.

```swift
let client = try MastraClient(
    baseURL: url,
    auth: .custom { request in
        var r = request
        r.headers["X-Signature"] = try await signer.sign(r)
        r.headers["X-Timestamp"] = String(Int(Date().timeIntervalSince1970))
        return r
    }
)
```

### None

``AuthScheme/none`` is the default and sends requests as-is. Useful for
local development against an unauthenticated server.

## Writing your own interceptor

Any type conforming to ``Interceptor`` can be appended to
``Configuration/interceptors``. Interceptors run in order after the
auth scheme, so they can observe (and mutate) the already-authenticated
request.

```swift
struct TelemetryInterceptor: Interceptor {
    func intercept(_ request: HTTPRequest) async throws -> HTTPRequest {
        var r = request
        r.headers["X-Trace-Id"] = UUID().uuidString
        return r
    }
}
```

## Topics

### Types

- ``AuthScheme``
- ``Interceptor``
- ``HTTPRequest``

### Related

- <doc:Configuration>
