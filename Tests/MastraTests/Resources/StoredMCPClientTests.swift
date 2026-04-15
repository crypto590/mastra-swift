import XCTest
@testable import Mastra
import MastraTestingSupport

final class StoredMCPClientTests: XCTestCase {
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

    private func payload(id: String = "mc1") -> [String: Any] {
        [
            "id": id,
            "status": "published",
            "createdAt": "2025-01-01T00:00:00Z",
            "updatedAt": "2025-01-01T00:00:00Z",
            "name": "Local",
            "servers": [
                "local": ["type": "stdio", "command": "node"],
            ],
        ]
    }

    // MARK: - details

    func testDetailsGetsPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(self.payload())
        })
        let out = try await client.storedMCPClient(id: "mc1").details()
        XCTAssertEqual(out.id, "mc1")
        XCTAssertEqual(out.servers["local"]?.type, .stdio)
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/stored/mcp-clients/mc1")
    }

    // MARK: - update

    func testUpdatePatchesWithServers() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(self.payload())
        })
        let params = UpdateStoredMCPClientParams(
            name: "Renamed",
            servers: [
                "remote": StoredMCPServerConfig(type: .http, url: "https://example.com/mcp"),
            ]
        )
        _ = try await client.storedMCPClient(id: "mc1").update(params)
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .PATCH)
        XCTAssertEqual(req.fullPath, "/api/stored/mcp-clients/mc1")
        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["name"]?.stringValue, "Renamed")
        let servers = try XCTUnwrap(body["servers"]?.objectValue)
        XCTAssertEqual(servers["remote"]?["type"]?.stringValue, "http")
        XCTAssertEqual(servers["remote"]?["url"]?.stringValue, "https://example.com/mcp")
    }

    // MARK: - delete

    func testDeleteSendsDelete() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["success": true, "message": "ok"])
        })
        let out = try await client.storedMCPClient(id: "mc1").delete()
        XCTAssertTrue(out.success)
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .DELETE)
        XCTAssertEqual(req.fullPath, "/api/stored/mcp-clients/mc1")
    }

    // MARK: - top-level list / create / get

    func testTopLevelListStoredMCPClients() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "mcpClients": [],
                "total": 0,
                "page": 1,
                "hasMore": false,
            ])
        })
        _ = try await client.listStoredMCPClients(
            ListStoredMCPClientsParams(page: 1, perPage: 50)
        )
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.fullPath, "/api/stored/mcp-clients")
        XCTAssertTrue(req.query.contains(.init(name: "page", value: "1")))
        XCTAssertTrue(req.query.contains(.init(name: "perPage", value: "50")))
    }

    func testTopLevelCreateStoredMCPClientPostsBody() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(self.payload(id: "new"))
        })
        let params = CreateStoredMCPClientParams(
            name: "Local",
            servers: [
                "local": StoredMCPServerConfig(
                    type: .stdio,
                    command: "node",
                    args: ["server.js"],
                    env: ["DEBUG": "1"]
                ),
            ]
        )
        _ = try await client.createStoredMCPClient(params)
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/stored/mcp-clients")
        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["name"]?.stringValue, "Local")
        let servers = try XCTUnwrap(body["servers"]?.objectValue)
        let local = try XCTUnwrap(servers["local"]?.objectValue)
        XCTAssertEqual(local["type"]?.stringValue, "stdio")
        XCTAssertEqual(local["command"]?.stringValue, "node")
        XCTAssertEqual(local["args"]?[0]?.stringValue, "server.js")
        XCTAssertEqual(local["env"]?["DEBUG"]?.stringValue, "1")
    }

    func testTopLevelFactoryReturnsHandle() throws {
        let (client, _) = try makeClient()
        let handle = client.storedMCPClient(id: "mc-x")
        XCTAssertEqual(handle.storedMCPClientId, "mc-x")
    }
}
