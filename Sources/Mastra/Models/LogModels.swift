import Foundation

// MARK: - Log level

/// Mirrors JS `LogLevel` from `@mastra/core/logger`. The open-ended string
/// form preserves forward compatibility with custom levels while exposing the
/// well-known pino levels as convenience statics.
public struct LogLevel: RawRepresentable, Sendable, Hashable, Codable, ExpressibleByStringLiteral {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.rawValue = value }

    public static let debug: LogLevel = "debug"
    public static let info: LogLevel = "info"
    public static let warn: LogLevel = "warn"
    public static let error: LogLevel = "error"
    public static let trace: LogLevel = "trace"
    public static let fatal: LogLevel = "fatal"
    public static let silent: LogLevel = "silent"
}

// MARK: - Log message

/// Mirrors JS `BaseLogMessage` (from `@mastra/core/logger`). The fields that
/// flow through pino's serializers are open-shaped so we keep them as
/// `JSONValue` to match what the JS client exposes.
public struct BaseLogMessage: Sendable, Codable {
    public let level: JSONValue?
    public let time: JSONValue?
    public let msg: String?
    public let message: String?
    public let runId: String?
    public let name: String?
    public let hostname: String?
    public let pid: JSONValue?

    /// Remaining fields the server attaches (e.g. `err`, `context`, `req`,
    /// `res`). Captured so callers can inspect the full log record.
    public let extra: JSONValue

    private static let knownKeys: Set<String> = [
        "level", "time", "msg", "message", "runId", "name", "hostname", "pid",
    ]

    private struct DynamicKey: CodingKey {
        let stringValue: String
        let intValue: Int? = nil
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: DynamicKey.self)
        func value(_ name: String) -> JSONValue? {
            guard let key = DynamicKey(stringValue: name) else { return nil }
            return try? c.decode(JSONValue.self, forKey: key)
        }
        self.level = value("level")
        self.time = value("time")
        self.msg = (value("msg")?.stringValue)
        self.message = (value("message")?.stringValue)
        self.runId = (value("runId")?.stringValue)
        self.name = (value("name")?.stringValue)
        self.hostname = (value("hostname")?.stringValue)
        self.pid = value("pid")

        var extra: JSONObject = [:]
        for key in c.allKeys where !Self.knownKeys.contains(key.stringValue) {
            if let v = try? c.decode(JSONValue.self, forKey: key) {
                extra[key.stringValue] = v
            }
        }
        self.extra = .object(extra)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: DynamicKey.self)
        func write(_ name: String, _ value: JSONValue?) throws {
            guard let value, let key = DynamicKey(stringValue: name) else { return }
            try c.encode(value, forKey: key)
        }
        try write("level", level)
        try write("time", time)
        if let msg, let k = DynamicKey(stringValue: "msg") { try c.encode(msg, forKey: k) }
        if let message, let k = DynamicKey(stringValue: "message") { try c.encode(message, forKey: k) }
        if let runId, let k = DynamicKey(stringValue: "runId") { try c.encode(runId, forKey: k) }
        if let name, let k = DynamicKey(stringValue: "name") { try c.encode(name, forKey: k) }
        if let hostname, let k = DynamicKey(stringValue: "hostname") { try c.encode(hostname, forKey: k) }
        try write("pid", pid)

        if case .object(let obj) = extra {
            for (k, v) in obj {
                if let key = DynamicKey(stringValue: k) { try c.encode(v, forKey: key) }
            }
        }
    }

    public init(
        level: JSONValue? = nil,
        time: JSONValue? = nil,
        msg: String? = nil,
        message: String? = nil,
        runId: String? = nil,
        name: String? = nil,
        hostname: String? = nil,
        pid: JSONValue? = nil,
        extra: JSONValue = .object([:])
    ) {
        self.level = level
        self.time = time
        self.msg = msg
        self.message = message
        self.runId = runId
        self.name = name
        self.hostname = hostname
        self.pid = pid
        self.extra = extra
    }
}

// MARK: - Paginated responses

/// Mirrors JS `GetLogsResponse` — the legacy pagination shape.
public struct GetLogsResponse: Sendable, Codable {
    public let logs: [BaseLogMessage]
    public let total: Int
    public let page: Int
    public let perPage: Int
    public let hasMore: Bool

    public init(
        logs: [BaseLogMessage],
        total: Int,
        page: Int,
        perPage: Int,
        hasMore: Bool
    ) {
        self.logs = logs
        self.total = total
        self.page = page
        self.perPage = perPage
        self.hasMore = hasMore
    }
}

// MARK: - Query params

/// Mirrors JS `GetLogsParams` (top-level `client.listLogs`).
///
/// Note: `filters` is serialized as repeated `filters=key:value` query items
/// (matches JS `searchParams.append('filters', filter)`).
public struct GetLogsParams: Sendable {
    public var transportId: String?
    public var fromDate: Date?
    public var toDate: Date?
    public var logLevel: LogLevel?
    public var filters: [String: String]?
    public var page: Int?
    public var perPage: Int?

    public init(
        transportId: String? = nil,
        fromDate: Date? = nil,
        toDate: Date? = nil,
        logLevel: LogLevel? = nil,
        filters: [String: String]? = nil,
        page: Int? = nil,
        perPage: Int? = nil
    ) {
        self.transportId = transportId
        self.fromDate = fromDate
        self.toDate = toDate
        self.logLevel = logLevel
        self.filters = filters
        self.page = page
        self.perPage = perPage
    }

    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        if let transportId { items.append(.init(name: "transportId", value: transportId)) }
        if let fromDate { items.append(.init(name: "fromDate", value: ISO8601Formatter.string(from: fromDate))) }
        if let toDate { items.append(.init(name: "toDate", value: ISO8601Formatter.string(from: toDate))) }
        if let logLevel { items.append(.init(name: "logLevel", value: logLevel.rawValue)) }
        if let page { items.append(.init(name: "page", value: String(page))) }
        if let perPage { items.append(.init(name: "perPage", value: String(perPage))) }
        if let filters {
            // JS emits one `filters=key:value` item per entry.
            for (k, v) in filters.sorted(by: { $0.key < $1.key }) {
                items.append(.init(name: "filters", value: "\(k):\(v)"))
            }
        }
        return items
    }
}

/// Mirrors JS `GetLogParams` (the `client.getLogForRun` variant).
public struct GetLogParams: Sendable {
    public var runId: String
    public var transportId: String?
    public var fromDate: Date?
    public var toDate: Date?
    public var logLevel: LogLevel?
    public var filters: [String: String]?
    public var page: Int?
    public var perPage: Int?

    public init(
        runId: String,
        transportId: String? = nil,
        fromDate: Date? = nil,
        toDate: Date? = nil,
        logLevel: LogLevel? = nil,
        filters: [String: String]? = nil,
        page: Int? = nil,
        perPage: Int? = nil
    ) {
        self.runId = runId
        self.transportId = transportId
        self.fromDate = fromDate
        self.toDate = toDate
        self.logLevel = logLevel
        self.filters = filters
        self.page = page
        self.perPage = perPage
    }

    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = [.init(name: "runId", value: runId)]
        if let transportId { items.append(.init(name: "transportId", value: transportId)) }
        if let fromDate { items.append(.init(name: "fromDate", value: ISO8601Formatter.string(from: fromDate))) }
        if let toDate { items.append(.init(name: "toDate", value: ISO8601Formatter.string(from: toDate))) }
        if let logLevel { items.append(.init(name: "logLevel", value: logLevel.rawValue)) }
        if let page { items.append(.init(name: "page", value: String(page))) }
        if let perPage { items.append(.init(name: "perPage", value: String(perPage))) }
        if let filters {
            for (k, v) in filters.sorted(by: { $0.key < $1.key }) {
                items.append(.init(name: "filters", value: "\(k):\(v)"))
            }
        }
        return items
    }
}

// MARK: - Log transports

/// Mirrors JS `{ transports: string[] }`.
public struct ListLogTransportsResponse: Sendable, Codable {
    public let transports: [String]
    public init(transports: [String]) { self.transports = transports }
}

// MARK: - ISO8601 helper

enum ISO8601Formatter {
    /// Match JS `Date.toISOString()` output: fractional seconds to millisecond precision.
    static func string(from date: Date) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.string(from: date)
    }
}
