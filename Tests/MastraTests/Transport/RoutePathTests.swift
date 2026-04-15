import XCTest
@testable import Mastra

final class RoutePathTests: XCTestCase {
    func testCollapsesAndPrefixes() throws {
        XCTAssertEqual(try RoutePath.normalize("//api///agents/"), "/api/agents")
        XCTAssertEqual(try RoutePath.normalize("agents"), "/agents")
        XCTAssertEqual(try RoutePath.normalize("/"), "")
        XCTAssertEqual(try RoutePath.normalize(""), "")
    }

    func testRejectsTraversalAndQueryAndFragment() {
        XCTAssertThrowsError(try RoutePath.normalize("/../etc/passwd"))
        XCTAssertThrowsError(try RoutePath.normalize("/agents?x=1"))
        XCTAssertThrowsError(try RoutePath.normalize("/agents#frag"))
    }
}
