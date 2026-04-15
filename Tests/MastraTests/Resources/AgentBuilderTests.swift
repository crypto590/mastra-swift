import XCTest
@testable import Mastra
import MastraTestingSupport

final class AgentBuilderTests: XCTestCase {
    private func makeClient(
        handler: @escaping MockTransport.Handler = { _ in
            HTTPResponse(status: 200, statusText: "OK", headers: [:], body: Data("{}".utf8))
        }
    ) throws -> (MastraClient, MockTransport) {
        let mock = MockTransport(handler: handler)
        let config = Configuration(
            baseURL: URL(string: "https://example.com")!,
            transport: mock
        )
        let client = try MastraClient(configuration: config)
        return (client, mock)
    }

    func testCreateRunPostsExpectedPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            HTTPResponse(
                status: 200, statusText: "OK", headers: [:],
                body: Data(#"{"runId":"r-1"}"#.utf8)
            )
        })
        let builder = client.agentBuilderAction(id: "act-1")
        let out = try await builder.createRun()
        XCTAssertEqual(out.runId, "r-1")
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/agent-builder/act-1/create-run")
    }

    func testCreateRunWithRunIdAddsQuery() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            HTTPResponse(
                status: 200, statusText: "OK", headers: [:],
                body: Data(#"{"runId":"r-2"}"#.utf8)
            )
        })
        let builder = client.agentBuilderAction(id: "act-1")
        _ = try await builder.createRun(runId: "r-2")
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertTrue(req.query.contains(.init(name: "runId", value: "r-2")))
    }

    func testStartAsyncPostsBody() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            HTTPResponse(
                status: 200, statusText: "OK", headers: [:],
                body: Data(#"{"status":"success","result":{"success":true,"applied":true,"message":"ok"}}"#.utf8)
            )
        })
        let builder = client.agentBuilderAction(id: "act-2")
        _ = try await builder.startAsync(
            AgentBuilder.ActionRequest(inputData: .object(["foo": .string("bar")]))
        )
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/agent-builder/act-2/start-async")
        guard case .json(let body) = req.body else {
            return XCTFail("expected JSON body")
        }
        XCTAssertEqual(body["inputData"]?["foo"]?.stringValue, "bar")
    }

    func testCancelRunPostsPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            HTTPResponse(
                status: 200, statusText: "OK", headers: [:],
                body: Data(#"{"message":"cancelled"}"#.utf8)
            )
        })
        let builder = client.agentBuilderAction(id: "act-3")
        let out = try await builder.cancelRun("run-x")
        XCTAssertEqual(out.message, "cancelled")
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.fullPath, "/api/agent-builder/act-3/runs/run-x/cancel")
    }

    func testDetailsUsesGet() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            HTTPResponse(
                status: 200, statusText: "OK", headers: [:],
                body: Data(#"{"name":"builder"}"#.utf8)
            )
        })
        let builder = client.agentBuilderAction(id: "act-4")
        _ = try await builder.details()
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/agent-builder/act-4")
    }
}
