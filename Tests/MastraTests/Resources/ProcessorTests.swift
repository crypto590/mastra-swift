import XCTest
@testable import Mastra
import MastraTestingSupport

final class ProcessorTests: XCTestCase {
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

    // MARK: - processor.details

    func testProcessorDetailsGetsProcessorsPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "id": "guard",
                "name": "Safety Guard",
                "phases": ["input", "outputResult"],
                "configurations": [
                    ["agentId": "a1", "agentName": "Alpha", "type": "input"]
                ],
                "isWorkflow": false,
            ])
        })
        let processor = client.processor(id: "guard")
        let details = try await processor.details()
        XCTAssertEqual(details.id, "guard")
        XCTAssertEqual(details.name, "Safety Guard")
        XCTAssertEqual(details.phases, [.input, .outputResult])
        XCTAssertEqual(details.configurations.first?.agentId, "a1")
        XCTAssertEqual(details.configurations.first?.type, .input)
        XCTAssertFalse(details.isWorkflow)
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/processors/guard")
    }

    func testProcessorDetailsAddsBase64RequestContext() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "id": "guard",
                "phases": [],
                "configurations": [],
                "isWorkflow": false,
            ])
        })
        let processor = client.processor(id: "guard")
        _ = try await processor.details(requestContext: ["tenant": .string("acme")])
        let req = try XCTUnwrap(mock.requests.first)
        let ctxItem = try XCTUnwrap(req.query.first(where: { $0.name == "requestContext" }))
        let encoded = try XCTUnwrap(ctxItem.value)
        let decoded = try XCTUnwrap(Data(base64Encoded: encoded))
        let json = try JSONDecoder().decode(JSONValue.self, from: decoded)
        XCTAssertEqual(json["tenant"]?.stringValue, "acme")
    }

    // MARK: - processor.execute

    func testProcessorExecutePostsBody() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "success": true,
                "phase": "input",
            ])
        })
        let processor = client.processor(id: "guard")
        let params = ExecuteProcessorParams(
            phase: .input,
            messages: .array([
                .object(["role": .string("user"), "content": .string("hi")])
            ]),
            agentId: "a1",
            requestContext: ["tenant": .string("acme")]
        )
        let response = try await processor.execute(params)
        XCTAssertTrue(response.success)
        XCTAssertEqual(response.phase, "input")

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/processors/guard/execute")
        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["phase"]?.stringValue, "input")
        XCTAssertEqual(body["agentId"]?.stringValue, "a1")
        XCTAssertNotNil(body["messages"]?.arrayValue)
        XCTAssertEqual(body["requestContext"]?["tenant"]?.stringValue, "acme")
    }

    // MARK: - client.listProcessors

    func testListProcessorsGetsProcessorsRoot() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([:])
        })
        _ = try await client.listProcessors()
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/processors")
        XCTAssertFalse(req.query.contains(where: { $0.name == "requestContext" }))
    }

    func testListProcessorsBase64EncodesRequestContext() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([:])
        })
        _ = try await client.listProcessors(requestContext: ["tenant": .string("acme")])
        let req = try XCTUnwrap(mock.requests.first)
        let ctxItem = try XCTUnwrap(req.query.first(where: { $0.name == "requestContext" }))
        let encoded = try XCTUnwrap(ctxItem.value)
        let decoded = try XCTUnwrap(Data(base64Encoded: encoded))
        let json = try JSONDecoder().decode(JSONValue.self, from: decoded)
        XCTAssertEqual(json["tenant"]?.stringValue, "acme")
    }

    func testListProcessorsDecodesMap() async throws {
        let (client, _) = try makeClient(handler: { _ in
            self.jsonResponse([
                "guard": [
                    "id": "guard",
                    "phases": ["input"],
                    "agentIds": ["a1", "a2"],
                    "isWorkflow": false,
                ]
            ])
        })
        let map = try await client.listProcessors()
        let entry = try XCTUnwrap(map["guard"])
        XCTAssertEqual(entry.id, "guard")
        XCTAssertEqual(entry.phases, [.input])
        XCTAssertEqual(entry.agentIds, ["a1", "a2"])
        XCTAssertFalse(entry.isWorkflow)
    }
}
