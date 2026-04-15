import XCTest
@testable import Mastra

/// Validates the schema and self-consistency of `parity-manifest.json`.
/// In Phase 2+ this expands to compare the manifest against a snapshot of the
/// upstream JS public surface.
final class ParityManifestTests: XCTestCase {
    func testManifestExistsAndIsWellFormed() throws {
        let url = manifestURL()
        let data = try Data(contentsOf: url)
        let json = try JSONDecoder().decode(JSONValue.self, from: data)
        XCTAssertNotNil(json["upstream"]?["gitCommit"]?.stringValue, "Manifest must pin a git commit")
        XCTAssertNotNil(json["upstream"]?["npmVersion"]?.stringValue, "Manifest must pin an npm version")
        XCTAssertNotNil(json["resources"]?.objectValue, "Manifest must declare resources")
        XCTAssertNotNil(json["exceptions"]?.arrayValue, "Manifest must declare exceptions (even if empty)")
    }

    func testEveryExceptionHasReasonAndJSSymbol() throws {
        let data = try Data(contentsOf: manifestURL())
        let json = try JSONDecoder().decode(JSONValue.self, from: data)
        let exceptions = json["exceptions"]?.arrayValue ?? []
        for entry in exceptions {
            XCTAssertNotNil(entry["jsSymbol"]?.stringValue, "exception missing jsSymbol")
            XCTAssertNotNil(entry["reason"]?.stringValue, "exception missing reason")
        }
    }

    private func manifestURL() -> URL {
        // Walk up from this file until we find parity-manifest.json
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<6 {
            url.deleteLastPathComponent()
            let candidate = url.appendingPathComponent("parity-manifest.json")
            if FileManager.default.fileExists(atPath: candidate.path) { return candidate }
        }
        return URL(fileURLWithPath: "parity-manifest.json")
    }
}
