import Foundation

public extension MastraClient {
    /// Mirrors JS `client.listLogs(params)` → `GET /logs`.
    ///
    /// The JS implementation emits one `filters=key:value` query item per
    /// entry in `filters`; our `GetLogsParams` serialization matches that.
    nonisolated func listLogs(
        _ params: GetLogsParams = .init()
    ) async throws -> GetLogsResponse {
        try await base.request("/logs", query: params.queryItems)
    }

    /// Mirrors JS `client.getLogForRun(params)` → `GET /logs/:runId`.
    nonisolated func logForRun(
        _ params: GetLogParams
    ) async throws -> GetLogsResponse {
        let encoded = params.runId.addingPercentEncoding(withAllowedCharacters: .jsURIComponent) ?? params.runId
        return try await base.request("/logs/\(encoded)", query: params.queryItems)
    }

    /// Mirrors JS `client.listLogTransports()` → `GET /logs/transports`.
    nonisolated func listLogTransports() async throws -> ListLogTransportsResponse {
        try await base.request("/logs/transports")
    }
}
