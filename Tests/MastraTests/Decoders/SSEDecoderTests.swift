import XCTest
@testable import Mastra
import MastraTestingSupport

final class SSEDecoderTests: XCTestCase {
    func testParsesMultilineDataAndEvents() async throws {
        let raw = "event: hello\ndata: line 1\ndata: line 2\n\ndata: solo\n\n"
        let bytes = MockTransport.bytes(raw)
        var events: [SSEEvent] = []
        for try await ev in SSEDecoder.events(from: bytes) { events.append(ev) }
        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(events[0].event, "hello")
        XCTAssertEqual(events[0].data, "line 1\nline 2")
        XCTAssertEqual(events[1].data, "solo")
    }

    func testIgnoresCommentsAndCarriageReturns() async throws {
        let raw = ": this is a comment\r\nevent: ping\r\ndata: pong\r\n\r\n"
        var events: [SSEEvent] = []
        for try await ev in SSEDecoder.events(from: MockTransport.bytes(raw)) { events.append(ev) }
        XCTAssertEqual(events.first?.event, "ping")
        XCTAssertEqual(events.first?.data, "pong")
    }
}
