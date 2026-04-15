import XCTest
@testable import Mastra
import MastraTestingSupport

final class ExperimentTests: XCTestCase {
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

    private func experimentJSON(id: String = "e1", datasetId: String = "d1") -> [String: Any] {
        [
            "id": id,
            "datasetId": datasetId,
            "datasetVersion": 1,
            "agentVersion": NSNull(),
            "targetType": "agent",
            "targetId": "agent-1",
            "status": "completed",
            "totalItems": 10,
            "succeededCount": 9,
            "failedCount": 1,
            "startedAt": "2025-01-01T00:00:00Z",
            "completedAt": "2025-01-01T00:01:00Z",
            "createdAt": "2025-01-01T00:00:00Z",
            "updatedAt": "2025-01-01T00:01:00Z",
        ]
    }

    private func experimentResultJSON(id: String = "r1", experimentId: String = "e1") -> [String: Any] {
        [
            "id": id,
            "experimentId": experimentId,
            "itemId": "item-1",
            "itemDatasetVersion": 1,
            "input": ["q": "hi"],
            "output": "hello",
            "groundTruth": "hello",
            "error": NSNull(),
            "startedAt": "2025-01-01T00:00:00Z",
            "completedAt": "2025-01-01T00:00:01Z",
            "retryCount": 0,
            "traceId": NSNull(),
            "status": "reviewed",
            "tags": ["clean"],
            "scores": [
                [
                    "scorerId": "s1",
                    "scorerName": "accuracy",
                    "score": 1.0,
                    "reason": "matched",
                    "error": NSNull(),
                ]
            ],
            "createdAt": "2025-01-01T00:00:00Z",
        ]
    }

    // MARK: - listExperiments

    func testListExperimentsIncludesPaginationQuery() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "experiments": [self.experimentJSON()],
                "pagination": ["total": 1, "page": 2, "perPage": 5, "hasMore": false],
            ])
        })
        let resp = try await client.listExperiments(page: 2, perPage: 5)
        XCTAssertEqual(resp.experiments.count, 1)
        XCTAssertEqual(resp.experiments.first?.targetType, .agent)
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/experiments")
        XCTAssertTrue(req.query.contains(.init(name: "page", value: "2")))
        XCTAssertTrue(req.query.contains(.init(name: "perPage", value: "5")))
    }

    // MARK: - experimentReviewSummary

    func testExperimentReviewSummaryGetsSummaryPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "counts": [
                    [
                        "experimentId": "e1",
                        "total": 10,
                        "needsReview": 2,
                        "reviewed": 5,
                        "complete": 3,
                    ]
                ]
            ])
        })
        let resp = try await client.experimentReviewSummary()
        XCTAssertEqual(resp.counts.count, 1)
        XCTAssertEqual(resp.counts.first?.needsReview, 2)
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/experiments/review-summary")
    }

    // MARK: - listDatasetExperiments

    func testListDatasetExperimentsPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "experiments": [self.experimentJSON()],
                "pagination": ["total": 1, "page": 1, "perPage": 10, "hasMore": false],
            ])
        })
        _ = try await client.listDatasetExperiments(datasetId: "d1")
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/datasets/d1/experiments")
    }

    // MARK: - getDatasetExperiment

    func testGetDatasetExperimentPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(self.experimentJSON(id: "e1", datasetId: "d1"))
        })
        let e = try await client.datasetExperiment(datasetId: "d1", experimentId: "e1")
        XCTAssertEqual(e.id, "e1")
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.fullPath, "/api/datasets/d1/experiments/e1")
    }

    // MARK: - listDatasetExperimentResults

    func testListDatasetExperimentResultsPaginated() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "results": [self.experimentResultJSON()],
                "pagination": ["total": 1, "page": 1, "perPage": 5, "hasMore": false],
            ])
        })
        let resp = try await client.listDatasetExperimentResults(
            datasetId: "d1",
            experimentId: "e1",
            page: 1,
            perPage: 5
        )
        XCTAssertEqual(resp.results.count, 1)
        XCTAssertEqual(resp.results[0].status, .reviewed)
        XCTAssertEqual(resp.results[0].scores.count, 1)
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/datasets/d1/experiments/e1/results")
        XCTAssertTrue(req.query.contains(.init(name: "page", value: "1")))
        XCTAssertTrue(req.query.contains(.init(name: "perPage", value: "5")))
    }

    // MARK: - updateExperimentResult / updateDatasetExperimentResult

    func testUpdateExperimentResultUsesPatch() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(self.experimentResultJSON())
        })
        let params = UpdateExperimentResultParams(
            datasetId: "d1",
            experimentId: "e1",
            resultId: "r1",
            status: .some(.reviewed),
            tags: ["good"]
        )
        _ = try await client.updateExperimentResult(params)
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .PATCH)
        XCTAssertEqual(req.fullPath, "/api/datasets/d1/experiments/e1/results/r1")
        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["status"]?.stringValue, "reviewed")
        XCTAssertEqual(body["tags"]?.arrayValue?.count, 1)
        XCTAssertNil(body["datasetId"])
        XCTAssertNil(body["experimentId"])
        XCTAssertNil(body["resultId"])
    }

    func testUpdateDatasetExperimentResultAliasUsesPatch() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(self.experimentResultJSON())
        })
        let params = UpdateExperimentResultParams(
            datasetId: "d1",
            experimentId: "e1",
            resultId: "r1",
            status: .some(nil) // clear
        )
        _ = try await client.updateDatasetExperimentResult(params)
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .PATCH)
        XCTAssertEqual(req.fullPath, "/api/datasets/d1/experiments/e1/results/r1")
        let body = try XCTUnwrap(self.decodeBody(req))
        // explicit-null status
        if case .null = body["status"] ?? .null {} else { XCTFail("expected null status") }
    }

    // MARK: - triggerDatasetExperiment

    func testTriggerDatasetExperimentPostsExpectedShape() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "experimentId": "e-new",
                "status": "pending",
                "totalItems": 0,
                "succeededCount": 0,
                "failedCount": 0,
                "startedAt": "2025-01-01T00:00:00Z",
                "completedAt": NSNull(),
                "results": [],
            ])
        })
        let params = TriggerDatasetExperimentParams(
            datasetId: "d1",
            targetType: .agent,
            targetId: "agent-1",
            scorerIds: ["s1"],
            version: 3,
            agentVersion: "v2",
            maxConcurrency: 4,
            requestContext: .object(["userId": .string("u1")])
        )
        let resp = try await client.triggerDatasetExperiment(params)
        XCTAssertEqual(resp.experimentId, "e-new")
        XCTAssertEqual(resp.status, .pending)
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/datasets/d1/experiments")
        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["targetType"]?.stringValue, "agent")
        XCTAssertEqual(body["targetId"]?.stringValue, "agent-1")
        XCTAssertEqual(body["scorerIds"]?.arrayValue?.count, 1)
        XCTAssertEqual(body["version"]?.intValue, 3)
        XCTAssertEqual(body["agentVersion"]?.stringValue, "v2")
        XCTAssertEqual(body["maxConcurrency"]?.intValue, 4)
        XCTAssertEqual(body["requestContext"]?["userId"]?.stringValue, "u1")
        XCTAssertNil(body["datasetId"])
    }

    // MARK: - compareExperiments

    func testCompareExperimentsPostsBodyShape() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "baselineId": "e1",
                "items": [
                    [
                        "itemId": "i1",
                        "input": "hi",
                        "groundTruth": "hello",
                        "results": [
                            "e1": ["output": "hello", "scores": ["acc": 1.0]],
                            "e2": NSNull(),
                        ],
                    ]
                ],
            ])
        })
        let params = CompareExperimentsParams(
            datasetId: "d1",
            experimentIdA: "e1",
            experimentIdB: "e2",
            thresholds: [
                "accuracy": CompareExperimentsParams.Threshold(
                    value: 0.1,
                    direction: .higherIsBetter
                )
            ]
        )
        let resp = try await client.compareExperiments(params)
        XCTAssertEqual(resp.baselineId, "e1")
        XCTAssertEqual(resp.items.count, 1)
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/datasets/d1/compare")
        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["experimentIdA"]?.stringValue, "e1")
        XCTAssertEqual(body["experimentIdB"]?.stringValue, "e2")
        XCTAssertEqual(body["thresholds"]?["accuracy"]?["value"]?.doubleValue, 0.1)
        XCTAssertEqual(
            body["thresholds"]?["accuracy"]?["direction"]?.stringValue,
            "higher-is-better"
        )
        XCTAssertNil(body["datasetId"])
    }
}
