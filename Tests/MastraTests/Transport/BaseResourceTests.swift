import XCTest
@testable import Mastra
import MastraTestingSupport

final class BaseResourceTests: XCTestCase {
    func testApiPrefixAppliedAndAuthHeaderInjected() async throws {
        let mock = MockTransport(handler: { _ in
            HTTPResponse(status: 200, statusText: "OK", headers: [:], body: Data("{}".utf8))
        })
        let config = Configuration(
            baseURL: URL(string: "https://example.com")!,
            auth: .bearer { "tok-1" },
            transport: mock
        )
        let base = try BaseResource(config)
        let _: JSONValue = try await base.request("/agents")
        XCTAssertEqual(mock.requests.first?.fullPath, "/api/agents")
        XCTAssertEqual(mock.requests.first?.headers["Authorization"], "Bearer tok-1")
    }

    func testFourHundredErrorsDoNotRetry() async throws {
        let counter = AtomicInt()
        let mock = MockTransport(handler: { _ in
            counter.increment()
            return HTTPResponse(status: 404, statusText: "Not Found", headers: [:], body: Data("{\"error\":\"nope\"}".utf8))
        })
        let config = Configuration(baseURL: URL(string: "https://example.com")!, transport: mock)
        let base = try BaseResource(config)
        do {
            let _: JSONValue = try await base.request("/missing")
            XCTFail("expected throw")
        } catch let err as MastraClientError {
            XCTAssertEqual(err.status, 404)
            XCTAssertEqual(counter.value, 1)
        }
    }

    func testFiveHundredRetriesUntilExhaustion() async throws {
        let counter = AtomicInt()
        let mock = MockTransport(handler: { _ in
            counter.increment()
            return HTTPResponse(status: 503, statusText: "Service Unavailable", headers: [:], body: Data())
        })
        let config = Configuration(
            baseURL: URL(string: "https://example.com")!,
            retryPolicy: RetryPolicy(maxRetries: 2, initialBackoff: .milliseconds(1), maxBackoff: .milliseconds(2)),
            transport: mock
        )
        let base = try BaseResource(config)
        do {
            let _: JSONValue = try await base.request("/down")
            XCTFail("expected throw")
        } catch let err as MastraClientError {
            XCTAssertEqual(err.status, 503)
            XCTAssertEqual(counter.value, 3) // initial + 2 retries
        }
    }

    func testCustomHeadersMerge() async throws {
        let mock = MockTransport()
        let config = Configuration(
            baseURL: URL(string: "https://example.com")!,
            headers: ["x-tenant": "acme"],
            transport: mock
        )
        let base = try BaseResource(config)
        _ = try await base.rawRequest("/x", headers: ["x-trace": "abc"])
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.headers["x-tenant"], "acme")
        XCTAssertEqual(req.headers["x-trace"], "abc")
    }
}

final class AtomicInt: @unchecked Sendable {
    private let lock = NSLock()
    private var _value = 0
    var value: Int { lock.lock(); defer { lock.unlock() }; return _value }
    func increment() { lock.lock(); _value += 1; lock.unlock() }
}
