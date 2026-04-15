import Foundation

// MARK: - Index info

/// Mirrors JS `GetVectorIndexResponse`.
public struct IndexInfo: Sendable, Codable {
    public let dimension: Int
    public let metric: VectorMetric
    public let count: Int

    public init(dimension: Int, metric: VectorMetric, count: Int) {
        self.dimension = dimension
        self.metric = metric
        self.count = count
    }
}

public enum VectorMetric: String, Sendable, Codable {
    case cosine
    case euclidean
    case dotproduct
}

// MARK: - Create index

/// Mirrors JS `CreateIndexParams`.
public struct CreateIndexParams: Sendable, Codable {
    public var indexName: String
    public var dimension: Int
    public var metric: VectorMetric?

    public init(indexName: String, dimension: Int, metric: VectorMetric? = nil) {
        self.indexName = indexName
        self.dimension = dimension
        self.metric = metric
    }
}

// MARK: - Upsert

/// Mirrors JS `UpsertVectorParams`.
public struct UpsertParams: Sendable {
    public var indexName: String
    public var vectors: [[Double]]
    public var metadata: [[String: JSONValue]]?
    public var ids: [String]?

    public init(
        indexName: String,
        vectors: [[Double]],
        metadata: [[String: JSONValue]]? = nil,
        ids: [String]? = nil
    ) {
        self.indexName = indexName
        self.vectors = vectors
        self.metadata = metadata
        self.ids = ids
    }

    func body() -> JSONValue {
        var obj: JSONObject = [
            "indexName": .string(indexName),
            "vectors": .array(vectors.map { vec in
                .array(vec.map { .double($0) })
            }),
        ]
        if let metadata {
            obj["metadata"] = .array(metadata.map { .object($0) })
        }
        if let ids {
            obj["ids"] = .array(ids.map(JSONValue.string))
        }
        return .object(obj)
    }
}

// MARK: - Query

/// Mirrors JS `QueryVectorParams`.
public struct QueryParams: Sendable {
    public var indexName: String
    public var queryVector: [Double]
    public var topK: Int?
    public var filter: [String: JSONValue]?
    public var includeVector: Bool?

    public init(
        indexName: String,
        queryVector: [Double],
        topK: Int? = nil,
        filter: [String: JSONValue]? = nil,
        includeVector: Bool? = nil
    ) {
        self.indexName = indexName
        self.queryVector = queryVector
        self.topK = topK
        self.filter = filter
        self.includeVector = includeVector
    }

    func body() -> JSONValue {
        var obj: JSONObject = [
            "indexName": .string(indexName),
            "queryVector": .array(queryVector.map { .double($0) }),
        ]
        if let topK { obj["topK"] = .int(Int64(topK)) }
        if let filter { obj["filter"] = .object(filter) }
        if let includeVector { obj["includeVector"] = .bool(includeVector) }
        return .object(obj)
    }
}

/// Mirrors JS `QueryResult` from `@mastra/core/vector`. Metadata is genuinely
/// open (depends on what the caller inserted) so stays as `JSONValue`.
public struct QueryResult: Sendable, Codable {
    public let id: String
    public let score: Double
    public let metadata: [String: JSONValue]?
    public let vector: [Double]?

    public init(
        id: String,
        score: Double,
        metadata: [String: JSONValue]? = nil,
        vector: [Double]? = nil
    ) {
        self.id = id
        self.score = score
        self.metadata = metadata
        self.vector = vector
    }
}

/// Mirrors JS `QueryVectorResponse`.
public struct QueryResponse: Sendable, Codable {
    public let results: [QueryResult]

    public init(results: [QueryResult]) { self.results = results }
}

// MARK: - List vectors / embedders

/// Mirrors JS `ListVectorsResponse`.
public struct ListVectorsResponse: Sendable, Codable {
    public let vectors: [VectorInfo]

    public struct VectorInfo: Sendable, Codable {
        public let name: String
        public let id: String
        public let type: String
    }
}

/// Mirrors JS `ListEmbeddersResponse`.
public struct ListEmbeddersResponse: Sendable, Codable {
    public let embedders: [EmbedderInfo]
}

public struct EmbedderInfo: Sendable, Codable {
    public let id: String
    public let provider: String
    public let name: String
    public let description: String
    public let dimensions: Int
    public let maxInputTokens: Int
}

// MARK: - Generic "success" response

public struct VectorSuccessResponse: Sendable, Codable {
    public let success: Bool
}

// MARK: - Upsert response

/// JS `upsert` returns `string[]` (the assigned vector ids). We wrap it so
/// consumers get a named type.
public typealias UpsertResponse = [String]
