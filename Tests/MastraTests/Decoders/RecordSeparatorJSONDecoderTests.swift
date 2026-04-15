import XCTest
@testable import Mastra
import MastraTestingSupport

final class RecordSeparatorJSONDecoderTests: XCTestCase {
    func testParsesRecords() async throws {
        let raw = "{\"a\":1}\u{1E}{\"b\":2}\u{1E}"
        var values: [JSONValue] = []
        for try await v in RecordSeparatorJSONDecoder.records(from: MockTransport.bytes(raw)) {
            values.append(v)
        }
        XCTAssertEqual(values.count, 2)
        XCTAssertEqual(values[0]["a"]?.intValue, 1)
        XCTAssertEqual(values[1]["b"]?.intValue, 2)
    }

    func testCarriesIncompleteJSONAcrossSeparators() async throws {
        // First record is intentionally split before separator; the second separator completes nothing new.
        let raw = "{\"a\":\u{1E}1}\u{1E}"
        var values: [JSONValue] = []
        for try await v in RecordSeparatorJSONDecoder.records(from: MockTransport.bytes(raw)) {
            values.append(v)
        }
        XCTAssertEqual(values.count, 1)
        XCTAssertEqual(values[0]["a"]?.intValue, 1)
    }

    func testFinalRecordWithoutTrailingSeparator() async throws {
        let raw = "{\"x\":true}"
        var values: [JSONValue] = []
        for try await v in RecordSeparatorJSONDecoder.records(from: MockTransport.bytes(raw)) {
            values.append(v)
        }
        XCTAssertEqual(values.count, 1)
        XCTAssertEqual(values[0]["x"]?.boolValue, true)
    }
}
