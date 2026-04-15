import Foundation

/// Decodes agent / network streams produced by `processMastraStream` /
/// `processMastraNetworkStream` in the JS client. The wire format is SSE-shaped
/// (`data: <json>\n\n`) terminated by a `data: [DONE]` sentinel.
public enum MastraAgentStreamDecoder {
    public static func chunks<S: AsyncSequence & Sendable>(
        from bytes: S
    ) -> AsyncThrowingStream<JSONValue, Error> where S.Element == UInt8 {
        let events = SSEDecoder.events(from: bytes)
        return AsyncThrowingStream { continuation in
            let task = Task {
                let decoder = JSONDecoder()
                do {
                    for try await event in events {
                        let payload = event.data
                        if payload == "[DONE]" {
                            continuation.finish()
                            return
                        }
                        guard let data = payload.data(using: .utf8) else { continue }
                        do {
                            let value = try decoder.decode(JSONValue.self, from: data)
                            continuation.yield(value)
                        } catch {
                            // Mirror JS behavior: log and skip malformed chunks.
                            continue
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
