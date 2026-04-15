import Foundation

enum JSONPrinter {
    /// Renders any `Encodable` value as pretty JSON on stdout.
    static func print<T: Encodable>(_ value: T) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        do {
            let data = try encoder.encode(value)
            if let s = String(data: data, encoding: .utf8) {
                Swift.print(s)
            } else {
                Swift.print("<unprintable>")
            }
        } catch {
            Swift.print("<encode error: \(error)>")
        }
    }
}
