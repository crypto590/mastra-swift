import XCTest
@testable import Mastra
import MastraTestingSupport

final class MastraAgentStreamDecoderTests: XCTestCase {
    func testYieldsChunksAndStopsOnDoneSentinel() async throws {
        let raw = """
        data: {"type":"text-delta","value":"hi"}

        data: {"type":"text-delta","value":" there"}

        data: [DONE]

        data: {"type":"ignored-after-done"}

        """
        var chunks: [JSONValue] = []
        for try await chunk in MastraAgentStreamDecoder.chunks(from: MockTransport.bytes(raw)) {
            chunks.append(chunk)
        }
        XCTAssertEqual(chunks.count, 2)
        XCTAssertEqual(chunks[0]["type"]?.stringValue, "text-delta")
        XCTAssertEqual(chunks[1]["value"]?.stringValue, " there")
    }

    func testSkipsMalformedJSON() async throws {
        let raw = "data: not-json\n\ndata: {\"ok\":true}\n\n"
        var chunks: [JSONValue] = []
        for try await chunk in MastraAgentStreamDecoder.chunks(from: MockTransport.bytes(raw)) {
            chunks.append(chunk)
        }
        XCTAssertEqual(chunks.count, 1)
        XCTAssertEqual(chunks[0]["ok"]?.boolValue, true)
    }
}
