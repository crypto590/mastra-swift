import XCTest
@testable import Mastra
import MastraTestingSupport

final class A2ATests: XCTestCase {
    // MARK: - Helpers

    private func makeClient(
        handler: @escaping MockTransport.Handler = { _ in
            HTTPResponse(status: 200, statusText: "OK", headers: [:], body: Data("{}".utf8))
        },
        streamingHandler: @escaping MockTransport.StreamingHandler = { _ in
            HTTPStreamingResponse(
                status: 200, statusText: "OK", headers: [:],
                bytes: AsyncThrowingStream { $0.finish() }
            )
        }
    ) throws -> (MastraClient, MockTransport) {
        let mock = MockTransport(handler: handler, streamingHandler: streamingHandler)
        let config = Configuration(
            baseURL: URL(string: "https://example.com")!,
            transport: mock
        )
        let client = try MastraClient(configuration: config)
        return (client, mock)
    }

    private func jsonResponse(_ object: Any) -> HTTPResponse {
        let data = try! JSONSerialization.data(withJSONObject: object, options: [])
        return HTTPResponse(status: 200, statusText: "OK", headers: [:], body: data)
    }

    private func decodeBody(_ request: HTTPRequest) -> JSONValue? {
        guard case .json(let value) = request.body else { return nil }
        return value
    }

    private func sampleParams() -> MessageSendParams {
        MessageSendParams(
            message: A2AMessage(
                messageId: "msg-1",
                role: "user",
                parts: [.text(text: "Hello")]
            )
        )
    }

    // MARK: - getCard

    func testGetCardGetsWellKnownPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "name": "Support Agent",
                "description": "Handles customer tickets",
                "url": "https://example.com/a2a/support",
                "version": "1.0.0",
                "provider": ["organization": "Example Inc.", "url": "https://example.com"],
                "defaultInputModes": ["text"],
                "defaultOutputModes": ["text"],
                "skills": [
                    [
                        "id": "triage",
                        "name": "Triage",
                        "description": "Classify tickets",
                        "tags": ["support"],
                    ]
                ],
            ])
        })

        let a2a = client.a2a(agentId: "support-agent")
        let card = try await a2a.getCard()

        XCTAssertEqual(card.name, "Support Agent")
        XCTAssertEqual(card.provider?.organization, "Example Inc.")
        XCTAssertEqual(card.skills?.first?.id, "triage")

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/.well-known/support-agent/agent-card.json")
    }

    // MARK: - sendMessage

    func testSendMessagePostsJSONRPCEnvelope() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "jsonrpc": "2.0",
                "id": "req-1",
                "result": [
                    "id": "task-1",
                    "kind": "task",
                    "status": ["state": "completed"],
                ],
            ])
        })

        let a2a = client.a2a(agentId: "test-agent")
        let response = try await a2a.sendMessage(sampleParams())

        XCTAssertEqual(response.jsonrpc, "2.0")
        XCTAssertEqual(response.result?["id"]?.stringValue, "task-1")

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/a2a/test-agent")

        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["jsonrpc"]?.stringValue, "2.0")
        XCTAssertEqual(body["method"]?.stringValue, "message/send")
        // id is a generated UUID string.
        XCTAssertNotNil(body["id"]?.stringValue)
        XCTAssertFalse(body["id"]!.stringValue!.isEmpty)

        // params.message round-tripped through encoding.
        let message = try XCTUnwrap(body["params"]?["message"])
        XCTAssertEqual(message["messageId"]?.stringValue, "msg-1")
        XCTAssertEqual(message["role"]?.stringValue, "user")
        XCTAssertEqual(message["kind"]?.stringValue, "message")
        XCTAssertEqual(message["parts"]?[0]?["kind"]?.stringValue, "text")
        XCTAssertEqual(message["parts"]?[0]?["text"]?.stringValue, "Hello")
    }

    // MARK: - sendStreamingMessage

    func testSendStreamingMessageConsumesSSEAndYieldsEvents() async throws {
        let sse = """
        data: {"jsonrpc":"2.0","result":{"state":"working"}}

        data: {"jsonrpc":"2.0","result":{"state":"completed","text":"Hello!"}}

        data: [DONE]

        """

        let (client, mock) = try makeClient(streamingHandler: { _ in
            HTTPStreamingResponse(
                status: 200, statusText: "OK", headers: [:],
                bytes: MockTransport.bytes(sse)
            )
        })

        let a2a = client.a2a(agentId: "test-agent")
        let stream = try await a2a.sendStreamingMessage(sampleParams())

        var events: [JSONValue] = []
        for try await event in stream { events.append(event) }

        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(events[0]["result"]?["state"]?.stringValue, "working")
        XCTAssertEqual(events[1]["result"]?["state"]?.stringValue, "completed")
        XCTAssertEqual(events[1]["result"]?["text"]?.stringValue, "Hello!")

        // Request shape: POST to /api/a2a/:agentId with stream=true and method=message/stream.
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/a2a/test-agent")
        XCTAssertTrue(req.stream)

        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["jsonrpc"]?.stringValue, "2.0")
        XCTAssertEqual(body["method"]?.stringValue, "message/stream")
        XCTAssertNotNil(body["id"]?.stringValue)
    }

    // MARK: - getTask

    func testGetTaskPostsTasksGetEnvelope() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "jsonrpc": "2.0",
                "id": "req-2",
                "result": [
                    "id": "task-123",
                    "contextId": "ctx-1",
                    "kind": "task",
                    "status": [
                        "state": "completed",
                        "timestamp": "2026-04-14T00:00:00Z",
                    ],
                ],
            ])
        })

        let a2a = client.a2a(agentId: "test-agent")
        let response = try await a2a.getTask(TaskQueryParams(id: "task-123", historyLength: 10))

        XCTAssertEqual(response.result?.id, "task-123")
        XCTAssertEqual(response.result?.contextId, "ctx-1")
        XCTAssertEqual(response.result?.status.state, "completed")

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/a2a/test-agent")

        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["method"]?.stringValue, "tasks/get")
        XCTAssertEqual(body["params"]?["id"]?.stringValue, "task-123")
        XCTAssertEqual(body["params"]?["historyLength"]?.intValue, 10)
    }

    // MARK: - cancelTask

    func testCancelTaskPostsTasksCancelEnvelopeAndReturnsTask() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "jsonrpc": "2.0",
                "id": "req-3",
                "result": [
                    "id": "task-xyz",
                    "kind": "task",
                    "status": ["state": "canceled"],
                ],
            ])
        })

        let a2a = client.a2a(agentId: "test-agent")
        let task = try await a2a.cancelTask(TaskQueryParams(id: "task-xyz"))

        XCTAssertEqual(task.id, "task-xyz")
        XCTAssertEqual(task.status.state, "canceled")

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/a2a/test-agent")

        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["method"]?.stringValue, "tasks/cancel")
        XCTAssertEqual(body["params"]?["id"]?.stringValue, "task-xyz")
    }

    func testCancelTaskThrowsOnJSONRPCError() async throws {
        let (client, _) = try makeClient(handler: { _ in
            self.jsonResponse([
                "jsonrpc": "2.0",
                "id": "req-4",
                "error": ["code": -32600, "message": "Invalid Request"],
            ])
        })

        let a2a = client.a2a(agentId: "test-agent")
        do {
            _ = try await a2a.cancelTask(TaskQueryParams(id: "missing"))
            XCTFail("expected cancelTask to throw on JSON-RPC error")
        } catch {
            // ok
        }
    }
}
