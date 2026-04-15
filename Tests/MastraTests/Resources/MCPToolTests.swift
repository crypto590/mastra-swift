import XCTest
@testable import Mastra
import MastraTestingSupport

final class MCPToolTests: XCTestCase {
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

    // MARK: - MCPTool.details

    func testMCPToolDetailsGetsMcpToolsPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "id": "tool-1",
                "name": "adder",
                "description": "Adds two numbers",
                "inputSchema": "{\"type\":\"object\"}",
            ])
        })
        let tool = client.mcpServerTool(serverId: "srv-1", toolId: "tool-1")
        let info = try await tool.details()
        XCTAssertEqual(info.id, "tool-1")
        XCTAssertEqual(info.name, "adder")
        XCTAssertEqual(info.description, "Adds two numbers")
        XCTAssertEqual(info.inputSchema, "{\"type\":\"object\"}")

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/mcp/srv-1/tools/tool-1")
        XCTAssertFalse(req.query.contains(where: { $0.name == "requestContext" }))
    }

    func testMCPToolDetailsEncodesRequestContext() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "id": "tool-1",
                "name": "adder",
                "inputSchema": "{}",
            ])
        })
        let tool = client.mcpServerTool(serverId: "srv-1", toolId: "tool-1")
        _ = try await tool.details(requestContext: ["userId": .string("u1")])

        let req = try XCTUnwrap(mock.requests.first)
        let ctxItem = try XCTUnwrap(req.query.first(where: { $0.name == "requestContext" }))
        let encoded = try XCTUnwrap(ctxItem.value)
        let decoded = try XCTUnwrap(Data(base64Encoded: encoded))
        let json = try JSONDecoder().decode(JSONValue.self, from: decoded)
        XCTAssertEqual(json["userId"]?.stringValue, "u1")
    }

    // MARK: - MCPTool.execute

    func testMCPToolExecutePostsDataAndRequestContext() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["ok": true])
        })
        let tool = client.mcpServerTool(serverId: "srv-1", toolId: "tool-1")
        _ = try await tool.execute(
            data: .object(["x": .int(1), "y": .int(2)]),
            requestContext: ["userId": .string("u1")]
        )

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/mcp/srv-1/tools/tool-1/execute")
        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["data"]?["x"]?.intValue, Int64(1))
        XCTAssertEqual(body["data"]?["y"]?.intValue, Int64(2))
        XCTAssertEqual(body["requestContext"]?["userId"]?.stringValue, "u1")
    }

    func testMCPToolExecuteOmitsBodyWhenNoParamsProvided() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["ok": true])
        })
        let tool = client.mcpServerTool(serverId: "srv-1", toolId: "tool-1")
        _ = try await tool.execute()

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/mcp/srv-1/tools/tool-1/execute")
        XCTAssertNil(req.body, "Body must be nil when neither data nor requestContext is set (matches JS).")
    }

    func testMCPToolExecuteIncludesOnlyDataWhenRequestContextOmitted() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["ok": true])
        })
        let tool = client.mcpServerTool(serverId: "srv-1", toolId: "tool-1")
        _ = try await tool.execute(data: .object(["x": .int(1)]))

        let req = try XCTUnwrap(mock.requests.first)
        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["data"]?["x"]?.intValue, Int64(1))
        XCTAssertNil(body["requestContext"])
    }

    // MARK: - client.mcpServers

    func testMcpServersGetsServersRoot() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "servers": [],
                "next": NSNull(),
                "total_count": 0,
            ])
        })
        let result = try await client.mcpServers()
        XCTAssertEqual(result.total_count, 0)
        XCTAssertTrue(result.servers.isEmpty)

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/mcp/v0/servers")
        XCTAssertTrue(req.query.isEmpty)
    }

    func testMcpServersForwardsPaginationQuery() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "servers": [],
                "next": NSNull(),
                "total_count": 0,
            ])
        })
        _ = try await client.mcpServers(page: 0, perPage: 1, limit: 25, offset: 10)

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.fullPath, "/api/mcp/v0/servers")
        XCTAssertTrue(req.query.contains(.init(name: "page", value: "0")))
        XCTAssertTrue(req.query.contains(.init(name: "perPage", value: "1")))
        XCTAssertTrue(req.query.contains(.init(name: "limit", value: "25")))
        XCTAssertTrue(req.query.contains(.init(name: "offset", value: "10")))
    }

    func testMcpServersDecodesResponseEnvelope() async throws {
        let (client, _) = try makeClient(handler: { _ in
            self.jsonResponse([
                "servers": [
                    [
                        "id": "srv-1",
                        "name": "Example",
                        "version_detail": [
                            "version": "1.0.0",
                            "release_date": "2023-01-01T00:00:00Z",
                            "is_latest": true,
                        ] as [String: Any],
                    ] as [String: Any]
                ],
                "next": "/api/mcp/v0/servers?page=1",
                "total_count": 1,
            ])
        })
        let response = try await client.mcpServers()
        XCTAssertEqual(response.total_count, 1)
        XCTAssertEqual(response.next, "/api/mcp/v0/servers?page=1")
        XCTAssertEqual(response.servers.first?.id, "srv-1")
        XCTAssertEqual(response.servers.first?.version_detail?.version, "1.0.0")
        XCTAssertEqual(response.servers.first?.version_detail?.is_latest, true)
    }

    // MARK: - client.mcpServer (details)

    func testMcpServerDetailsGetsServerPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "id": "srv-1",
                "name": "Example",
                "description": "Detailed",
            ])
        })
        let detail = try await client.mcpServer(id: "srv-1")
        XCTAssertEqual(detail.id, "srv-1")
        XCTAssertEqual(detail.description, "Detailed")

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/mcp/v0/servers/srv-1")
        XCTAssertFalse(req.query.contains(where: { $0.name == "version" }))
    }

    func testMcpServerDetailsForwardsVersionQuery() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "id": "srv-1",
                "name": "Example",
            ])
        })
        _ = try await client.mcpServer(id: "srv-1", version: "1.0.0")

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.fullPath, "/api/mcp/v0/servers/srv-1")
        XCTAssertTrue(req.query.contains(.init(name: "version", value: "1.0.0")))
    }

    // MARK: - client.mcpServerTools

    func testMcpServerToolsGetsToolsPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "tools": [
                    ["name": "tool1", "description": "First tool"],
                    ["name": "tool2", "description": "Second tool"],
                ]
            ])
        })
        let response = try await client.mcpServerTools(serverId: "srv-1")
        XCTAssertEqual(response.tools.count, 2)
        XCTAssertEqual(response.tools.first?.name, "tool1")

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/mcp/srv-1/tools")
    }

    // MARK: - client.mcpServerTool

    func testMcpServerToolReturnsHandle() throws {
        let (client, _) = try makeClient()
        let tool = client.mcpServerTool(serverId: "srv-1", toolId: "tool-1")
        XCTAssertEqual(tool.serverId, "srv-1")
        XCTAssertEqual(tool.toolId, "tool-1")
    }
}
