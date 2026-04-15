import Foundation

public struct SSEEvent: Sendable, Equatable {
    public var id: String?
    public var event: String?
    public var data: String
    public var retry: Int?
    public init(id: String? = nil, event: String? = nil, data: String, retry: Int? = nil) {
        self.id = id
        self.event = event
        self.data = data
        self.retry = retry
    }
}

/// Standard Server-Sent Events parser. Used by Responses and A2A.
/// Operates on raw UTF-8 bytes; splits on LF (0x0A) and decodes each line.
public enum SSEDecoder {
    private static let lf: UInt8 = 0x0A
    private static let cr: UInt8 = 0x0D

    public static func events<S: AsyncSequence & Sendable>(
        from bytes: S
    ) -> AsyncThrowingStream<SSEEvent, Error> where S.Element == UInt8 {
        AsyncThrowingStream { continuation in
            let task = Task {
                var buffer = Data()
                var current = SSEEvent(data: "")
                do {
                    for try await byte in bytes {
                        if byte == lf {
                            var line = buffer
                            if line.last == cr { line.removeLast() }
                            buffer.removeAll(keepingCapacity: true)
                            let lineStr = String(decoding: line, as: UTF8.self)
                            if lineStr.isEmpty {
                                if !current.data.isEmpty || current.event != nil || current.id != nil {
                                    if current.data.hasSuffix("\n") { current.data.removeLast() }
                                    continuation.yield(current)
                                }
                                current = SSEEvent(data: "")
                            } else if !lineStr.hasPrefix(":") {
                                let (field, value) = Self.splitField(lineStr)
                                switch field {
                                case "event": current.event = value
                                case "data": current.data += value + "\n"
                                case "id": current.id = value
                                case "retry": current.retry = Int(value)
                                default: break
                                }
                            }
                        } else {
                            buffer.append(byte)
                        }
                    }
                    if !current.data.isEmpty {
                        if current.data.hasSuffix("\n") { current.data.removeLast() }
                        continuation.yield(current)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private static func splitField(_ line: String) -> (String, String) {
        guard let colonIdx = line.firstIndex(of: ":") else { return (line, "") }
        let field = String(line[..<colonIdx])
        var value = String(line[line.index(after: colonIdx)...])
        if value.hasPrefix(" ") { value.removeFirst() }
        return (field, value)
    }
}
