import Foundation

/// Parses workflow run streams: chunks delimited by RS (`\x1E`) carrying JSON records.
/// Mirrors `Run.createChunkTransformStream` in the JS client.
public enum RecordSeparatorJSONDecoder {
    private static let rs: UInt8 = 0x1E

    public static func records<S: AsyncSequence & Sendable>(
        from bytes: S
    ) -> AsyncThrowingStream<JSONValue, Error> where S.Element == UInt8 {
        AsyncThrowingStream { continuation in
            let task = Task {
                var carry = Data()
                var pending = Data()
                let decoder = JSONDecoder()
                do {
                    for try await byte in bytes {
                        if byte == rs {
                            if !pending.isEmpty {
                                let combined = carry + pending
                                if let value = try? decoder.decode(JSONValue.self, from: combined) {
                                    continuation.yield(value)
                                    carry.removeAll()
                                } else {
                                    carry = combined
                                }
                                pending.removeAll()
                            }
                        } else {
                            pending.append(byte)
                        }
                    }
                    if !pending.isEmpty {
                        let combined = carry + pending
                        if let value = try? decoder.decode(JSONValue.self, from: combined) {
                            continuation.yield(value)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
