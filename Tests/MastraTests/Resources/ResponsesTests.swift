import XCTest
@testable import Mastra
import MastraTestingSupport

final class ResponsesTests: XCTestCase {
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

    // MARK: - create

    func testCreatePostsBodyAndAttachesOutputText() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "id": "resp_123",
                "object": "response",
                "created_at": 1_234_567_890,
                "model": "support-agent",
                "status": "completed",
                "output": [
                    [
                        "id": "msg_1",
                        "type": "message",
                        "role": "assistant",
                        "status": "completed",
                        "content": [
                            ["type": "output_text", "text": "Hello from Mastra"]
                        ]
                    ]
                ],
                "usage": NSNull(),
                "conversation_id": "conv_123",
            ])
        })

        let params = CreateResponseParams(
            model: "openai/gpt-5",
            agent_id: "support-agent",
            input: "Summarize this ticket",
            store: true
        )
        let response = try await client.responses.create(params)

        XCTAssertEqual(response.id, "resp_123")
        XCTAssertEqual(response.conversation_id, "conv_123")
        // Derived client-side, mirroring JS `attachOutputText`.
        XCTAssertEqual(response.output_text, "Hello from Mastra")

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/v1/responses")

        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["model"]?.stringValue, "openai/gpt-5")
        XCTAssertEqual(body["agent_id"]?.stringValue, "support-agent")
        XCTAssertEqual(body["input"]?.stringValue, "Summarize this ticket")
        XCTAssertEqual(body["store"]?.boolValue, true)
        // No stream flag on non-streaming create.
        XCTAssertNil(body["stream"])
    }

    func testCreatePassesTextJsonSchemaFormat() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "id": "r", "object": "response", "created_at": 0,
                "model": "m", "status": "completed", "output": [],
            ])
        })

        let schema: JSONValue = .object([
            "type": .string("object"),
            "properties": .object([
                "summary": .object(["type": .string("string")])
            ]),
        ])
        let params = CreateResponseParams(
            agent_id: "a",
            input: "Return typed",
            text: ResponseTextConfig(format: .jsonSchema(
                name: "ticket_summary",
                schema: schema,
                strict: true
            ))
        )
        _ = try await client.responses.create(params)

        let body = try XCTUnwrap(self.decodeBody(mock.requests[0]))
        let text = try XCTUnwrap(body["text"])
        XCTAssertEqual(text["format"]?["type"]?.stringValue, "json_schema")
        XCTAssertEqual(text["format"]?["name"]?.stringValue, "ticket_summary")
        XCTAssertEqual(text["format"]?["strict"]?.boolValue, true)
        XCTAssertEqual(text["format"]?["schema"]?["type"]?.stringValue, "object")
    }

    func testCreateWithInputMessages() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "id": "r", "object": "response", "created_at": 0,
                "model": "m", "status": "completed", "output": [],
            ])
        })
        let params = CreateResponseParams(
            agent_id: "a",
            input: .messages([
                ResponseInputMessage(role: "user", content: .text("Hi")),
                ResponseInputMessage(
                    role: "assistant",
                    content: .parts([ResponseInputTextPart(text: "Hello")])
                ),
            ])
        )
        _ = try await client.responses.create(params)

        let body = try XCTUnwrap(self.decodeBody(mock.requests[0]))
        let input = try XCTUnwrap(body["input"]?.arrayValue)
        XCTAssertEqual(input.count, 2)
        XCTAssertEqual(input[0]["role"]?.stringValue, "user")
        XCTAssertEqual(input[0]["content"]?.stringValue, "Hi")
        XCTAssertEqual(input[1]["content"]?[0]?["text"]?.stringValue, "Hello")
    }

    // MARK: - stream

    func testStreamYieldsTypedEvents() async throws {
        let sse = """
        data: {"type":"response.created","sequence_number":1,"response":{"id":"r","object":"response","created_at":0,"model":"m","status":"in_progress","output":[],"usage":null}}

        data: {"type":"response.output_text.delta","sequence_number":2,"output_index":0,"content_index":0,"item_id":"msg_1","delta":"Hello"}

        data: {"type":"response.completed","sequence_number":3,"response":{"id":"r","object":"response","created_at":0,"model":"m","status":"completed","output":[{"id":"msg_1","type":"message","role":"assistant","status":"completed","content":[{"type":"output_text","text":"Hello world"}]}],"usage":null}}

        data: [DONE]

        """

        let (client, mock) = try makeClient(streamingHandler: { _ in
            HTTPStreamingResponse(
                status: 200, statusText: "OK", headers: [:],
                bytes: MockTransport.bytes(sse)
            )
        })

        let params = CreateResponseParams(
            model: "openai/gpt-5",
            agent_id: "support-agent",
            input: "Say hello"
        )
        let stream = try await client.responses.stream(params)

        var events: [ResponseEvent] = []
        for try await event in stream { events.append(event) }

        XCTAssertEqual(events.count, 3)

        // Created event hydrates output_text on its nested response.
        if case .created(let response, let seq) = events[0] {
            XCTAssertEqual(seq, 1)
            XCTAssertEqual(response.id, "r")
            XCTAssertEqual(response.output_text, "")
        } else {
            XCTFail("expected response.created, got \(events[0])")
        }

        if case .outputTextDelta(_, _, let itemId, let delta, let seq) = events[1] {
            XCTAssertEqual(itemId, "msg_1")
            XCTAssertEqual(delta, "Hello")
            XCTAssertEqual(seq, 2)
        } else {
            XCTFail("expected response.output_text.delta, got \(events[1])")
        }

        if case .completed(let response, _) = events[2] {
            XCTAssertEqual(response.output_text, "Hello world")
        } else {
            XCTFail("expected response.completed, got \(events[2])")
        }

        // Stream request goes to the same path with stream flag on body.
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/v1/responses")
        XCTAssertTrue(req.stream)
        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["stream"]?.boolValue, true)
    }

    // MARK: - retrieve

    func testRetrieveGetsResponseById() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "id": "resp_x",
                "object": "response",
                "created_at": 0,
                "model": "m",
                "status": "completed",
                "output": [
                    [
                        "id": "msg",
                        "type": "message",
                        "role": "assistant",
                        "status": "completed",
                        "content": [
                            ["type": "output_text", "text": "hi"]
                        ]
                    ]
                ],
            ])
        })

        let response = try await client.responses.retrieve("resp_x")
        XCTAssertEqual(response.id, "resp_x")
        XCTAssertEqual(response.output_text, "hi")

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/v1/responses/resp_x")
    }

    // MARK: - delete

    func testDeleteCallsDeleteOnResponseId() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "id": "resp_x",
                "object": "response",
                "deleted": true,
            ])
        })

        let deleted = try await client.responses.delete("resp_x")
        XCTAssertEqual(deleted.id, "resp_x")
        XCTAssertTrue(deleted.deleted)

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .DELETE)
        XCTAssertEqual(req.fullPath, "/api/v1/responses/resp_x")
    }

    // MARK: - requestContext

    func testRetrieveAddsRequestContextQuery() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "id": "r", "object": "response", "created_at": 0,
                "model": "m", "status": "completed", "output": [],
            ])
        })
        let context = RequestContext(["tenant": .string("acme")])
        _ = try await client.responses.retrieve("r", requestContext: context)

        let req = try XCTUnwrap(mock.requests.first)
        let item = try XCTUnwrap(req.query.first(where: { $0.name == "requestContext" }))
        XCTAssertNotNil(item.value)
        XCTAssertFalse(item.value!.isEmpty)
    }
}
