import Foundation

public extension MastraClient {
    // ========================================================================
    // Experiments (cross-dataset)
    // ========================================================================

    /// Mirrors JS `client.listExperiments(pagination?)` → `GET /experiments`.
    nonisolated func listExperiments(
        page: Int? = nil,
        perPage: Int? = nil
    ) async throws -> ListDatasetExperimentsResponse {
        var query: [URLQueryItem] = []
        if let page { query.append(.init(name: "page", value: String(page))) }
        if let perPage { query.append(.init(name: "perPage", value: String(perPage))) }
        return try await base.request("/experiments", query: query)
    }

    /// Mirrors JS `client.getExperimentReviewSummary()` →
    /// `GET /experiments/review-summary`.
    nonisolated func experimentReviewSummary() async throws -> ExperimentReviewSummaryResponse {
        try await base.request("/experiments/review-summary")
    }

    // ========================================================================
    // Dataset Experiments
    // ========================================================================

    /// Mirrors JS `client.listDatasetExperiments(datasetId, pagination?)` →
    /// `GET /datasets/:id/experiments`.
    nonisolated func listDatasetExperiments(
        datasetId: String,
        page: Int? = nil,
        perPage: Int? = nil
    ) async throws -> ListDatasetExperimentsResponse {
        let encoded = datasetId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? datasetId
        var query: [URLQueryItem] = []
        if let page { query.append(.init(name: "page", value: String(page))) }
        if let perPage { query.append(.init(name: "perPage", value: String(perPage))) }
        return try await base.request("/datasets/\(encoded)/experiments", query: query)
    }

    /// Mirrors JS `client.getDatasetExperiment(datasetId, experimentId)` →
    /// `GET /datasets/:id/experiments/:experimentId`.
    nonisolated func datasetExperiment(
        datasetId: String,
        experimentId: String
    ) async throws -> DatasetExperiment {
        let d = datasetId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? datasetId
        let e = experimentId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? experimentId
        return try await base.request("/datasets/\(d)/experiments/\(e)")
    }

    /// Mirrors JS `client.listDatasetExperimentResults(datasetId, experimentId, pagination?)`
    /// → `GET /datasets/:id/experiments/:experimentId/results`.
    nonisolated func listDatasetExperimentResults(
        datasetId: String,
        experimentId: String,
        page: Int? = nil,
        perPage: Int? = nil
    ) async throws -> ListDatasetExperimentResultsResponse {
        let d = datasetId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? datasetId
        let e = experimentId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? experimentId
        var query: [URLQueryItem] = []
        if let page { query.append(.init(name: "page", value: String(page))) }
        if let perPage { query.append(.init(name: "perPage", value: String(perPage))) }
        return try await base.request("/datasets/\(d)/experiments/\(e)/results", query: query)
    }

    /// Mirrors JS `client.updateDatasetExperimentResult(params)` →
    /// `PATCH /datasets/:id/experiments/:experimentId/results/:resultId`.
    nonisolated func updateDatasetExperimentResult(
        _ params: UpdateExperimentResultParams
    ) async throws -> DatasetExperimentResult {
        try await performUpdateExperimentResult(params)
    }

    /// Mirrors JS `client.triggerDatasetExperiment(params)` →
    /// `POST /datasets/:id/experiments`.
    nonisolated func triggerDatasetExperiment(
        _ params: TriggerDatasetExperimentParams
    ) async throws -> TriggerDatasetExperimentResponse {
        let encoded = params.datasetId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? params.datasetId
        return try await base.request(
            "/datasets/\(encoded)/experiments",
            method: .POST,
            body: .json(params.body())
        )
    }

    /// Mirrors JS `client.updateExperimentResult(params)` — same endpoint as
    /// `updateDatasetExperimentResult`; the JS client exposes both names.
    nonisolated func updateExperimentResult(
        _ params: UpdateExperimentResultParams
    ) async throws -> DatasetExperimentResult {
        try await performUpdateExperimentResult(params)
    }

    /// Mirrors JS `client.compareExperiments(params)` →
    /// `POST /datasets/:id/compare`.
    nonisolated func compareExperiments(
        _ params: CompareExperimentsParams
    ) async throws -> CompareExperimentsResponse {
        let encoded = params.datasetId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? params.datasetId
        return try await base.request(
            "/datasets/\(encoded)/compare",
            method: .POST,
            body: .json(params.body())
        )
    }

    // MARK: - Private helpers

    private nonisolated func performUpdateExperimentResult(
        _ params: UpdateExperimentResultParams
    ) async throws -> DatasetExperimentResult {
        let d = params.datasetId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? params.datasetId
        let e = params.experimentId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? params.experimentId
        let r = params.resultId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? params.resultId
        return try await base.request(
            "/datasets/\(d)/experiments/\(e)/results/\(r)",
            method: .PATCH,
            body: .json(params.body())
        )
    }
}
