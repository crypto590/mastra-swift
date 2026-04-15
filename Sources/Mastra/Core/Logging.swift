import Foundation

public enum MastraLogLevel: Int, Sendable, Comparable {
    case trace = 0, debug, info, warning, error
    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public protocol MastraLogger: Sendable {
    func log(_ level: MastraLogLevel, _ message: @autoclosure () -> String)
}

public struct NoopLogger: MastraLogger {
    public init() {}
    public func log(_ level: MastraLogLevel, _ message: @autoclosure () -> String) {}
}

public struct PrintLogger: MastraLogger {
    public let minimum: MastraLogLevel
    public init(minimum: MastraLogLevel = .info) { self.minimum = minimum }
    public func log(_ level: MastraLogLevel, _ message: @autoclosure () -> String) {
        guard level >= minimum else { return }
        print("[mastra:\(level)] \(message())")
    }
}
