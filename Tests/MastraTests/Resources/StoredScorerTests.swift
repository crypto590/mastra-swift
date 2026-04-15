import XCTest
@testable import Mastra
import MastraTestingSupport

final class StoredScorerTests: XCTestCase {
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

    private func payload(id: String = "s1") -> [String: Any] {
        [
            "id": id,
            "status": "published",
            "createdAt": "2025-01-01T00:00:00Z",
            "updatedAt": "2025-01-01T00:00:00Z",
            "name": "Relevance",
            "type": "answer-relevancy",
        ]
    }

    private func versionPayload(id: String = "sv1", scorerId: String = "s1") -> [String: Any] {
        [
            "id": id,
            "scorerDefinitionId": scorerId,
            "versionNumber": 1,
            "name": "Relevance",
            "type": "answer-relevancy",
            "createdAt": "2025-01-01T00:00:00Z",
        ]
    }

    // MARK: - details

    func testDetailsGetsPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(self.payload())
        })
        _ = try await client.storedScorer(id: "s1").details()
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/stored/scorers/s1")
    }

    func testDetailsWithStatus() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(self.payload())
        })
        _ = try await client.storedScorer(id: "s1").details(status: .archived)
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertTrue(req.query.contains(.init(name: "status", value: "archived")))
    }

    // MARK: - update

    func testUpdatePatches() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(self.payload())
        })
        _ = try await client.storedScorer(id: "s1").update(
            UpdateStoredScorerParams(name: "Renamed", type: .bias)
        )
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .PATCH)
        XCTAssertEqual(req.fullPath, "/api/stored/scorers/s1")
        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["name"]?.stringValue, "Renamed")
        XCTAssertEqual(body["type"]?.stringValue, "bias")
    }

    // MARK: - delete

    func testDeleteSendsDelete() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["success": true, "message": "ok"])
        })
        _ = try await client.storedScorer(id: "s1").delete()
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .DELETE)
        XCTAssertEqual(req.fullPath, "/api/stored/scorers/s1")
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
        _ = try await client.storedScorer(id: "s1").listVersions(
            ListScorerVersionsParams(page: 4, perPage: 2, orderBy: .versionNumber, sortDirection: .DESC)
        )
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.fullPath, "/api/stored/scorers/s1/versions")
        XCTAssertTrue(req.query.contains(.init(name: "page", value: "4")))
        XCTAssertTrue(req.query.contains(.init(name: "perPage", value: "2")))
        XCTAssertTrue(req.query.contains(.init(name: "orderBy", value: "versionNumber")))
        XCTAssertTrue(req.query.contains(.init(name: "sortDirection", value: "DESC")))
    }

    // MARK: - createVersion

    func testCreateVersionPosts() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(self.versionPayload())
        })
        _ = try await client.storedScorer(id: "s1").createVersion(
            CreateScorerVersionParams(changeMessage: "init")
        )
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/stored/scorers/s1/versions")
        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["changeMessage"]?.stringValue, "init")
    }

    // MARK: - activateVersion

    func testActivateVersionPosts() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "success": true, "message": "ok", "activeVersionId": "sv1",
            ])
        })
        let out = try await client.storedScorer(id: "s1").activateVersion(versionId: "sv1")
        XCTAssertEqual(out.activeVersionId, "sv1")
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/stored/scorers/s1/versions/sv1/activate")
    }

    // MARK: - restoreVersion

    func testRestoreVersionPosts() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(self.versionPayload(id: "sv2"))
        })
        let out = try await client.storedScorer(id: "s1").restoreVersion(versionId: "sv1")
        XCTAssertEqual(out.id, "sv2")
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/stored/scorers/s1/versions/sv1/restore")
    }

    // MARK: - deleteVersion

    func testDeleteVersionSendsDelete() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["success": true, "message": "gone"])
        })
        _ = try await client.storedScorer(id: "s1").deleteVersion(versionId: "sv1")
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .DELETE)
        XCTAssertEqual(req.fullPath, "/api/stored/scorers/s1/versions/sv1")
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
        _ = try await client.storedScorer(id: "s1").compareVersions(fromId: "a", toId: "b")
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.fullPath, "/api/stored/scorers/s1/versions/compare")
        XCTAssertTrue(req.query.contains(.init(name: "from", value: "a")))
        XCTAssertTrue(req.query.contains(.init(name: "to", value: "b")))
    }

    // MARK: - top-level list / create / get

    func testTopLevelListStoredScorers() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "scorerDefinitions": [],
                "total": 0,
                "page": 1,
                "hasMore": false,
            ])
        })
        _ = try await client.listStoredScorers(
            ListStoredScorersParams(authorId: "me")
        )
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.fullPath, "/api/stored/scorers")
        XCTAssertTrue(req.query.contains(.init(name: "authorId", value: "me")))
    }

    func testTopLevelCreateStoredScorerPostsBody() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(self.payload(id: "new"))
        })
        let params = CreateStoredScorerParams(
            name: "Relevance",
            type: .answerRelevancy,
            scoreRange: .init(min: 0, max: 1)
        )
        _ = try await client.createStoredScorer(params)
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/stored/scorers")
        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["name"]?.stringValue, "Relevance")
        XCTAssertEqual(body["type"]?.stringValue, "answer-relevancy")
        XCTAssertEqual(body["scoreRange"]?["min"]?.doubleValue, 0)
        XCTAssertEqual(body["scoreRange"]?["max"]?.doubleValue, 1)
    }

    func testTopLevelFactoryReturnsHandle() throws {
        let (client, _) = try makeClient()
        let handle = client.storedScorer(id: "sc-x")
        XCTAssertEqual(handle.storedScorerId, "sc-x")
    }
}
