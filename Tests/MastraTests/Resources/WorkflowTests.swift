import XCTest
@testable import Mastra
import MastraTestingSupport

final class WorkflowTests: XCTestCase {
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

    // MARK: - details

    func testDetailsUsesGetOnWorkflowsPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "name": "my-workflow",
                "description": "does things",
            ])
        })
        let workflow = client.workflow(id: "wf-1")
        let info = try await workflow.details()
        XCTAssertEqual(info.name, "my-workflow")
        XCTAssertEqual(info.description, "does things")
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/workflows/wf-1")
    }

    // MARK: - runs

    func testRunsAppliesQueryParams() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["runs": []])
        })
        let workflow = client.workflow(id: "wf-q")
        _ = try await workflow.runs(
            ListWorkflowRunsParams(
                page: 2,
                perPage: 25,
                resourceId: "res-1",
                status: .running
            )
        )
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/workflows/wf-q/runs")
        XCTAssertTrue(req.query.contains(.init(name: "page", value: "2")))
        XCTAssertTrue(req.query.contains(.init(name: "perPage", value: "25")))
        XCTAssertTrue(req.query.contains(.init(name: "resourceId", value: "res-1")))
        XCTAssertTrue(req.query.contains(.init(name: "status", value: "running")))
    }

    func testRunByIdAppliesFieldsAndNestedQuery() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["runId": "r1"])
        })
        let workflow = client.workflow(id: "wf-r")
        _ = try await workflow.runById(
            "r1",
            options: WorkflowRunByIdOptions(
                fields: ["result", "steps"],
                withNestedWorkflows: false
            )
        )
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.fullPath, "/api/workflows/wf-r/runs/r1")
        XCTAssertTrue(req.query.contains(.init(name: "fields", value: "result,steps")))
        XCTAssertTrue(req.query.contains(.init(name: "withNestedWorkflows", value: "false")))
    }

    func testDeleteRunByIdSendsDelete() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["message": "ok"])
        })
        let workflow = client.workflow(id: "wf-d")
        let resp = try await workflow.deleteRunById("run-99")
        XCTAssertEqual(resp.message, "ok")
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .DELETE)
        XCTAssertEqual(req.fullPath, "/api/workflows/wf-d/runs/run-99")
    }

    // MARK: - createRun

    func testCreateRunPostsShapeAndReturnsRun() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["runId": "run-1"])
        })
        let workflow = client.workflow(id: "wf-c")
        let run = try await workflow.createRun(
            CreateRunParams(
                runId: "run-1",
                resourceId: "res-a",
                disableScorers: true
            )
        )
        XCTAssertEqual(run.runId, "run-1")
        XCTAssertEqual(run.workflowId, "wf-c")

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/workflows/wf-c/create-run")
        XCTAssertTrue(req.query.contains(.init(name: "runId", value: "run-1")))

        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["resourceId"]?.stringValue, "res-a")
        XCTAssertEqual(body["disableScorers"]?.boolValue, true)
    }

    // MARK: - getSchema

    func testGetSchemaParsesEmbeddedJSONStrings() async throws {
        let (client, _) = try makeClient(handler: { _ in
            self.jsonResponse([
                "name": "wf-s",
                "inputSchema": "{\"type\":\"object\"}",
                "outputSchema": "{\"type\":\"string\"}",
            ])
        })
        let workflow = client.workflow(id: "wf-s")
        let schema = try await workflow.getSchema()
        XCTAssertEqual(schema.inputSchema?["type"]?.stringValue, "object")
        XCTAssertEqual(schema.outputSchema?["type"]?.stringValue, "string")
    }

    // MARK: - top-level listWorkflows

    func testListWorkflowsPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([:])
        })
        _ = try await client.listWorkflows()
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.fullPath, "/api/workflows")
    }

    func testListWorkflowsPartialAddsQuery() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([:])
        })
        _ = try await client.listWorkflows(partial: true)
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertTrue(req.query.contains(.init(name: "partial", value: "true")))
    }
}
