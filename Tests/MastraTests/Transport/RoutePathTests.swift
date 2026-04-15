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

    func testEncodeURIComponentMatchesJSSemantics() {
        // Unreserved set — untouched.
        XCTAssertEqual(RoutePath.encodeURIComponent("abcABC012-_.!~*'()"), "abcABC012-_.!~*'()")
        // Slash must be escaped so an ID containing `/` becomes a single segment.
        XCTAssertEqual(RoutePath.encodeURIComponent("dataset/1"), "dataset%2F1")
        // Reserved characters that `.urlPathAllowed` would leave unescaped.
        XCTAssertEqual(RoutePath.encodeURIComponent("a&b=c?d#e"), "a%26b%3Dc%3Fd%23e")
        XCTAssertEqual(RoutePath.encodeURIComponent("a:b@c+d,e;f"), "a%3Ab%40c%2Bd%2Ce%3Bf")
        XCTAssertEqual(RoutePath.encodeURIComponent(" "), "%20")
    }
}
