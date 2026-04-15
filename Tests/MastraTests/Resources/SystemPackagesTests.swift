import XCTest
@testable import Mastra
import MastraTestingSupport

final class SystemPackagesTests: XCTestCase {
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

    func testSystemPackagesGetsSystemPackagesPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "packages": [
                    ["name": "@mastra/core", "version": "1.2.3"],
                    ["name": "@mastra/client-js", "version": "0.9.0"],
                ],
                "isDev": true,
                "cmsEnabled": false,
                "storageType": "libsql",
                "observabilityStorageType": "postgres",
            ])
        })
        let response = try await client.systemPackages()
        XCTAssertEqual(response.packages.count, 2)
        XCTAssertEqual(response.packages.first?.name, "@mastra/core")
        XCTAssertEqual(response.packages.first?.version, "1.2.3")
        XCTAssertTrue(response.isDev)
        XCTAssertFalse(response.cmsEnabled)
        XCTAssertEqual(response.storageType, "libsql")
        XCTAssertEqual(response.observabilityStorageType, "postgres")

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/system/packages")
    }

    func testSystemPackagesDecodesWithOptionalFieldsAbsent() async throws {
        let (client, _) = try makeClient(handler: { _ in
            self.jsonResponse([
                "packages": [],
                "isDev": false,
                "cmsEnabled": true,
            ])
        })
        let response = try await client.systemPackages()
        XCTAssertTrue(response.packages.isEmpty)
        XCTAssertFalse(response.isDev)
        XCTAssertTrue(response.cmsEnabled)
        XCTAssertNil(response.storageType)
        XCTAssertNil(response.observabilityStorageType)
    }
}
