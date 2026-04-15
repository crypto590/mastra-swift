import XCTest
@testable import Mastra
import MastraTestingSupport

final class ToolTests: XCTestCase {
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

    // MARK: - tool.details

    func testToolDetailsGetsToolsPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "id": "calc",
                "description": "A calculator",
                "inputSchema": "{}",
                "outputSchema": "{}",
            ])
        })
        let tool = client.tool(id: "calc")
        let response = try await tool.details()
        XCTAssertEqual(response.id, "calc")
        XCTAssertEqual(response.description, "A calculator")
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/tools/calc")
    }

    func testToolDetailsAddsBase64RequestContextQuery() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "id": "calc",
                "description": "A calculator",
                "inputSchema": "{}",
                "outputSchema": "{}",
            ])
        })
        let tool = client.tool(id: "calc")
        _ = try await tool.details(requestContext: ["userId": .string("u1")])
        let req = try XCTUnwrap(mock.requests.first)
        let ctxItem = try XCTUnwrap(req.query.first(where: { $0.name == "requestContext" }))
        let encoded = try XCTUnwrap(ctxItem.value)
        let decoded = try XCTUnwrap(Data(base64Encoded: encoded))
        let json = try JSONDecoder().decode(JSONValue.self, from: decoded)
        XCTAssertEqual(json["userId"]?.stringValue, "u1")
    }

    // MARK: - tool.execute

    func testToolExecutePostsBodyAndRunIdQuery() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["ok": true])
        })
        let tool = client.tool(id: "calc")
        _ = try await tool.execute(
            data: .object(["x": .int(1), "y": .int(2)]),
            runId: "run-42",
            requestContext: ["userId": .string("u1")]
        )
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/tools/calc/execute")
        XCTAssertTrue(req.query.contains(.init(name: "runId", value: "run-42")))
        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["data"]?["x"]?.intValue, Int64(1))
        XCTAssertEqual(body["requestContext"]?["userId"]?.stringValue, "u1")
    }

    func testToolExecuteOmitsOptionalsWhenNil() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["ok": true])
        })
        let tool = client.tool(id: "calc")
        _ = try await tool.execute(data: .object(["x": .int(1)]))
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertFalse(req.query.contains(where: { $0.name == "runId" }))
        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertNil(body["requestContext"])
    }

    // MARK: - client.listTools

    func testListToolsGetsToolsRoot() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([:])
        })
        _ = try await client.listTools()
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/tools")
        XCTAssertFalse(req.query.contains(where: { $0.name == "requestContext" }))
    }

    func testListToolsBase64EncodesRequestContext() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([:])
        })
        _ = try await client.listTools(requestContext: ["userId": .string("u1")])
        let req = try XCTUnwrap(mock.requests.first)
        let ctxItem = try XCTUnwrap(req.query.first(where: { $0.name == "requestContext" }))
        let encoded = try XCTUnwrap(ctxItem.value)
        let decoded = try XCTUnwrap(Data(base64Encoded: encoded))
        let json = try JSONDecoder().decode(JSONValue.self, from: decoded)
        XCTAssertEqual(json["userId"]?.stringValue, "u1")
    }

    func testListToolsDecodesMap() async throws {
        let (client, _) = try makeClient(handler: { _ in
            self.jsonResponse([
                "calc": [
                    "id": "calc",
                    "description": "A calculator",
                    "inputSchema": "{}",
                    "outputSchema": "{}",
                ]
            ])
        })
        let map = try await client.listTools()
        XCTAssertEqual(map["calc"]?.id, "calc")
        XCTAssertEqual(map["calc"]?.description, "A calculator")
    }
}
