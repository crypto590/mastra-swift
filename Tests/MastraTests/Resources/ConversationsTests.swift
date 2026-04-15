import XCTest
@testable import Mastra
import MastraTestingSupport

final class ConversationsTests: XCTestCase {
    // MARK: - Helpers

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

    private func jsonResponse(_ object: Any) -> HTTPResponse {
        let data = try! JSONSerialization.data(withJSONObject: object, options: [])
        return HTTPResponse(status: 200, statusText: "OK", headers: [:], body: data)
    }

    private func decodeBody(_ request: HTTPRequest) -> JSONValue? {
        guard case .json(let value) = request.body else { return nil }
        return value
    }

    // MARK: - create

    func testCreatePostsConversationBody() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "id": "conv_123",
                "object": "conversation",
                "thread": [
                    "id": "conv_123",
                    "resourceId": "conv_123",
                ]
            ])
        })

        let conversation = try await client.conversations.create(
            CreateConversationParams(
                agent_id: "support-agent",
                conversation_id: "conv_123"
            )
        )

        XCTAssertEqual(conversation.id, "conv_123")
        XCTAssertEqual(conversation.object, "conversation")
        XCTAssertEqual(conversation.thread["id"]?.stringValue, "conv_123")

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/v1/conversations")
        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["agent_id"]?.stringValue, "support-agent")
        XCTAssertEqual(body["conversation_id"]?.stringValue, "conv_123")
        // requestContext is destructured out of the body in JS; we mirror that.
        XCTAssertNil(body["requestContext"])
    }

    func testCreatePassesOptionalFieldsThrough() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "id": "c",
                "object": "conversation",
                "thread": ["id": "c"]
            ])
        })
        _ = try await client.conversations.create(
            CreateConversationParams(
                agent_id: "a",
                resource_id: "res-1",
                title: "Hello",
                metadata: ["k": .string("v")]
            )
        )
        let body = try XCTUnwrap(self.decodeBody(mock.requests[0]))
        XCTAssertEqual(body["agent_id"]?.stringValue, "a")
        XCTAssertEqual(body["resource_id"]?.stringValue, "res-1")
        XCTAssertEqual(body["title"]?.stringValue, "Hello")
        XCTAssertEqual(body["metadata"]?["k"]?.stringValue, "v")
    }

    // MARK: - retrieve

    func testRetrieveGetsConversationById() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "id": "conv_123",
                "object": "conversation",
                "thread": ["id": "conv_123"]
            ])
        })

        let conversation = try await client.conversations.retrieve("conv_123")
        XCTAssertEqual(conversation.id, "conv_123")

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/v1/conversations/conv_123")
    }

    // MARK: - delete

    func testDeleteCallsDeleteOnConversation() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "id": "conv_123",
                "object": "conversation.deleted",
                "deleted": true,
            ])
        })

        let result = try await client.conversations.delete("conv_123")
        XCTAssertTrue(result.deleted)

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .DELETE)
        XCTAssertEqual(req.fullPath, "/api/v1/conversations/conv_123")
    }

    // MARK: - items.list

    func testItemsListGetsConversationItemsPage() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "object": "list",
                "data": [
                    [
                        "id": "msg_1",
                        "type": "message",
                        "role": "user",
                        "status": "completed",
                        "content": [
                            ["type": "input_text", "text": "Hello"]
                        ]
                    ]
                ],
                "first_id": "msg_1",
                "last_id": "msg_1",
                "has_more": false,
            ])
        })

        let page = try await client.conversations.items.list("conv_123")
        XCTAssertEqual(page.data.count, 1)
        XCTAssertEqual(page.first_id, "msg_1")
        XCTAssertEqual(page.last_id, "msg_1")
        XCTAssertFalse(page.has_more)

        if case .message(let message) = page.data[0] {
            XCTAssertEqual(message.id, "msg_1")
            XCTAssertEqual(message.role, "user")
            if case .inputText(let part) = message.content[0] {
                XCTAssertEqual(part.text, "Hello")
            } else {
                XCTFail("expected input_text content part")
            }
        } else {
            XCTFail("expected message conversation item")
        }

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/v1/conversations/conv_123/items")
    }

    func testItemsListForwardsRequestContextQuery() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "object": "list",
                "data": [],
                "first_id": NSNull(),
                "last_id": NSNull(),
                "has_more": false,
            ])
        })

        let context = RequestContext(["tenant": .string("acme")])
        _ = try await client.conversations.items.list("conv_x", requestContext: context)

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.fullPath, "/api/v1/conversations/conv_x/items")
        let item = try XCTUnwrap(req.query.first(where: { $0.name == "requestContext" }))
        XCTAssertNotNil(item.value)
        XCTAssertFalse(item.value!.isEmpty)
    }
}
