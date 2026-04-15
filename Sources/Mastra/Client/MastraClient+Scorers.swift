import Foundation

public extension MastraClient {
    /// Mirrors JS `client.listScorers(requestContext?)` → `GET /scores/scorers`.
    nonisolated func listScorers(
        requestContext: RequestContext? = nil
    ) async throws -> [String: GetScorerResponse] {
        var query: [URLQueryItem] = []
        if let encoded = requestContext?.base64Encoded() {
            query.append(URLQueryItem(name: "requestContext", value: encoded))
        }
        return try await base.request("/scores/scorers", query: query)
    }

    /// Mirrors JS `client.getScorer(scorerId)` → `GET /scores/scorers/:scorerId`.
    nonisolated func scorer(id: String) async throws -> GetScorerResponse {
        let encoded = id.addingPercentEncoding(withAllowedCharacters: .jsURIComponent) ?? id
        return try await base.request("/scores/scorers/\(encoded)")
    }

    /// Mirrors JS `client.listScoresByScorerId(params)` → `GET /scores/scorer/:scorerId`.
    nonisolated func listScoresByScorerId(
        _ params: ListScoresByScorerIdParams
    ) async throws -> ListScoresResponse {
        let encoded = params.scorerId.addingPercentEncoding(withAllowedCharacters: .jsURIComponent) ?? params.scorerId
        return try await base.request(
            "/scores/scorer/\(encoded)",
            query: params.queryItems
        )
    }

    /// Mirrors JS `client.listScoresByRunId(params)` → `GET /scores/run/:runId`.
    nonisolated func listScoresByRunId(
        _ params: ListScoresByRunIdParams
    ) async throws -> ListScoresResponse {
        let encoded = params.runId.addingPercentEncoding(withAllowedCharacters: .jsURIComponent) ?? params.runId
        return try await base.request(
            "/scores/run/\(encoded)",
            query: params.queryItems
        )
    }

    /// Mirrors JS `client.listScoresByEntityId(params)` →
    /// `GET /scores/entity/:entityType/:entityId`.
    nonisolated func listScoresByEntityId(
        _ params: ListScoresByEntityIdParams
    ) async throws -> ListScoresResponse {
        let typeEnc = params.entityType.addingPercentEncoding(withAllowedCharacters: .jsURIComponent) ?? params.entityType
        let idEnc = params.entityId.addingPercentEncoding(withAllowedCharacters: .jsURIComponent) ?? params.entityId
        return try await base.request(
            "/scores/entity/\(typeEnc)/\(idEnc)",
            query: params.queryItems
        )
    }

    /// Mirrors JS `client.saveScore(params)` → `POST /scores`.
    nonisolated func saveScore(
        _ params: SaveScoreParams
    ) async throws -> SaveScoreResponse {
        try await base.request(
            "/scores",
            method: .POST,
            body: .json(params.body())
        )
    }
}
