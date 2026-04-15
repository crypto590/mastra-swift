import XCTest
@testable import Mastra
import MastraTestingSupport

final class StoredAgentTests: XCTestCase {
    // MARK: - Helpers

    private func makeClient(
        handler: @escaping MockTransport.Handler = { _ in
            HTTPResponse(status: 200, statusText: "OK", headers: [:], body: Data("{}".utf8))
        }
    ) throws -> (MastraClient, MockTransport) {
        let mock = MockTransport(
            handler: handler,
            streamingHandler: { _ in
                HTTPStreamingResponse(
                    status: 200, statusText: "OK", headers: [:],
                    bytes: AsyncThrowingStream { $0.finish() }
                )
            }
        )
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

    private func storedAgentPayload(id: String = "a1") -> [String: Any] {
        [
            "id": id,
            "status": "published",
            "createdAt": "2025-01-01T00:00:00Z",
            "updatedAt": "2025-01-01T00:00:00Z",
            "name": "Alpha",
            "instructions": "Say hi",
        ]
    }

    // MARK: - details

    func testDetailsGetsStoredAgentsPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(self.storedAgentPayload(id: "a1"))
        })
        let agent = client.storedAgent(id: "a1")
        let out = try await agent.details()
        XCTAssertEqual(out.id, "a1")
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/stored/agents/a1")
    }

    func testDetailsWithStatusAddsQuery() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(self.storedAgentPayload())
        })
        _ = try await client.storedAgent(id: "a1").details(status: .draft)
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertTrue(req.query.contains(.init(name: "status", value: "draft")))
    }

    // MARK: - update

    func testUpdateSendsPatchWithBody() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(self.storedAgentPayload())
        })
        _ = try await client.storedAgent(id: "a1").update(
            UpdateStoredAgentParams(
                name: "Renamed",
                changeMessage: "rename"
            )
        )
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .PATCH)
        XCTAssertEqual(req.fullPath, "/api/stored/agents/a1")
        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["name"]?.stringValue, "Renamed")
        XCTAssertEqual(body["changeMessage"]?.stringValue, "rename")
    }

    // MARK: - delete

    func testDeleteSendsDelete() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["success": true, "message": "ok"])
        })
        let resp = try await client.storedAgent(id: "a1").delete()
        XCTAssertTrue(resp.success)
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .DELETE)
        XCTAssertEqual(req.fullPath, "/api/stored/agents/a1")
    }

    // MARK: - listVersions

    func testListVersionsGetsVersionsPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "versions": [],
                "total": 0,
                "page": 1,
                "hasMore": false,
            ])
        })
        _ = try await client.storedAgent(id: "a1").listVersions(
            ListAgentVersionsParams(page: 2, perPage: 10, orderBy: .versionNumber, sortDirection: .DESC)
        )
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/stored/agents/a1/versions")
        XCTAssertTrue(req.query.contains(.init(name: "page", value: "2")))
        XCTAssertTrue(req.query.contains(.init(name: "perPage", value: "10")))
        XCTAssertTrue(req.query.contains(.init(name: "orderBy", value: "versionNumber")))
        XCTAssertTrue(req.query.contains(.init(name: "sortDirection", value: "DESC")))
    }

    // MARK: - createVersion

    func testCreateVersionPostsBody() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "id": "v1",
                "agentId": "a1",
                "versionNumber": 1,
                "name": "n",
                "instructions": "x",
                "createdAt": "2025-01-01T00:00:00Z",
            ])
        })
        _ = try await client.storedAgent(id: "a1").createVersion(
            CreateStoredAgentVersionParams(changeMessage: "initial")
        )
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/stored/agents/a1/versions")
        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["changeMessage"]?.stringValue, "initial")
    }

    // MARK: - activateVersion

    func testActivateVersionPosts() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "success": true, "message": "ok", "activeVersionId": "v1",
            ])
        })
        let out = try await client.storedAgent(id: "a1").activateVersion(versionId: "v1")
        XCTAssertEqual(out.activeVersionId, "v1")
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/stored/agents/a1/versions/v1/activate")
    }

    // MARK: - restoreVersion

    func testRestoreVersionPosts() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "id": "v2",
                "agentId": "a1",
                "versionNumber": 2,
                "name": "n",
                "instructions": "x",
                "createdAt": "2025-01-01T00:00:00Z",
            ])
        })
        let out = try await client.storedAgent(id: "a1").restoreVersion(versionId: "v1")
        XCTAssertEqual(out.id, "v2")
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/stored/agents/a1/versions/v1/restore")
    }

    // MARK: - deleteVersion

    func testDeleteVersionSendsDelete() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["success": true, "message": "gone"])
        })
        _ = try await client.storedAgent(id: "a1").deleteVersion(versionId: "v1")
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .DELETE)
        XCTAssertEqual(req.fullPath, "/api/stored/agents/a1/versions/v1")
    }

    // MARK: - compareVersions

    func testCompareVersionsGetsComparePath() async throws {
        let versionJSON: [String: Any] = [
            "id": "v",
            "agentId": "a1",
            "versionNumber": 1,
            "name": "n",
            "instructions": "x",
            "createdAt": "2025-01-01T00:00:00Z",
        ]
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "fromVersion": versionJSON,
                "toVersion": versionJSON,
                "diffs": [],
            ])
        })
        _ = try await client.storedAgent(id: "a1").compareVersions(fromId: "v1", toId: "v2")
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/stored/agents/a1/versions/compare")
        XCTAssertTrue(req.query.contains(.init(name: "from", value: "v1")))
        XCTAssertTrue(req.query.contains(.init(name: "to", value: "v2")))
    }

    // MARK: - top-level list / create / get

    func testTopLevelListStoredAgents() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "agents": [],
                "total": 0,
                "page": 1,
                "hasMore": false,
            ])
        })
        _ = try await client.listStoredAgents(
            ListStoredAgentsParams(
                page: 1,
                perPage: 20,
                orderBy: .init(field: .createdAt, direction: .DESC),
                authorId: "me",
                metadata: .object(["tag": .string("prod")])
            )
        )
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/stored/agents")
        XCTAssertTrue(req.query.contains(.init(name: "page", value: "1")))
        XCTAssertTrue(req.query.contains(.init(name: "perPage", value: "20")))
        XCTAssertTrue(req.query.contains(.init(name: "orderBy[field]", value: "createdAt")))
        XCTAssertTrue(req.query.contains(.init(name: "orderBy[direction]", value: "DESC")))
        XCTAssertTrue(req.query.contains(.init(name: "authorId", value: "me")))
        let metaItem = req.query.first { $0.name == "metadata" }
        XCTAssertNotNil(metaItem)
        XCTAssertTrue(metaItem?.value?.contains("prod") ?? false)
    }

    func testTopLevelCreateStoredAgentPostsBody() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(self.storedAgentPayload(id: "new-id"))
        })
        let params = CreateStoredAgentParams(
            id: "new-id",
            name: "Alpha",
            instructions: .string("hi"),
            model: .object([
                "provider": .string("openai"),
                "name": .string("gpt-4"),
            ])
        )
        let out = try await client.createStoredAgent(params)
        XCTAssertEqual(out.id, "new-id")
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/stored/agents")
        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["id"]?.stringValue, "new-id")
        XCTAssertEqual(body["name"]?.stringValue, "Alpha")
        XCTAssertEqual(body["instructions"]?.stringValue, "hi")
        XCTAssertEqual(body["model"]?["provider"]?.stringValue, "openai")
    }

    func testTopLevelStoredAgentFactoryReturnsHandle() throws {
        let (client, _) = try makeClient()
        let handle = client.storedAgent(id: "xyz")
        XCTAssertEqual(handle.storedAgentId, "xyz")
    }
}
