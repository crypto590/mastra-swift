import XCTest
@testable import Mastra
import MastraTestingSupport

final class ScorersTests: XCTestCase {
    private func makeClient(
        handler: @escaping MockTransport.Handler
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

    // MARK: - listScorers

    func testListScorersReturnsMapOfScorers() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "tone": [
                    "agentIds": ["a1"],
                    "agentNames": ["Alpha"],
                    "workflowIds": [],
                    "isRegistered": true,
                    "source": "code",
                    "scorer": ["id": "tone"],
                ]
            ])
        })
        let scorers = try await client.listScorers()
        XCTAssertEqual(scorers["tone"]?.agentIds, ["a1"])
        XCTAssertEqual(scorers["tone"]?.source, .code)
        XCTAssertTrue(scorers["tone"]?.isRegistered ?? false)

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/scores/scorers")
    }

    // MARK: - getScorer

    func testGetScorerEncodesScorerIdInPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "agentIds": [],
                "agentNames": [],
                "workflowIds": [],
                "isRegistered": false,
                "source": "stored",
            ])
        })
        _ = try await client.scorer(id: "scorer with spaces")
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/scores/scorers/scorer%20with%20spaces")
    }

    // MARK: - listScoresByRunId

    func testListScoresByRunIdIncludesPagination() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "pagination": ["total": 0, "page": 1, "perPage": 5, "hasMore": false],
                "scores": [],
            ])
        })
        _ = try await client.listScoresByRunId(
            ListScoresByRunIdParams(runId: "run-1", page: 1, perPage: 5)
        )
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/scores/run/run-1")
        XCTAssertEqual(req.query.first(where: { $0.name == "page" })?.value, "1")
        XCTAssertEqual(req.query.first(where: { $0.name == "perPage" })?.value, "5")
    }

    func testListScoresByScorerIdAddsEntityFilters() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "pagination": ["total": 0, "page": 0, "perPage": 10, "hasMore": false],
                "scores": [],
            ])
        })
        _ = try await client.listScoresByScorerId(
            ListScoresByScorerIdParams(
                scorerId: "tone",
                entityId: "agent-9",
                entityType: "agent"
            )
        )
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.fullPath, "/api/scores/scorer/tone")
        XCTAssertEqual(req.query.first(where: { $0.name == "entityId" })?.value, "agent-9")
        XCTAssertEqual(req.query.first(where: { $0.name == "entityType" })?.value, "agent")
    }

    func testListScoresByEntityIdUsesEntityTypeAndIdInPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "pagination": ["total": 0, "page": 0, "perPage": 10, "hasMore": false],
                "scores": [],
            ])
        })
        _ = try await client.listScoresByEntityId(
            ListScoresByEntityIdParams(entityId: "e-1", entityType: "workflow", page: 0, perPage: 10)
        )
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.fullPath, "/api/scores/entity/workflow/e-1")
    }

    // MARK: - saveScore POST shape

    func testSaveScoreWrapsPayloadInScoreKey() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "score": [
                    "id": "sc-1",
                    "createdAt": "2025-01-01T00:00:00.000Z",
                    "updatedAt": "2025-01-01T00:00:00.000Z",
                ]
            ])
        })
        let score: JSONValue = .object([
            "score": .double(0.9),
            "scorerId": .string("tone"),
            "entityId": .string("agent-1"),
            "entityType": .string("agent"),
        ])
        let resp = try await client.saveScore(SaveScoreParams(score: score))
        XCTAssertEqual(resp.score.id, "sc-1")

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/scores")
        let body = try XCTUnwrap(self.decodeBody(req))
        // Body must be wrapped under `score`.
        XCTAssertEqual(body["score"]?["scorerId"]?.stringValue, "tone")
        XCTAssertEqual(body["score"]?["score"]?.doubleValue, 0.9)
    }
}
