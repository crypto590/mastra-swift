import XCTest
@testable import Mastra

final class RequestContextTests: XCTestCase {
    func testEmptyContextProducesNoFragment() {
        XCTAssertEqual(RequestContext().queryFragment(), "")
    }

    func testBase64RoundTrip() throws {
        let ctx: RequestContext = ["userId": .string("abc-123"), "tier": .int(2)]
        let encoded = try XCTUnwrap(ctx.base64Encoded())
        let data = try XCTUnwrap(Data(base64Encoded: encoded))
        let decoded = try JSONDecoder().decode(JSONObject.self, from: data)
        XCTAssertEqual(decoded["userId"]?.stringValue, "abc-123")
        XCTAssertEqual(decoded["tier"]?.intValue, 2)
    }
}
