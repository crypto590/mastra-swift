import XCTest
@testable import Mastra
import MastraTestingSupport

final class ProcessorProviderTests: XCTestCase {
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

    // MARK: - client.processorProviders

    func testProcessorProvidersGetsRoot() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "providers": [
                    [
                        "id": "openai-moderation",
                        "name": "OpenAI Moderation",
                        "description": "Hosted safety checks",
                        "availablePhases": ["processInput", "processOutputResult"],
                    ],
                    [
                        "id": "local",
                        "name": "Local",
                        "availablePhases": ["processOutputStream"],
                    ],
                ]
            ])
        })
        let response = try await client.processorProviders()
        XCTAssertEqual(response.providers.count, 2)
        XCTAssertEqual(response.providers[0].id, "openai-moderation")
        XCTAssertEqual(response.providers[0].availablePhases, [.processInput, .processOutputResult])
        XCTAssertNil(response.providers[1].description)
        XCTAssertEqual(response.providers[1].availablePhases, [.processOutputStream])

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/processor-providers")
    }

    // MARK: - client.processorProvider(id:) factory

    func testProcessorProviderHandleCapturesId() throws {
        let (client, _) = try makeClient()
        let provider = client.processorProvider(id: "openai-moderation")
        XCTAssertEqual(provider.providerId, "openai-moderation")
    }

    // MARK: - processorProvider.details

    func testProcessorProviderDetailsGetsProviderPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "id": "openai-moderation",
                "name": "OpenAI Moderation",
                "description": "Hosted safety checks",
                "availablePhases": ["processInput", "processInputStep", "processOutputStep"],
                "configSchema": [
                    "type": "object",
                    "properties": [
                        "threshold": ["type": "number"],
                    ],
                ],
            ])
        })
        let details = try await client.processorProvider(id: "openai-moderation").details()
        XCTAssertEqual(details.id, "openai-moderation")
        XCTAssertEqual(details.name, "OpenAI Moderation")
        XCTAssertEqual(details.description, "Hosted safety checks")
        XCTAssertEqual(
            details.availablePhases,
            [.processInput, .processInputStep, .processOutputStep]
        )
        XCTAssertEqual(details.configSchema["type"]?.stringValue, "object")
        XCTAssertEqual(
            details.configSchema["properties"]?["threshold"]?["type"]?.stringValue,
            "number"
        )

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/processor-providers/openai-moderation")
    }
}
