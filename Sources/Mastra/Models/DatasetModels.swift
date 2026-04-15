import Foundation

// MARK: - Item source

/// Mirrors JS `DatasetItemSource`. Identifies where a dataset item came from.
public struct DatasetItemSource: Sendable, Codable, Hashable {
    public enum SourceType: String, Sendable, Codable {
        case csv
        case json
        case trace
        case llm
        case experimentResult = "experiment-result"
    }

    public let type: SourceType
    public let referenceId: String?

    public init(type: SourceType, referenceId: String? = nil) {
        self.type = type
        self.referenceId = referenceId
    }
}

// MARK: - Dataset record / item

/// Mirrors JS `DatasetRecord`. Schema fields are open shapes (arbitrary JSON
/// Schema dictionaries) so they are typed as `JSONValue`.
public struct DatasetRecord: Sendable, Codable {
    public let id: String
    public let name: String
    public let description: String?
    public let metadata: JSONValue?
    public let inputSchema: JSONValue?
    public let groundTruthSchema: JSONValue?
    public let requestContextSchema: JSONValue?
    public let tags: [String]?
    public let targetType: String?
    public let targetIds: [String]?
    public let scorerIds: [String]?
    public let version: Int
    public let createdAt: String
    public let updatedAt: String

    public init(
        id: String,
        name: String,
        description: String? = nil,
        metadata: JSONValue? = nil,
        inputSchema: JSONValue? = nil,
        groundTruthSchema: JSONValue? = nil,
        requestContextSchema: JSONValue? = nil,
        tags: [String]? = nil,
        targetType: String? = nil,
        targetIds: [String]? = nil,
        scorerIds: [String]? = nil,
        version: Int,
        createdAt: String,
        updatedAt: String
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.metadata = metadata
        self.inputSchema = inputSchema
        self.groundTruthSchema = groundTruthSchema
        self.requestContextSchema = requestContextSchema
        self.tags = tags
        self.targetType = targetType
        self.targetIds = targetIds
        self.scorerIds = scorerIds
        self.version = version
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Mirrors JS `DatasetItem`. `input`, `groundTruth`, `expectedTrajectory`,
/// `metadata`, and `requestContext` are open-typed.
public struct DatasetItem: Sendable, Codable {
    public let id: String
    public let datasetId: String
    public let datasetVersion: Int
    public let input: JSONValue?
    public let groundTruth: JSONValue?
    public let expectedTrajectory: JSONValue?
    public let requestContext: JSONValue?
    public let metadata: JSONValue?
    public let source: DatasetItemSource?
    public let createdAt: String
    public let updatedAt: String

    public init(
        id: String,
        datasetId: String,
        datasetVersion: Int,
        input: JSONValue? = nil,
        groundTruth: JSONValue? = nil,
        expectedTrajectory: JSONValue? = nil,
        requestContext: JSONValue? = nil,
        metadata: JSONValue? = nil,
        source: DatasetItemSource? = nil,
        createdAt: String,
        updatedAt: String
    ) {
        self.id = id
        self.datasetId = datasetId
        self.datasetVersion = datasetVersion
        self.input = input
        self.groundTruth = groundTruth
        self.expectedTrajectory = expectedTrajectory
        self.requestContext = requestContext
        self.metadata = metadata
        self.source = source
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - List responses

/// Mirrors JS `{ datasets, pagination }`.
public struct ListDatasetsResponse: Sendable, Codable {
    public let datasets: [DatasetRecord]
    public let pagination: PaginationInfo

    public init(datasets: [DatasetRecord], pagination: PaginationInfo) {
        self.datasets = datasets
        self.pagination = pagination
    }
}

/// Mirrors JS `{ items, pagination }`.
public struct ListDatasetItemsResponse: Sendable, Codable {
    public let items: [DatasetItem]
    public let pagination: PaginationInfo

    public init(items: [DatasetItem], pagination: PaginationInfo) {
        self.items = items
        self.pagination = pagination
    }
}

/// Mirrors JS `{ success: boolean }`.
public struct DatasetDeleteResponse: Sendable, Codable {
    public let success: Bool
    public init(success: Bool) { self.success = success }
}

/// Mirrors JS `{ items, count }` for `batchInsertDatasetItems`.
public struct BatchInsertDatasetItemsResponse: Sendable, Codable {
    public let items: [DatasetItem]
    public let count: Int

    public init(items: [DatasetItem], count: Int) {
        self.items = items
        self.count = count
    }
}

/// Mirrors JS `{ success, deletedCount }` for `batchDeleteDatasetItems`.
public struct BatchDeleteDatasetItemsResponse: Sendable, Codable {
    public let success: Bool
    public let deletedCount: Int

    public init(success: Bool, deletedCount: Int) {
        self.success = success
        self.deletedCount = deletedCount
    }
}

// MARK: - Params — datasets

/// Mirrors JS `CreateDatasetParams`.
public struct CreateDatasetParams: Sendable {
    public var name: String
    public var description: String?
    public var metadata: JSONValue?
    public var inputSchema: JSONValue?
    public var groundTruthSchema: JSONValue?
    public var requestContextSchema: JSONValue?
    public var targetType: String?
    public var targetIds: [String]?
    public var scorerIds: [String]?

    public init(
        name: String,
        description: String? = nil,
        metadata: JSONValue? = nil,
        inputSchema: JSONValue? = nil,
        groundTruthSchema: JSONValue? = nil,
        requestContextSchema: JSONValue? = nil,
        targetType: String? = nil,
        targetIds: [String]? = nil,
        scorerIds: [String]? = nil
    ) {
        self.name = name
        self.description = description
        self.metadata = metadata
        self.inputSchema = inputSchema
        self.groundTruthSchema = groundTruthSchema
        self.requestContextSchema = requestContextSchema
        self.targetType = targetType
        self.targetIds = targetIds
        self.scorerIds = scorerIds
    }

    func body() -> JSONValue {
        var o: [String: JSONValue] = ["name": .string(name)]
        if let description { o["description"] = .string(description) }
        if let metadata { o["metadata"] = metadata }
        if let inputSchema { o["inputSchema"] = inputSchema }
        if let groundTruthSchema { o["groundTruthSchema"] = groundTruthSchema }
        if let requestContextSchema { o["requestContextSchema"] = requestContextSchema }
        if let targetType { o["targetType"] = .string(targetType) }
        if let targetIds { o["targetIds"] = .array(targetIds.map { .string($0) }) }
        if let scorerIds { o["scorerIds"] = .array(scorerIds.map { .string($0) }) }
        return .object(o)
    }
}

/// Mirrors JS `UpdateDatasetParams` (minus `datasetId` which is path-scoped).
public struct UpdateDatasetParams: Sendable {
    public var datasetId: String
    public var name: String?
    public var description: String?
    public var metadata: JSONValue?
    public var inputSchema: JSONValue?
    public var groundTruthSchema: JSONValue?
    public var requestContextSchema: JSONValue?
    public var tags: [String]?
    public var targetType: String?
    public var targetIds: [String]?
    public var scorerIds: [String]?

    public init(
        datasetId: String,
        name: String? = nil,
        description: String? = nil,
        metadata: JSONValue? = nil,
        inputSchema: JSONValue? = nil,
        groundTruthSchema: JSONValue? = nil,
        requestContextSchema: JSONValue? = nil,
        tags: [String]? = nil,
        targetType: String? = nil,
        targetIds: [String]? = nil,
        scorerIds: [String]? = nil
    ) {
        self.datasetId = datasetId
        self.name = name
        self.description = description
        self.metadata = metadata
        self.inputSchema = inputSchema
        self.groundTruthSchema = groundTruthSchema
        self.requestContextSchema = requestContextSchema
        self.tags = tags
        self.targetType = targetType
        self.targetIds = targetIds
        self.scorerIds = scorerIds
    }

    func body() -> JSONValue {
        var o: [String: JSONValue] = [:]
        if let name { o["name"] = .string(name) }
        if let description { o["description"] = .string(description) }
        if let metadata { o["metadata"] = metadata }
        if let inputSchema { o["inputSchema"] = inputSchema }
        if let groundTruthSchema { o["groundTruthSchema"] = groundTruthSchema }
        if let requestContextSchema { o["requestContextSchema"] = requestContextSchema }
        if let tags { o["tags"] = .array(tags.map { .string($0) }) }
        if let targetType { o["targetType"] = .string(targetType) }
        if let targetIds { o["targetIds"] = .array(targetIds.map { .string($0) }) }
        if let scorerIds { o["scorerIds"] = .array(scorerIds.map { .string($0) }) }
        return .object(o)
    }
}

// MARK: - Params — dataset items

/// Mirrors JS `AddDatasetItemParams`. `datasetId` is path-scoped (not in body).
public struct AddDatasetItemParams: Sendable {
    public var datasetId: String
    public var input: JSONValue
    public var groundTruth: JSONValue?
    public var expectedTrajectory: JSONValue?
    public var requestContext: JSONValue?
    public var metadata: JSONValue?
    public var source: DatasetItemSource?

    public init(
        datasetId: String,
        input: JSONValue,
        groundTruth: JSONValue? = nil,
        expectedTrajectory: JSONValue? = nil,
        requestContext: JSONValue? = nil,
        metadata: JSONValue? = nil,
        source: DatasetItemSource? = nil
    ) {
        self.datasetId = datasetId
        self.input = input
        self.groundTruth = groundTruth
        self.expectedTrajectory = expectedTrajectory
        self.requestContext = requestContext
        self.metadata = metadata
        self.source = source
    }

    func body() -> JSONValue {
        var o: [String: JSONValue] = ["input": input]
        if let groundTruth { o["groundTruth"] = groundTruth }
        if let expectedTrajectory { o["expectedTrajectory"] = expectedTrajectory }
        if let requestContext { o["requestContext"] = requestContext }
        if let metadata { o["metadata"] = metadata }
        if let source { o["source"] = encodeSource(source) }
        return .object(o)
    }
}

/// Mirrors JS `UpdateDatasetItemParams` (`datasetId`/`itemId` path-scoped).
public struct UpdateDatasetItemParams: Sendable {
    public var datasetId: String
    public var itemId: String
    public var input: JSONValue?
    public var groundTruth: JSONValue?
    public var expectedTrajectory: JSONValue?
    public var requestContext: JSONValue?
    public var metadata: JSONValue?
    public var source: DatasetItemSource?

    public init(
        datasetId: String,
        itemId: String,
        input: JSONValue? = nil,
        groundTruth: JSONValue? = nil,
        expectedTrajectory: JSONValue? = nil,
        requestContext: JSONValue? = nil,
        metadata: JSONValue? = nil,
        source: DatasetItemSource? = nil
    ) {
        self.datasetId = datasetId
        self.itemId = itemId
        self.input = input
        self.groundTruth = groundTruth
        self.expectedTrajectory = expectedTrajectory
        self.requestContext = requestContext
        self.metadata = metadata
        self.source = source
    }

    func body() -> JSONValue {
        var o: [String: JSONValue] = [:]
        if let input { o["input"] = input }
        if let groundTruth { o["groundTruth"] = groundTruth }
        if let expectedTrajectory { o["expectedTrajectory"] = expectedTrajectory }
        if let requestContext { o["requestContext"] = requestContext }
        if let metadata { o["metadata"] = metadata }
        if let source { o["source"] = encodeSource(source) }
        return .object(o)
    }
}

/// A single item entry for batch insert.
public struct BatchInsertItem: Sendable {
    public var input: JSONValue
    public var groundTruth: JSONValue?
    public var expectedTrajectory: JSONValue?
    public var requestContext: JSONValue?
    public var metadata: JSONValue?
    public var source: DatasetItemSource?

    public init(
        input: JSONValue,
        groundTruth: JSONValue? = nil,
        expectedTrajectory: JSONValue? = nil,
        requestContext: JSONValue? = nil,
        metadata: JSONValue? = nil,
        source: DatasetItemSource? = nil
    ) {
        self.input = input
        self.groundTruth = groundTruth
        self.expectedTrajectory = expectedTrajectory
        self.requestContext = requestContext
        self.metadata = metadata
        self.source = source
    }

    func json() -> JSONValue {
        var o: [String: JSONValue] = ["input": input]
        if let groundTruth { o["groundTruth"] = groundTruth }
        if let expectedTrajectory { o["expectedTrajectory"] = expectedTrajectory }
        if let requestContext { o["requestContext"] = requestContext }
        if let metadata { o["metadata"] = metadata }
        if let source { o["source"] = encodeSource(source) }
        return .object(o)
    }
}

/// Mirrors JS `BatchInsertDatasetItemsParams` (`datasetId` path-scoped).
public struct BatchInsertDatasetItemsParams: Sendable {
    public var datasetId: String
    public var items: [BatchInsertItem]

    public init(datasetId: String, items: [BatchInsertItem]) {
        self.datasetId = datasetId
        self.items = items
    }

    func body() -> JSONValue {
        .object(["items": .array(items.map { $0.json() })])
    }
}

/// Mirrors JS `BatchDeleteDatasetItemsParams` (`datasetId` path-scoped).
public struct BatchDeleteDatasetItemsParams: Sendable {
    public var datasetId: String
    public var itemIds: [String]

    public init(datasetId: String, itemIds: [String]) {
        self.datasetId = datasetId
        self.itemIds = itemIds
    }

    func body() -> JSONValue {
        .object(["itemIds": .array(itemIds.map { .string($0) })])
    }
}

// MARK: - Generate items

/// Mirrors JS `GenerateDatasetItemsParams` (`datasetId` path-scoped).
public struct GenerateDatasetItemsParams: Sendable {
    public struct AgentContext: Sendable {
        public var description: String?
        public var instructions: String?
        public var tools: [String]?

        public init(
            description: String? = nil,
            instructions: String? = nil,
            tools: [String]? = nil
        ) {
            self.description = description
            self.instructions = instructions
            self.tools = tools
        }

        func json() -> JSONValue {
            var o: [String: JSONValue] = [:]
            if let description { o["description"] = .string(description) }
            if let instructions { o["instructions"] = .string(instructions) }
            if let tools { o["tools"] = .array(tools.map { .string($0) }) }
            return .object(o)
        }
    }

    public var datasetId: String
    public var modelId: String
    public var prompt: String
    public var count: Int?
    public var agentContext: AgentContext?

    public init(
        datasetId: String,
        modelId: String,
        prompt: String,
        count: Int? = nil,
        agentContext: AgentContext? = nil
    ) {
        self.datasetId = datasetId
        self.modelId = modelId
        self.prompt = prompt
        self.count = count
        self.agentContext = agentContext
    }

    func body() -> JSONValue {
        var o: [String: JSONValue] = [
            "modelId": .string(modelId),
            "prompt": .string(prompt),
        ]
        if let count { o["count"] = .int(Int64(count)) }
        if let agentContext { o["agentContext"] = agentContext.json() }
        return .object(o)
    }
}

/// Mirrors JS `GeneratedItem`.
public struct GeneratedItem: Sendable, Codable {
    public let input: JSONValue?
    public let groundTruth: JSONValue?

    public init(input: JSONValue? = nil, groundTruth: JSONValue? = nil) {
        self.input = input
        self.groundTruth = groundTruth
    }
}

/// Mirrors JS `{ items: GeneratedItem[] }`.
public struct GenerateDatasetItemsResponse: Sendable, Codable {
    public let items: [GeneratedItem]
    public init(items: [GeneratedItem]) { self.items = items }
}

// MARK: - Cluster failures

/// Mirrors JS `clusterFailures` input items.
public struct ClusterFailureItem: Sendable {
    public var id: String
    public var input: JSONValue
    public var output: JSONValue?
    public var error: String?
    public var scores: [String: Double]?
    public var existingTags: [String]?

    public init(
        id: String,
        input: JSONValue,
        output: JSONValue? = nil,
        error: String? = nil,
        scores: [String: Double]? = nil,
        existingTags: [String]? = nil
    ) {
        self.id = id
        self.input = input
        self.output = output
        self.error = error
        self.scores = scores
        self.existingTags = existingTags
    }

    func json() -> JSONValue {
        var o: [String: JSONValue] = [
            "id": .string(id),
            "input": input,
        ]
        if let output { o["output"] = output }
        if let error { o["error"] = .string(error) }
        if let scores {
            var sc: [String: JSONValue] = [:]
            for (k, v) in scores { sc[k] = .double(v) }
            o["scores"] = .object(sc)
        }
        if let existingTags { o["existingTags"] = .array(existingTags.map { .string($0) }) }
        return .object(o)
    }
}

/// Mirrors JS `clusterFailures` params object.
public struct ClusterFailuresParams: Sendable {
    public var modelId: String
    public var items: [ClusterFailureItem]
    public var availableTags: [String]?
    public var prompt: String?

    public init(
        modelId: String,
        items: [ClusterFailureItem],
        availableTags: [String]? = nil,
        prompt: String? = nil
    ) {
        self.modelId = modelId
        self.items = items
        self.availableTags = availableTags
        self.prompt = prompt
    }

    func body() -> JSONValue {
        var o: [String: JSONValue] = [
            "modelId": .string(modelId),
            "items": .array(items.map { $0.json() }),
        ]
        if let availableTags { o["availableTags"] = .array(availableTags.map { .string($0) }) }
        if let prompt { o["prompt"] = .string(prompt) }
        return .object(o)
    }
}

/// Mirrors JS `clusterFailures` response.
public struct ClusterFailuresResponse: Sendable, Codable {
    public struct Cluster: Sendable, Codable {
        public let id: String
        public let label: String
        public let description: String
        public let itemIds: [String]

        public init(id: String, label: String, description: String, itemIds: [String]) {
            self.id = id
            self.label = label
            self.description = description
            self.itemIds = itemIds
        }
    }

    public struct ProposedTag: Sendable, Codable {
        public let itemId: String
        public let tags: [String]
        public let reason: String

        public init(itemId: String, tags: [String], reason: String) {
            self.itemId = itemId
            self.tags = tags
            self.reason = reason
        }
    }

    public let clusters: [Cluster]
    public let proposedTags: [ProposedTag]?

    public init(clusters: [Cluster], proposedTags: [ProposedTag]? = nil) {
        self.clusters = clusters
        self.proposedTags = proposedTags
    }
}

// MARK: - Versions

/// Mirrors JS `DatasetItemVersionResponse`.
public struct DatasetItemVersionResponse: Sendable, Codable {
    public let id: String
    public let datasetId: String
    public let datasetVersion: Int
    public let input: JSONValue?
    public let groundTruth: JSONValue?
    public let metadata: JSONValue?
    public let validTo: Int?
    public let isDeleted: Bool
    public let createdAt: String
    public let updatedAt: String

    public init(
        id: String,
        datasetId: String,
        datasetVersion: Int,
        input: JSONValue? = nil,
        groundTruth: JSONValue? = nil,
        metadata: JSONValue? = nil,
        validTo: Int? = nil,
        isDeleted: Bool,
        createdAt: String,
        updatedAt: String
    ) {
        self.id = id
        self.datasetId = datasetId
        self.datasetVersion = datasetVersion
        self.input = input
        self.groundTruth = groundTruth
        self.metadata = metadata
        self.validTo = validTo
        self.isDeleted = isDeleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Mirrors JS `{ history: DatasetItemVersionResponse[] }`.
public struct DatasetItemHistoryResponse: Sendable, Codable {
    public let history: [DatasetItemVersionResponse]
    public init(history: [DatasetItemVersionResponse]) { self.history = history }
}

/// Mirrors JS `DatasetVersionResponse`.
public struct DatasetVersionResponse: Sendable, Codable {
    public let id: String
    public let datasetId: String
    public let version: Int
    public let createdAt: String

    public init(id: String, datasetId: String, version: Int, createdAt: String) {
        self.id = id
        self.datasetId = datasetId
        self.version = version
        self.createdAt = createdAt
    }
}

/// Mirrors JS `{ versions, pagination }`.
public struct ListDatasetVersionsResponse: Sendable, Codable {
    public let versions: [DatasetVersionResponse]
    public let pagination: PaginationInfo

    public init(versions: [DatasetVersionResponse], pagination: PaginationInfo) {
        self.versions = versions
        self.pagination = pagination
    }
}

// MARK: - Experiments

/// Mirrors JS `DatasetExperiment`.
public struct DatasetExperiment: Sendable, Codable {
    public enum TargetType: String, Sendable, Codable {
        case agent, workflow, scorer, processor
    }

    public enum Status: String, Sendable, Codable {
        case pending, running, completed, failed
    }

    public let id: String
    public let datasetId: String?
    public let datasetVersion: Int?
    public let agentVersion: String?
    public let targetType: TargetType
    public let targetId: String
    public let status: Status
    public let totalItems: Int
    public let succeededCount: Int
    public let failedCount: Int
    public let startedAt: String?
    public let completedAt: String?
    public let createdAt: String
    public let updatedAt: String

    public init(
        id: String,
        datasetId: String? = nil,
        datasetVersion: Int? = nil,
        agentVersion: String? = nil,
        targetType: TargetType,
        targetId: String,
        status: Status,
        totalItems: Int,
        succeededCount: Int,
        failedCount: Int,
        startedAt: String? = nil,
        completedAt: String? = nil,
        createdAt: String,
        updatedAt: String
    ) {
        self.id = id
        self.datasetId = datasetId
        self.datasetVersion = datasetVersion
        self.agentVersion = agentVersion
        self.targetType = targetType
        self.targetId = targetId
        self.status = status
        self.totalItems = totalItems
        self.succeededCount = succeededCount
        self.failedCount = failedCount
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Mirrors JS `DatasetExperimentResult`.
public struct DatasetExperimentResult: Sendable, Codable {
    public enum ReviewStatus: String, Sendable, Codable {
        case needsReview = "needs-review"
        case reviewed
        case complete
    }

    public struct Score: Sendable, Codable {
        public let scorerId: String
        public let scorerName: String
        public let score: Double?
        public let reason: String?
        public let error: String?

        public init(
            scorerId: String,
            scorerName: String,
            score: Double? = nil,
            reason: String? = nil,
            error: String? = nil
        ) {
            self.scorerId = scorerId
            self.scorerName = scorerName
            self.score = score
            self.reason = reason
            self.error = error
        }
    }

    public let id: String
    public let experimentId: String
    public let itemId: String
    public let itemDatasetVersion: Int?
    public let input: JSONValue?
    public let output: JSONValue?
    public let groundTruth: JSONValue?
    public let error: String?
    public let startedAt: String
    public let completedAt: String
    public let retryCount: Int
    public let traceId: String?
    public let status: ReviewStatus?
    public let tags: [String]?
    public let scores: [Score]
    public let createdAt: String

    public init(
        id: String,
        experimentId: String,
        itemId: String,
        itemDatasetVersion: Int? = nil,
        input: JSONValue? = nil,
        output: JSONValue? = nil,
        groundTruth: JSONValue? = nil,
        error: String? = nil,
        startedAt: String,
        completedAt: String,
        retryCount: Int,
        traceId: String? = nil,
        status: ReviewStatus? = nil,
        tags: [String]? = nil,
        scores: [Score],
        createdAt: String
    ) {
        self.id = id
        self.experimentId = experimentId
        self.itemId = itemId
        self.itemDatasetVersion = itemDatasetVersion
        self.input = input
        self.output = output
        self.groundTruth = groundTruth
        self.error = error
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.retryCount = retryCount
        self.traceId = traceId
        self.status = status
        self.tags = tags
        self.scores = scores
        self.createdAt = createdAt
    }
}

/// Mirrors JS `{ experiments, pagination }`.
public struct ListDatasetExperimentsResponse: Sendable, Codable {
    public let experiments: [DatasetExperiment]
    public let pagination: PaginationInfo

    public init(experiments: [DatasetExperiment], pagination: PaginationInfo) {
        self.experiments = experiments
        self.pagination = pagination
    }
}

/// Mirrors JS `{ results, pagination }`.
public struct ListDatasetExperimentResultsResponse: Sendable, Codable {
    public let results: [DatasetExperimentResult]
    public let pagination: PaginationInfo

    public init(results: [DatasetExperimentResult], pagination: PaginationInfo) {
        self.results = results
        self.pagination = pagination
    }
}

/// Mirrors JS `ExperimentReviewCounts`.
public struct ExperimentReviewCounts: Sendable, Codable {
    public let experimentId: String
    public let total: Int
    public let needsReview: Int
    public let reviewed: Int
    public let complete: Int

    public init(experimentId: String, total: Int, needsReview: Int, reviewed: Int, complete: Int) {
        self.experimentId = experimentId
        self.total = total
        self.needsReview = needsReview
        self.reviewed = reviewed
        self.complete = complete
    }
}

/// Mirrors JS `{ counts: ExperimentReviewCounts[] }`.
public struct ExperimentReviewSummaryResponse: Sendable, Codable {
    public let counts: [ExperimentReviewCounts]
    public init(counts: [ExperimentReviewCounts]) { self.counts = counts }
}

// MARK: - Trigger & update experiment

/// Mirrors JS `TriggerDatasetExperimentParams` (`datasetId` path-scoped).
public struct TriggerDatasetExperimentParams: Sendable {
    public enum TargetType: String, Sendable, Codable {
        case agent, workflow, scorer
    }

    public var datasetId: String
    public var targetType: TargetType
    public var targetId: String
    public var scorerIds: [String]?
    public var version: Int?
    public var agentVersion: String?
    public var maxConcurrency: Int?
    public var requestContext: JSONValue?

    public init(
        datasetId: String,
        targetType: TargetType,
        targetId: String,
        scorerIds: [String]? = nil,
        version: Int? = nil,
        agentVersion: String? = nil,
        maxConcurrency: Int? = nil,
        requestContext: JSONValue? = nil
    ) {
        self.datasetId = datasetId
        self.targetType = targetType
        self.targetId = targetId
        self.scorerIds = scorerIds
        self.version = version
        self.agentVersion = agentVersion
        self.maxConcurrency = maxConcurrency
        self.requestContext = requestContext
    }

    func body() -> JSONValue {
        var o: [String: JSONValue] = [
            "targetType": .string(targetType.rawValue),
            "targetId": .string(targetId),
        ]
        if let scorerIds { o["scorerIds"] = .array(scorerIds.map { .string($0) }) }
        if let version { o["version"] = .int(Int64(version)) }
        if let agentVersion { o["agentVersion"] = .string(agentVersion) }
        if let maxConcurrency { o["maxConcurrency"] = .int(Int64(maxConcurrency)) }
        if let requestContext { o["requestContext"] = requestContext }
        return .object(o)
    }
}

/// Mirrors the JS return shape of `triggerDatasetExperiment` — a summary with
/// per-item results. Dates are strings.
public struct TriggerDatasetExperimentResponse: Sendable, Codable {
    public struct ItemResult: Sendable, Codable {
        public struct Score: Sendable, Codable {
            public let scorerId: String
            public let scorerName: String
            public let score: Double?
            public let reason: String?
            public let error: String?
        }
        public let itemId: String
        public let itemDatasetVersion: Int?
        public let input: JSONValue?
        public let output: JSONValue?
        public let groundTruth: JSONValue?
        public let error: String?
        public let startedAt: String
        public let completedAt: String
        public let retryCount: Int
        public let scores: [Score]
    }

    public let experimentId: String
    public let status: DatasetExperiment.Status
    public let totalItems: Int
    public let succeededCount: Int
    public let failedCount: Int
    public let startedAt: String
    public let completedAt: String?
    public let results: [ItemResult]
}

/// Mirrors JS `UpdateExperimentResultParams` (path segments peeled into URL).
public struct UpdateExperimentResultParams: Sendable {
    public var datasetId: String
    public var experimentId: String
    public var resultId: String
    /// Note: JS allows explicit `null` to clear. We model that as
    /// `.some(nil)` via the nested optional pattern: `status == .some(nil)`
    /// means "encode null". `nil` (i.e. `.none`) means "omit".
    public var status: DatasetExperimentResult.ReviewStatus??
    public var tags: [String]?

    public init(
        datasetId: String,
        experimentId: String,
        resultId: String,
        status: DatasetExperimentResult.ReviewStatus?? = nil,
        tags: [String]? = nil
    ) {
        self.datasetId = datasetId
        self.experimentId = experimentId
        self.resultId = resultId
        self.status = status
        self.tags = tags
    }

    func body() -> JSONValue {
        var o: [String: JSONValue] = [:]
        switch status {
        case .some(.some(let v)): o["status"] = .string(v.rawValue)
        case .some(.none): o["status"] = .null
        case .none: break
        }
        if let tags { o["tags"] = .array(tags.map { .string($0) }) }
        return .object(o)
    }
}

// MARK: - Compare experiments

/// Mirrors JS `CompareExperimentsParams` (`datasetId` path-scoped).
public struct CompareExperimentsParams: Sendable {
    public struct Threshold: Sendable {
        public enum Direction: String, Sendable, Codable {
            case higherIsBetter = "higher-is-better"
            case lowerIsBetter = "lower-is-better"
        }

        public var value: Double
        public var direction: Direction?

        public init(value: Double, direction: Direction? = nil) {
            self.value = value
            self.direction = direction
        }

        func json() -> JSONValue {
            var o: [String: JSONValue] = ["value": .double(value)]
            if let direction { o["direction"] = .string(direction.rawValue) }
            return .object(o)
        }
    }

    public var datasetId: String
    public var experimentIdA: String
    public var experimentIdB: String
    public var thresholds: [String: Threshold]?

    public init(
        datasetId: String,
        experimentIdA: String,
        experimentIdB: String,
        thresholds: [String: Threshold]? = nil
    ) {
        self.datasetId = datasetId
        self.experimentIdA = experimentIdA
        self.experimentIdB = experimentIdB
        self.thresholds = thresholds
    }

    func body() -> JSONValue {
        var o: [String: JSONValue] = [
            "experimentIdA": .string(experimentIdA),
            "experimentIdB": .string(experimentIdB),
        ]
        if let thresholds {
            var t: [String: JSONValue] = [:]
            for (k, v) in thresholds { t[k] = v.json() }
            o["thresholds"] = .object(t)
        }
        return .object(o)
    }
}

/// Mirrors JS `CompareExperimentsResponse`. The per-experiment `results` map
/// has open-shaped values (keyed by experiment id), so it's carried as
/// `JSONValue`.
public struct CompareExperimentsResponse: Sendable, Codable {
    public struct Item: Sendable, Codable {
        public let itemId: String
        public let input: JSONValue?
        public let groundTruth: JSONValue?
        public let results: JSONValue

        public init(itemId: String, input: JSONValue?, groundTruth: JSONValue?, results: JSONValue) {
            self.itemId = itemId
            self.input = input
            self.groundTruth = groundTruth
            self.results = results
        }
    }

    public let baselineId: String
    public let items: [Item]

    public init(baselineId: String, items: [Item]) {
        self.baselineId = baselineId
        self.items = items
    }
}

// MARK: - Helpers

private func encodeSource(_ source: DatasetItemSource) -> JSONValue {
    var o: [String: JSONValue] = ["type": .string(source.type.rawValue)]
    if let ref = source.referenceId { o["referenceId"] = .string(ref) }
    return .object(o)
}
