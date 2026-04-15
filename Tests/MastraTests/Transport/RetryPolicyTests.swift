import XCTest
@testable import Mastra

final class RetryPolicyTests: XCTestCase {
    func testDoesNotRetry4xx() {
        let err = MastraClientError(status: 404, statusText: "Not Found", message: "")
        XCTAssertFalse(RetryPolicy.shouldRetry(error: err))
    }

    func testRetries5xx() {
        let err = MastraClientError(status: 503, statusText: "Service Unavailable", message: "")
        XCTAssertTrue(RetryPolicy.shouldRetry(error: err))
    }

    func testRetriesNonHTTPErrors() {
        struct Boom: Error {}
        XCTAssertTrue(RetryPolicy.shouldRetry(error: Boom()))
    }

    func testBackoffCapsAtMax() {
        let policy = RetryPolicy(
            maxRetries: 5,
            initialBackoff: .milliseconds(100),
            maxBackoff: .milliseconds(1000)
        )
        XCTAssertLessThanOrEqual(policy.backoff(forAttempt: 10), .milliseconds(1000))
    }
}
