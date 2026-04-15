import XCTest
@testable import Mastra
import MastraTestingSupport

final class ToolProviderTests: XCTestCase {
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

    // MARK: - client.listToolProviders

    func testListToolProvidersGetsRoot() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "providers": [
                    ["id": "composio", "name": "Composio", "description": "Toolkit provider"],
                    ["id": "local", "name": "Local"],
                ]
            ])
        })
        let response = try await client.listToolProviders()
        XCTAssertEqual(response.providers.count, 2)
        XCTAssertEqual(response.providers[0].id, "composio")
        XCTAssertEqual(response.providers[0].name, "Composio")
        XCTAssertEqual(response.providers[0].description, "Toolkit provider")
        XCTAssertEqual(response.providers[1].id, "local")
        XCTAssertNil(response.providers[1].description)

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/tool-providers")
    }

    // MARK: - client.toolProvider(id:) factory

    func testToolProviderHandleCaptureId() throws {
        let (client, _) = try makeClient()
        let provider = client.toolProvider(id: "composio")
        XCTAssertEqual(provider.providerId, "composio")
    }

    // MARK: - toolProvider.listToolkits

    func testListToolkitsGetsToolkitsPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "data": [
                    [
                        "slug": "github",
                        "name": "GitHub",
                        "description": "Git hosting",
                        "icon": "github.svg",
                    ]
                ],
                "pagination": [
                    "total": 1,
                    "page": 1,
                    "perPage": 20,
                    "hasMore": false,
                ],
            ])
        })
        let response = try await client.toolProvider(id: "composio").listToolkits()
        XCTAssertEqual(response.data.count, 1)
        XCTAssertEqual(response.data.first?.slug, "github")
        XCTAssertEqual(response.data.first?.icon, "github.svg")
        XCTAssertEqual(response.pagination?.hasMore, false)
        XCTAssertEqual(response.pagination?.total, 1)

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/tool-providers/composio/toolkits")
    }

    // MARK: - toolProvider.listTools

    func testListToolsWithoutParamsNoQuery() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["data": []])
        })
        _ = try await client.toolProvider(id: "composio").listTools()
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.fullPath, "/api/tool-providers/composio/tools")
        XCTAssertTrue(req.query.isEmpty)
    }

    func testListToolsIncludesAllQueryParams() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "data": [
                    [
                        "slug": "create-issue",
                        "name": "Create Issue",
                        "description": "Open a GitHub issue",
                        "toolkit": "github",
                    ]
                ],
                "pagination": ["hasMore": true, "page": 2, "perPage": 10],
            ])
        })
        let params = ListToolProviderToolsParams(
            toolkit: "github",
            search: "issue",
            page: 2,
            perPage: 10
        )
        let response = try await client.toolProvider(id: "composio").listTools(params)
        XCTAssertEqual(response.data.first?.slug, "create-issue")
        XCTAssertEqual(response.data.first?.toolkit, "github")
        XCTAssertEqual(response.pagination?.hasMore, true)

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.fullPath, "/api/tool-providers/composio/tools")
        let byName = Dictionary(uniqueKeysWithValues: req.query.map { ($0.name, $0.value) })
        XCTAssertEqual(byName["toolkit"] ?? nil, "github")
        XCTAssertEqual(byName["search"] ?? nil, "issue")
        XCTAssertEqual(byName["page"] ?? nil, "2")
        XCTAssertEqual(byName["perPage"] ?? nil, "10")
    }

    // MARK: - toolProvider.getToolSchema

    func testGetToolSchemaGetsSchemaPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "type": "object",
                "properties": ["title": ["type": "string"]],
            ])
        })
        let schema = try await client.toolProvider(id: "composio")
            .getToolSchema(toolSlug: "create-issue")
        XCTAssertEqual(schema["type"]?.stringValue, "object")
        XCTAssertEqual(schema["properties"]?["title"]?["type"]?.stringValue, "string")

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/tool-providers/composio/tools/create-issue/schema")
    }
}
