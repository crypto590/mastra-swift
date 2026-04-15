import XCTest
@testable import Mastra
import MastraTestingSupport

final class StoredSkillTests: XCTestCase {
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

    private func payload(id: String = "sk1") -> [String: Any] {
        [
            "id": id,
            "status": "published",
            "createdAt": "2025-01-01T00:00:00Z",
            "updatedAt": "2025-01-01T00:00:00Z",
            "name": "Echo",
            "instructions": "Respond with the text provided.",
        ]
    }

    // MARK: - details

    func testDetailsGetsPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(self.payload())
        })
        let out = try await client.storedSkill(id: "sk1").details()
        XCTAssertEqual(out.id, "sk1")
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/stored/skills/sk1")
    }

    // MARK: - update

    func testUpdatePatches() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(self.payload())
        })
        let files = [
            StoredSkillFileNode(id: "f1", name: "readme.md", type: .file, content: "# Hi"),
        ]
        _ = try await client.storedSkill(id: "sk1").update(
            UpdateStoredSkillParams(name: "Renamed", instructions: "Do the thing.", files: files)
        )
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .PATCH)
        XCTAssertEqual(req.fullPath, "/api/stored/skills/sk1")
        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["name"]?.stringValue, "Renamed")
        XCTAssertEqual(body["instructions"]?.stringValue, "Do the thing.")
        let filesArr = try XCTUnwrap(body["files"]?.arrayValue)
        XCTAssertEqual(filesArr.first?["name"]?.stringValue, "readme.md")
        XCTAssertEqual(filesArr.first?["type"]?.stringValue, "file")
    }

    // MARK: - delete

    func testDeleteSendsDelete() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["success": true, "message": "ok"])
        })
        _ = try await client.storedSkill(id: "sk1").delete()
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .DELETE)
        XCTAssertEqual(req.fullPath, "/api/stored/skills/sk1")
    }

    // MARK: - top-level list / create / get

    func testTopLevelListStoredSkills() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "skills": [],
                "total": 0,
                "page": 1,
                "hasMore": false,
            ])
        })
        _ = try await client.listStoredSkills(
            ListStoredSkillsParams(
                orderBy: .init(field: .createdAt, direction: .DESC)
            )
        )
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.fullPath, "/api/stored/skills")
        XCTAssertTrue(req.query.contains(.init(name: "orderBy[field]", value: "createdAt")))
        XCTAssertTrue(req.query.contains(.init(name: "orderBy[direction]", value: "DESC")))
    }

    func testTopLevelCreateStoredSkillPostsBody() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(self.payload(id: "new"))
        })
        let params = CreateStoredSkillParams(
            id: "new",
            name: "Echo",
            instructions: "Echo the input."
        )
        _ = try await client.createStoredSkill(params)
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/stored/skills")
        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["id"]?.stringValue, "new")
        XCTAssertEqual(body["name"]?.stringValue, "Echo")
        XCTAssertEqual(body["instructions"]?.stringValue, "Echo the input.")
    }

    func testTopLevelFactoryReturnsHandle() throws {
        let (client, _) = try makeClient()
        let handle = client.storedSkill(id: "sk-x")
        XCTAssertEqual(handle.storedSkillId, "sk-x")
    }
}
