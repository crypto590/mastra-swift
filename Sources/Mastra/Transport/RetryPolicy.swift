import Foundation

public struct RetryPolicy: Sendable {
    public var maxRetries: Int
    public var initialBackoff: Duration
    public var maxBackoff: Duration

    public init(
        maxRetries: Int = 3,
        initialBackoff: Duration = .milliseconds(100),
        maxBackoff: Duration = .milliseconds(1000)
    ) {
        self.maxRetries = maxRetries
        self.initialBackoff = initialBackoff
        self.maxBackoff = maxBackoff
    }

    public static let `default` = RetryPolicy()
    public static let none = RetryPolicy(maxRetries: 0)
}

extension RetryPolicy {
    /// Mirrors `base.ts`: do not retry on 4xx; otherwise exponential backoff up to `maxRetries` attempts.
    public static func shouldRetry(error: Error) -> Bool {
        if let mce = error as? MastraClientError {
            return !(400...499).contains(mce.status)
        }
        return true
    }

    public func backoff(forAttempt attempt: Int) -> Duration {
        let multiplier = max(0, attempt)
        let scaled = initialBackoff * (1 << min(multiplier, 30))
        return scaled > maxBackoff ? maxBackoff : scaled
    }
}

private func * (lhs: Duration, rhs: Int) -> Duration {
    Duration.nanoseconds(lhs.components.attoseconds / 1_000_000_000 * Int64(rhs)
                         + lhs.components.seconds * 1_000_000_000 * Int64(rhs))
}

private func > (lhs: Duration, rhs: Duration) -> Bool {
    if lhs.components.seconds != rhs.components.seconds {
        return lhs.components.seconds > rhs.components.seconds
    }
    return lhs.components.attoseconds > rhs.components.attoseconds
}
