import XCTest
@testable import Mastra
import MastraTestingSupport

final class LogsTests: XCTestCase {
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

    // MARK: - listLogs

    func testListLogsSerializesFiltersAsRepeatedKeyValueItems() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "logs": [],
                "total": 0,
                "page": 1,
                "perPage": 25,
                "hasMore": false,
            ])
        })
        let params = GetLogsParams(
            transportId: "console",
            logLevel: .info,
            filters: ["runId": "r-1", "component": "agent"],
            page: 1,
            perPage: 25
        )
        let resp = try await client.listLogs(params)
        XCTAssertEqual(resp.perPage, 25)

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/logs")

        XCTAssertEqual(req.query.first(where: { $0.name == "transportId" })?.value, "console")
        XCTAssertEqual(req.query.first(where: { $0.name == "logLevel" })?.value, "info")
        XCTAssertEqual(req.query.first(where: { $0.name == "page" })?.value, "1")
        XCTAssertEqual(req.query.first(where: { $0.name == "perPage" })?.value, "25")

        // The JS client emits one `filters` item per entry (key:value).
        let filtersValues = req.query.filter { $0.name == "filters" }.compactMap(\.value).sorted()
        XCTAssertEqual(filtersValues, ["component:agent", "runId:r-1"])
    }

    func testListLogsWithNoParamsOmitsQueryString() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "logs": [],
                "total": 0,
                "page": 0,
                "perPage": 0,
                "hasMore": false,
            ])
        })
        _ = try await client.listLogs()
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.fullPath, "/api/logs")
        XCTAssertTrue(req.query.isEmpty)
    }

    // MARK: - logForRun

    func testLogForRunTargetsLogsByRunIdAndIncludesRunIdQuery() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "logs": [],
                "total": 0,
                "page": 0,
                "perPage": 0,
                "hasMore": false,
            ])
        })
        let params = GetLogParams(
            runId: "run-xyz",
            transportId: "console",
            logLevel: .error,
            filters: ["tag": "v1"],
            page: 2,
            perPage: 10
        )
        _ = try await client.logForRun(params)
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/logs/run-xyz")
        XCTAssertEqual(req.query.first(where: { $0.name == "runId" })?.value, "run-xyz")
        XCTAssertEqual(req.query.first(where: { $0.name == "transportId" })?.value, "console")
        XCTAssertEqual(req.query.first(where: { $0.name == "logLevel" })?.value, "error")
        XCTAssertEqual(req.query.first(where: { $0.name == "page" })?.value, "2")
        XCTAssertEqual(req.query.first(where: { $0.name == "perPage" })?.value, "10")
        XCTAssertEqual(req.query.first(where: { $0.name == "filters" })?.value, "tag:v1")
    }

    // MARK: - listLogTransports

    func testListLogTransportsGetsLogsTransports() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["transports": ["console", "file"]])
        })
        let resp = try await client.listLogTransports()
        XCTAssertEqual(resp.transports, ["console", "file"])

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/logs/transports")
    }
}
