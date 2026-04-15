import XCTest
@testable import Mastra
import MastraTestingSupport

final class ObservabilityTests: XCTestCase {
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

    // MARK: - getTrace

    func testGetTraceGetsObservabilityTraceById() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "traceId": "t-1",
                "name": "root",
                "spans": [],
            ])
        })
        let trace = try await client.observability.getTrace(traceId: "t-1")
        XCTAssertEqual(trace.traceId, "t-1")
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/observability/traces/t-1")
    }

    // MARK: - listTraces (flattened query params)

    func testListTracesFlattensFiltersPaginationAndOrderBy() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "pagination": ["total": 0, "page": 0, "perPage": 10, "hasMore": false],
                "traces": [],
            ])
        })
        var params = ListTracesArgs()
        params.pagination = .init(page: 1, perPage: 25)
        params.filters = .init(
            name: "agent_run",
            spanType: .agentRun,
            entityId: "e-1",
            entityType: "agent"
        )
        params.orderBy = .init(field: "startedAt", direction: .DESC)
        _ = try await client.observability.listTraces(params)

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/observability/traces")
        let names = req.query.map(\.name)
        // Flattened keys present
        XCTAssertTrue(names.contains("page"))
        XCTAssertTrue(names.contains("perPage"))
        XCTAssertTrue(names.contains("field"))
        XCTAssertTrue(names.contains("direction"))
        XCTAssertTrue(names.contains("name"))
        XCTAssertTrue(names.contains("spanType"))
        XCTAssertTrue(names.contains("entityId"))
        XCTAssertTrue(names.contains("entityType"))
        // Un-nested original keys must not survive.
        XCTAssertFalse(names.contains("pagination"))
        XCTAssertFalse(names.contains("filters"))
        XCTAssertFalse(names.contains("orderBy"))

        XCTAssertEqual(req.query.first(where: { $0.name == "field" })?.value, "startedAt")
        XCTAssertEqual(req.query.first(where: { $0.name == "direction" })?.value, "DESC")
        XCTAssertEqual(req.query.first(where: { $0.name == "spanType" })?.value, "agent_run")
    }

    // MARK: - listScoresBySpan (path-based)

    func testListScoresBySpanTargetsTraceAndSpanPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "pagination": ["total": 0, "page": 0, "perPage": 10, "hasMore": false],
                "scores": [],
            ])
        })
        let params = ListScoresBySpanParams(
            traceId: "t-abc",
            spanId: "s-def",
            page: 2,
            perPage: 5
        )
        _ = try await client.observability.listScoresBySpan(params)
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/observability/traces/t-abc/s-def/scores")
        XCTAssertEqual(req.query.first(where: { $0.name == "page" })?.value, "2")
        XCTAssertEqual(req.query.first(where: { $0.name == "perPage" })?.value, "5")
    }

    // MARK: - createFeedback (POST body)

    func testCreateFeedbackPostsJSONBodyToObservabilityFeedback() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["feedbackId": "fb-1"])
        })
        let body: JSONValue = .object([
            "traceId": .string("t-1"),
            "spanId": .string("s-1"),
            "rating": .int(5),
            "comment": .string("nice"),
        ])
        let resp = try await client.observability.createFeedback(CreateFeedbackBody(body))
        XCTAssertEqual(resp.feedbackId, "fb-1")

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/observability/feedback")
        let decoded = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(decoded["traceId"]?.stringValue, "t-1")
        XCTAssertEqual(decoded["rating"]?.intValue, 5)
    }

    // MARK: - metrics OLAP

    func testGetMetricAggregatePostsToMetricsAggregate() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["total": 42])
        })
        let body: JSONValue = .object([
            "metricName": .string("tokens"),
            "aggregator": .string("sum"),
        ])
        let resp = try await client.observability.getMetricAggregate(
            ObservabilityQueryBody(body)
        )
        XCTAssertEqual(resp.raw["total"]?.intValue, 42)

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/observability/metrics/aggregate")
        let sentBody = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(sentBody["metricName"]?.stringValue, "tokens")
    }

    // MARK: - discovery

    func testGetServiceNamesGetsDiscoveryPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["serviceNames": ["auth", "chat"]])
        })
        let resp = try await client.observability.getServiceNames()
        XCTAssertEqual(resp.serviceNames, ["auth", "chat"])
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/observability/discovery/service-names")
    }

    func testGetMetricLabelValuesPassesMetricNameAndLabelKeyQuery() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["values": ["staging", "prod"]])
        })
        let params = GetMetricLabelValuesArgs(
            metricName: "tokens",
            labelKey: "env",
            prefix: "pro"
        )
        let resp = try await client.observability.getMetricLabelValues(params)
        XCTAssertEqual(resp.values, ["staging", "prod"])
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.fullPath, "/api/observability/discovery/metric-label-values")
        XCTAssertEqual(req.query.first(where: { $0.name == "metricName" })?.value, "tokens")
        XCTAssertEqual(req.query.first(where: { $0.name == "labelKey" })?.value, "env")
        XCTAssertEqual(req.query.first(where: { $0.name == "prefix" })?.value, "pro")
    }

    // MARK: - score (fire-and-forget POST)

    func testScoreTracesPostsScorerNameAndTargets() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["status": "accepted", "message": "queued"])
        })
        let req = ScoreTracesRequest(
            scorerName: "usefulness",
            targets: [
                .init(traceId: "t-1"),
                .init(traceId: "t-2", spanId: "s-42"),
            ]
        )
        let resp = try await client.observability.score(req)
        XCTAssertEqual(resp.status, "accepted")

        let sent = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(sent.method, .POST)
        XCTAssertEqual(sent.fullPath, "/api/observability/traces/score")
        let body = try XCTUnwrap(self.decodeBody(sent))
        XCTAssertEqual(body["scorerName"]?.stringValue, "usefulness")
        XCTAssertEqual(body["targets"]?[0]?["traceId"]?.stringValue, "t-1")
        XCTAssertEqual(body["targets"]?[1]?["spanId"]?.stringValue, "s-42")
    }
}
