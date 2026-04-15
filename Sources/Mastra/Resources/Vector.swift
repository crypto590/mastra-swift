import Foundation

/// Equivalent of JS `Vector` resource. All methods map 1:1 to the JS client;
/// paths are preserved exactly (including `encodeURIComponent` of the vector
/// name and index name). Acquire an instance via `MastraClient.vector(name:)`.
public struct Vector: Sendable {
    public let vectorName: String
    let base: BaseResource

    init(base: BaseResource, vectorName: String) {
        self.base = base
        self.vectorName = vectorName
    }

    // MARK: - Path helpers

    private var encodedName: String {
        vectorName.addingPercentEncoding(withAllowedCharacters: .jsURIComponent) ?? vectorName
    }

    private func encode(_ s: String) -> String {
        s.addingPercentEncoding(withAllowedCharacters: .jsURIComponent) ?? s
    }

    private func requestContextQuery(_ context: RequestContext?) -> [URLQueryItem] {
        guard let encoded = context?.base64Encoded() else { return [] }
        return [.init(name: "requestContext", value: encoded)]
    }

    // MARK: - Index details / list / delete

    /// Mirrors JS `vector.details(indexName, requestContext?)` →
    /// `GET /vector/:vectorName/indexes/:indexName`.
    public func details(
        indexName: String,
        requestContext: RequestContext? = nil
    ) async throws -> IndexInfo {
        try await base.request(
            "/vector/\(encodedName)/indexes/\(encode(indexName))",
            query: requestContextQuery(requestContext)
        )
    }

    /// Mirrors JS `vector.delete(indexName)` →
    /// `DELETE /vector/:vectorName/indexes/:indexName`.
    public func delete(
        indexName: String
    ) async throws -> VectorSuccessResponse {
        try await base.request(
            "/vector/\(encodedName)/indexes/\(encode(indexName))",
            method: .DELETE
        )
    }

    /// Mirrors JS `vector.getIndexes(requestContext?)` →
    /// `GET /vector/:vectorName/indexes`.
    public func getIndexes(
        requestContext: RequestContext? = nil
    ) async throws -> GetIndexesResponse {
        try await base.request(
            "/vector/\(encodedName)/indexes",
            query: requestContextQuery(requestContext)
        )
    }

    public struct GetIndexesResponse: Sendable, Codable {
        public let indexes: [String]
    }

    // MARK: - Index creation / upsert / query

    /// Mirrors JS `vector.createIndex(params)` →
    /// `POST /vector/:vectorName/create-index`.
    public func createIndex(
        _ params: CreateIndexParams
    ) async throws -> VectorSuccessResponse {
        let data = try JSONEncoder().encode(params)
        let body = try JSONDecoder().decode(JSONValue.self, from: data)
        return try await base.request(
            "/vector/\(encodedName)/create-index",
            method: .POST,
            body: .json(body)
        )
    }

    /// Mirrors JS `vector.upsert(params)` → `POST /vector/:vectorName/upsert`.
    public func upsert(
        _ params: UpsertParams
    ) async throws -> UpsertResponse {
        try await base.request(
            "/vector/\(encodedName)/upsert",
            method: .POST,
            body: .json(params.body())
        )
    }

    /// Mirrors JS `vector.query(params)` → `POST /vector/:vectorName/query`.
    public func query(
        _ params: QueryParams
    ) async throws -> QueryResponse {
        try await base.request(
            "/vector/\(encodedName)/query",
            method: .POST,
            body: .json(params.body())
        )
    }
}
