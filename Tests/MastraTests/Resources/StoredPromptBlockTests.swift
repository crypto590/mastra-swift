import XCTest
@testable import Mastra
import MastraTestingSupport

final class StoredPromptBlockTests: XCTestCase {
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
        return (try MastraClient(configuration: config), mock)
    }

    private func jsonResponse(_ object: Any) -> HTTPResponse {
        let data = try! JSONSerialization.data(withJSONObject: object, options: [])
        return HTTPResponse(status: 200, statusText: "OK", headers: [:], body: data)
    }

    private func decodeBody(_ request: HTTPRequest) -> JSONValue? {
        guard case .json(let value) = request.body else { return nil }
        return value
    }

    private func payload(id: String = "pb1") -> [String: Any] {
        [
            "id": id,
            "status": "published",
            "createdAt": "2025-01-01T00:00:00Z",
            "updatedAt": "2025-01-01T00:00:00Z",
            "name": "Greeting",
            "content": "Hello!",
        ]
    }

    private func versionPayload(id: String = "pbv1", blockId: String = "pb1") -> [String: Any] {
        [
            "id": id,
            "blockId": blockId,
            "versionNumber": 1,
            "name": "Greeting",
            "content": "Hello!",
            "createdAt": "2025-01-01T00:00:00Z",
        ]
    }

    // MARK: - details

    func testDetailsGetsPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(self.payload(id: "pb1"))
        })
        let out = try await client.storedPromptBlock(id: "pb1").details()
        XCTAssertEqual(out.id, "pb1")
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/stored/prompt-blocks/pb1")
    }

    func testDetailsWithStatusAddsQuery() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(self.payload())
        })
        _ = try await client.storedPromptBlock(id: "pb1").details(status: .published)
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertTrue(req.query.contains(.init(name: "status", value: "published")))
    }

    // MARK: - update

    func testUpdatePatches() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(self.payload())
        })
        _ = try await client.storedPromptBlock(id: "pb1").update(
            UpdateStoredPromptBlockParams(name: "Greeting 2", content: "Hi there")
        )
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .PATCH)
        XCTAssertEqual(req.fullPath, "/api/stored/prompt-blocks/pb1")
        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["name"]?.stringValue, "Greeting 2")
        XCTAssertEqual(body["content"]?.stringValue, "Hi there")
    }

    // MARK: - delete

    func testDeleteSendsDelete() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["success": true, "message": "ok"])
        })
        let out = try await client.storedPromptBlock(id: "pb1").delete()
        XCTAssertTrue(out.success)
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .DELETE)
        XCTAssertEqual(req.fullPath, "/api/stored/prompt-blocks/pb1")
    }

    // MARK: - listVersions

    func testListVersionsGetsPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "versions": [],
                "total": 0,
                "page": 1,
                "hasMore": false,
            ])
        })
        _ = try await client.storedPromptBlock(id: "pb1").listVersions(
            ListPromptBlockVersionsParams(page: 3, perPage: 5, orderBy: .createdAt, sortDirection: .ASC)
        )
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/stored/prompt-blocks/pb1/versions")
        XCTAssertTrue(req.query.contains(.init(name: "page", value: "3")))
        XCTAssertTrue(req.query.contains(.init(name: "orderBy", value: "createdAt")))
        XCTAssertTrue(req.query.contains(.init(name: "sortDirection", value: "ASC")))
    }

    // MARK: - createVersion

    func testCreateVersionPosts() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(self.versionPayload())
        })
        _ = try await client.storedPromptBlock(id: "pb1").createVersion(
            CreatePromptBlockVersionParams(changeMessage: "bootstrap")
        )
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/stored/prompt-blocks/pb1/versions")
        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["changeMessage"]?.stringValue, "bootstrap")
    }

    // MARK: - activateVersion

    func testActivateVersionPosts() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "success": true, "message": "ok", "activeVersionId": "pbv1",
            ])
        })
        let out = try await client.storedPromptBlock(id: "pb1").activateVersion(versionId: "pbv1")
        XCTAssertEqual(out.activeVersionId, "pbv1")
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/stored/prompt-blocks/pb1/versions/pbv1/activate")
    }

    // MARK: - restoreVersion

    func testRestoreVersionPosts() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(self.versionPayload(id: "pbv2"))
        })
        let out = try await client.storedPromptBlock(id: "pb1").restoreVersion(versionId: "pbv1")
        XCTAssertEqual(out.id, "pbv2")
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/stored/prompt-blocks/pb1/versions/pbv1/restore")
    }

    // MARK: - deleteVersion

    func testDeleteVersionSendsDelete() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["success": true, "message": "gone"])
        })
        _ = try await client.storedPromptBlock(id: "pb1").deleteVersion(versionId: "pbv1")
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .DELETE)
        XCTAssertEqual(req.fullPath, "/api/stored/prompt-blocks/pb1/versions/pbv1")
    }

    // MARK: - compareVersions

    func testCompareVersionsGetsComparePath() async throws {
        let v = self.versionPayload()
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "fromVersion": v,
                "toVersion": v,
                "diffs": [],
            ])
        })
        _ = try await client.storedPromptBlock(id: "pb1").compareVersions(fromId: "a", toId: "b")
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.fullPath, "/api/stored/prompt-blocks/pb1/versions/compare")
        XCTAssertTrue(req.query.contains(.init(name: "from", value: "a")))
        XCTAssertTrue(req.query.contains(.init(name: "to", value: "b")))
    }

    // MARK: - top-level list / create / get

    func testTopLevelListStoredPromptBlocks() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "promptBlocks": [],
                "total": 0,
                "page": 1,
                "hasMore": false,
            ])
        })
        _ = try await client.listStoredPromptBlocks(
            ListStoredPromptBlocksParams(
                page: 2,
                orderBy: .init(field: .updatedAt, direction: .ASC),
                status: .draft
            )
        )
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.fullPath, "/api/stored/prompt-blocks")
        XCTAssertTrue(req.query.contains(.init(name: "page", value: "2")))
        XCTAssertTrue(req.query.contains(.init(name: "orderBy[field]", value: "updatedAt")))
        XCTAssertTrue(req.query.contains(.init(name: "orderBy[direction]", value: "ASC")))
        XCTAssertTrue(req.query.contains(.init(name: "status", value: "draft")))
    }

    func testTopLevelCreateStoredPromptBlockPostsBody() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(self.payload(id: "new"))
        })
        let params = CreateStoredPromptBlockParams(name: "Welcome", content: "Hi!")
        let out = try await client.createStoredPromptBlock(params)
        XCTAssertEqual(out.id, "new")
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/stored/prompt-blocks")
        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["name"]?.stringValue, "Welcome")
        XCTAssertEqual(body["content"]?.stringValue, "Hi!")
    }

    func testTopLevelFactoryReturnsHandle() throws {
        let (client, _) = try makeClient()
        let handle = client.storedPromptBlock(id: "pb-x")
        XCTAssertEqual(handle.storedPromptBlockId, "pb-x")
    }
}
