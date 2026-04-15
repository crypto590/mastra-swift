import XCTest
@testable import Mastra
import MastraTestingSupport

final class MemoryThreadTests: XCTestCase {
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

    // MARK: - createMemoryThread

    func testCreateMemoryThreadPostsShape() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "id": "thread-1",
                "resourceId": "res-1",
                "title": "My thread",
            ])
        })
        let params = CreateMemoryThreadParams(
            resourceId: "res-1",
            agentId: "agent-1",
            title: "My thread",
            metadata: ["tag": .string("demo")],
            threadId: "thread-1"
        )
        let info = try await client.createMemoryThread(params)
        XCTAssertEqual(info.id, "thread-1")
        XCTAssertEqual(info.title, "My thread")

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/memory/threads")
        XCTAssertTrue(req.query.contains(.init(name: "agentId", value: "agent-1")))

        let body = try XCTUnwrap(decodeBody(req))
        XCTAssertEqual(body["resourceId"]?.stringValue, "res-1")
        XCTAssertEqual(body["agentId"]?.stringValue, "agent-1")
        XCTAssertEqual(body["title"]?.stringValue, "My thread")
        XCTAssertEqual(body["threadId"]?.stringValue, "thread-1")
        XCTAssertEqual(body["metadata"]?["tag"]?.stringValue, "demo")
    }

    // MARK: - listThreadMessages (GET path with query params)

    func testListThreadMessagesGetsExpectedPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["messages": []])
        })
        let thread = client.memoryThread(threadId: "t-1", agentId: "agent-1")
        let params = ListMemoryThreadMessagesParams(
            page: 2,
            perPage: 20,
            resourceId: "res-1",
            orderBy: .object(["field": .string("createdAt"), "direction": .string("DESC")]),
            filter: .object(["role": .string("user")]),
            include: .array([.string("metadata")]),
            includeSystemReminders: true
        )
        _ = try await thread.listMessages(params)

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/memory/threads/t-1/messages")

        // agentId from the MemoryThread handle
        XCTAssertTrue(req.query.contains(.init(name: "agentId", value: "agent-1")))
        XCTAssertTrue(req.query.contains(.init(name: "resourceId", value: "res-1")))
        XCTAssertTrue(req.query.contains(.init(name: "page", value: "2")))
        XCTAssertTrue(req.query.contains(.init(name: "perPage", value: "20")))
        XCTAssertTrue(req.query.contains(.init(name: "includeSystemReminders", value: "true")))

        // orderBy/filter/include are JSON-stringified
        let orderBy = req.query.first(where: { $0.name == "orderBy" })?.value ?? ""
        XCTAssertTrue(orderBy.contains("\"field\""))
        XCTAssertTrue(orderBy.contains("createdAt"))

        let filter = req.query.first(where: { $0.name == "filter" })?.value ?? ""
        XCTAssertTrue(filter.contains("\"role\""))
        XCTAssertTrue(filter.contains("user"))

        let include = req.query.first(where: { $0.name == "include" })?.value ?? ""
        XCTAssertTrue(include.contains("metadata"))
    }

    // MARK: - saveMessageToMemory (POST body shape)

    func testSaveMessageToMemoryPostsShape() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["messages": []])
        })
        let params = SaveMessageToMemoryParams(
            messages: [
                .object(["role": .string("user"), "content": .string("hi")]),
                .object(["role": .string("assistant"), "content": .string("yo")]),
            ],
            agentId: "agent-x"
        )
        _ = try await client.saveMessageToMemory(params)

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/memory/save-messages")
        XCTAssertTrue(req.query.contains(.init(name: "agentId", value: "agent-x")))

        let body = try XCTUnwrap(decodeBody(req))
        XCTAssertEqual(body["agentId"]?.stringValue, "agent-x")
        let messages = try XCTUnwrap(body["messages"]?.arrayValue)
        XCTAssertEqual(messages.count, 2)
        XCTAssertEqual(messages[0]["role"]?.stringValue, "user")
    }

    // MARK: - getWorkingMemory (GET path)

    func testGetWorkingMemoryGetPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([:])
        })
        let params = GetWorkingMemoryParams(
            agentId: "a1",
            threadId: "t-42",
            resourceId: "res-7"
        )
        _ = try await client.workingMemory(params)

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/memory/threads/t-42/working-memory")
        XCTAssertTrue(req.query.contains(.init(name: "agentId", value: "a1")))
        XCTAssertTrue(req.query.contains(.init(name: "resourceId", value: "res-7")))
    }

    // MARK: - searchMemory (POST shape)
    // Note: JS client issues a GET for searchMemory; we preserve that contract
    // exactly (params flow in the query string). Name kept for parity with the
    // brief.

    func testSearchMemoryShape() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "results": [],
                "count": 0,
                "query": "hello",
            ])
        })
        let params = SearchMemoryParams(
            agentId: "a1",
            resourceId: "res-1",
            searchQuery: "hello",
            threadId: "t-1",
            memoryConfig: .object(["limit": .int(5)])
        )
        _ = try await client.searchMemory(params)

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/memory/search")
        XCTAssertTrue(req.query.contains(.init(name: "searchQuery", value: "hello")))
        XCTAssertTrue(req.query.contains(.init(name: "resourceId", value: "res-1")))
        XCTAssertTrue(req.query.contains(.init(name: "agentId", value: "a1")))
        XCTAssertTrue(req.query.contains(.init(name: "threadId", value: "t-1")))
        let memoryConfig = req.query.first(where: { $0.name == "memoryConfig" })?.value ?? ""
        XCTAssertTrue(memoryConfig.contains("limit"))
    }

    // MARK: - updateWorkingMemory (POST shape)

    func testUpdateWorkingMemoryPostsShape() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([:])
        })
        let params = UpdateWorkingMemoryParams(
            agentId: "a1",
            threadId: "t-1",
            workingMemory: "remembered text",
            resourceId: "res-1"
        )
        _ = try await client.updateWorkingMemory(params)

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/memory/threads/t-1/working-memory")
        XCTAssertTrue(req.query.contains(.init(name: "agentId", value: "a1")))

        let body = try XCTUnwrap(decodeBody(req))
        XCTAssertEqual(body["workingMemory"]?.stringValue, "remembered text")
        XCTAssertEqual(body["resourceId"]?.stringValue, "res-1")
    }

    // MARK: - getObservationalMemory (query params)

    func testGetObservationalMemoryQueryParams() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["record": NSNull()])
        })
        let from = Date(timeIntervalSince1970: 0)
        let to = Date(timeIntervalSince1970: 1_700_000_000)
        let params = GetObservationalMemoryParams(
            agentId: "a1",
            resourceId: "res-1",
            threadId: "t-1",
            from: from,
            to: to,
            offset: 10,
            limit: 50
        )
        _ = try await client.observationalMemory(params)

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/memory/observational-memory")
        XCTAssertTrue(req.query.contains(.init(name: "agentId", value: "a1")))
        XCTAssertTrue(req.query.contains(.init(name: "resourceId", value: "res-1")))
        XCTAssertTrue(req.query.contains(.init(name: "threadId", value: "t-1")))
        XCTAssertTrue(req.query.contains(.init(name: "offset", value: "10")))
        XCTAssertTrue(req.query.contains(.init(name: "limit", value: "50")))

        let fromStr = req.query.first(where: { $0.name == "from" })?.value
        let toStr = req.query.first(where: { $0.name == "to" })?.value
        XCTAssertNotNil(fromStr)
        XCTAssertNotNil(toStr)
        // ISO 8601 with fractional seconds — should start with a 4-digit year.
        XCTAssertTrue(fromStr?.hasPrefix("1970") ?? false)
        XCTAssertTrue(toStr?.hasPrefix("2023") ?? false)
    }

    // MARK: - deleteMessages (POST body shape)

    func testDeleteMessagesPostsShape() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["success": true, "message": "deleted"])
        })
        let thread = client.memoryThread(threadId: "t-1", agentId: "a1")
        _ = try await thread.deleteMessages(["m1", "m2"])

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/memory/messages/delete")
        XCTAssertTrue(req.query.contains(.init(name: "agentId", value: "a1")))

        let body = try XCTUnwrap(decodeBody(req))
        let ids = try XCTUnwrap(body["messageIds"]?.arrayValue)
        XCTAssertEqual(ids.compactMap { $0.stringValue }, ["m1", "m2"])
    }

    // MARK: - listMemoryThreads (bare-array response shape)

    func testListMemoryThreadsAcceptsArrayResponse() async throws {
        let (client, _) = try makeClient(handler: { _ in
            self.jsonResponse([
                ["id": "t1"],
                ["id": "t2"],
            ])
        })
        let resp = try await client.listMemoryThreads()
        XCTAssertEqual(resp.threads.count, 2)
        XCTAssertEqual(resp.threads.first?.id, "t1")
    }
}
