import Foundation

public extension MastraClient {
    // ========================================================================
    // Datasets
    // ========================================================================

    /// Mirrors JS `client.listDatasets(pagination?)` → `GET /datasets`.
    nonisolated func listDatasets(
        page: Int? = nil,
        perPage: Int? = nil
    ) async throws -> ListDatasetsResponse {
        var query: [URLQueryItem] = []
        if let page { query.append(.init(name: "page", value: String(page))) }
        if let perPage { query.append(.init(name: "perPage", value: String(perPage))) }
        return try await base.request("/datasets", query: query)
    }

    /// Mirrors JS `client.getDataset(datasetId)` → `GET /datasets/:id`.
    nonisolated func dataset(_ datasetId: String) async throws -> DatasetRecord {
        let encoded = datasetId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? datasetId
        return try await base.request("/datasets/\(encoded)")
    }

    /// Mirrors JS `client.createDataset(params)` → `POST /datasets`.
    nonisolated func createDataset(
        _ params: CreateDatasetParams
    ) async throws -> DatasetRecord {
        try await base.request("/datasets", method: .POST, body: .json(params.body()))
    }

    /// Mirrors JS `client.updateDataset(params)` → `PATCH /datasets/:id`.
    nonisolated func updateDataset(
        _ params: UpdateDatasetParams
    ) async throws -> DatasetRecord {
        let encoded = params.datasetId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? params.datasetId
        return try await base.request(
            "/datasets/\(encoded)",
            method: .PATCH,
            body: .json(params.body())
        )
    }

    /// Mirrors JS `client.deleteDataset(datasetId)` → `DELETE /datasets/:id`.
    @discardableResult
    nonisolated func deleteDataset(_ datasetId: String) async throws -> DatasetDeleteResponse {
        let encoded = datasetId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? datasetId
        return try await base.request("/datasets/\(encoded)", method: .DELETE)
    }

    // ========================================================================
    // Dataset Items
    // ========================================================================

    /// Mirrors JS `client.listDatasetItems(datasetId, params?)` →
    /// `GET /datasets/:id/items`.
    nonisolated func listDatasetItems(
        datasetId: String,
        page: Int? = nil,
        perPage: Int? = nil,
        search: String? = nil,
        version: Int? = nil
    ) async throws -> ListDatasetItemsResponse {
        let encoded = datasetId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? datasetId
        var query: [URLQueryItem] = []
        if let page { query.append(.init(name: "page", value: String(page))) }
        if let perPage { query.append(.init(name: "perPage", value: String(perPage))) }
        if let search { query.append(.init(name: "search", value: search)) }
        if let version { query.append(.init(name: "version", value: String(version))) }
        return try await base.request("/datasets/\(encoded)/items", query: query)
    }

    /// Mirrors JS `client.getDatasetItem(datasetId, itemId)` →
    /// `GET /datasets/:id/items/:itemId`.
    nonisolated func datasetItem(
        datasetId: String,
        itemId: String
    ) async throws -> DatasetItem {
        let d = datasetId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? datasetId
        let i = itemId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? itemId
        return try await base.request("/datasets/\(d)/items/\(i)")
    }

    /// Mirrors JS `client.addDatasetItem(params)` →
    /// `POST /datasets/:id/items`.
    nonisolated func addDatasetItem(
        _ params: AddDatasetItemParams
    ) async throws -> DatasetItem {
        let encoded = params.datasetId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? params.datasetId
        return try await base.request(
            "/datasets/\(encoded)/items",
            method: .POST,
            body: .json(params.body())
        )
    }

    /// Mirrors JS `client.updateDatasetItem(params)` →
    /// `PATCH /datasets/:id/items/:itemId`.
    nonisolated func updateDatasetItem(
        _ params: UpdateDatasetItemParams
    ) async throws -> DatasetItem {
        let d = params.datasetId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? params.datasetId
        let i = params.itemId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? params.itemId
        return try await base.request(
            "/datasets/\(d)/items/\(i)",
            method: .PATCH,
            body: .json(params.body())
        )
    }

    /// Mirrors JS `client.deleteDatasetItem(datasetId, itemId)` →
    /// `DELETE /datasets/:id/items/:itemId`.
    @discardableResult
    nonisolated func deleteDatasetItem(
        datasetId: String,
        itemId: String
    ) async throws -> DatasetDeleteResponse {
        let d = datasetId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? datasetId
        let i = itemId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? itemId
        return try await base.request("/datasets/\(d)/items/\(i)", method: .DELETE)
    }

    /// Mirrors JS `client.batchInsertDatasetItems(params)` →
    /// `POST /datasets/:id/items/batch`.
    nonisolated func batchInsertDatasetItems(
        _ params: BatchInsertDatasetItemsParams
    ) async throws -> BatchInsertDatasetItemsResponse {
        let encoded = params.datasetId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? params.datasetId
        return try await base.request(
            "/datasets/\(encoded)/items/batch",
            method: .POST,
            body: .json(params.body())
        )
    }

    /// Mirrors JS `client.batchDeleteDatasetItems(params)` →
    /// `DELETE /datasets/:id/items/batch` (with body).
    nonisolated func batchDeleteDatasetItems(
        _ params: BatchDeleteDatasetItemsParams
    ) async throws -> BatchDeleteDatasetItemsResponse {
        let encoded = params.datasetId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? params.datasetId
        return try await base.request(
            "/datasets/\(encoded)/items/batch",
            method: .DELETE,
            body: .json(params.body())
        )
    }

    /// Mirrors JS `client.generateDatasetItems(params)` →
    /// `POST /datasets/:id/generate-items`. Items are returned for review,
    /// not auto-saved.
    nonisolated func generateDatasetItems(
        _ params: GenerateDatasetItemsParams
    ) async throws -> GenerateDatasetItemsResponse {
        let encoded = params.datasetId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? params.datasetId
        return try await base.request(
            "/datasets/\(encoded)/generate-items",
            method: .POST,
            body: .json(params.body())
        )
    }

    /// Mirrors JS `client.clusterFailures(params)` →
    /// `POST /datasets/cluster-failures`.
    nonisolated func clusterFailures(
        _ params: ClusterFailuresParams
    ) async throws -> ClusterFailuresResponse {
        try await base.request(
            "/datasets/cluster-failures",
            method: .POST,
            body: .json(params.body())
        )
    }

    // ========================================================================
    // Dataset Item Versions
    // ========================================================================

    /// Mirrors JS `client.getItemHistory(datasetId, itemId)` →
    /// `GET /datasets/:id/items/:itemId/history`.
    nonisolated func itemHistory(
        datasetId: String,
        itemId: String
    ) async throws -> DatasetItemHistoryResponse {
        let d = datasetId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? datasetId
        let i = itemId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? itemId
        return try await base.request("/datasets/\(d)/items/\(i)/history")
    }

    /// Mirrors JS `client.getDatasetItemVersion(datasetId, itemId, datasetVersion)` →
    /// `GET /datasets/:id/items/:itemId/versions/:version`.
    nonisolated func datasetItemVersion(
        datasetId: String,
        itemId: String,
        datasetVersion: Int
    ) async throws -> DatasetItemVersionResponse {
        let d = datasetId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? datasetId
        let i = itemId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? itemId
        return try await base.request("/datasets/\(d)/items/\(i)/versions/\(datasetVersion)")
    }

    // ========================================================================
    // Dataset Versions
    // ========================================================================

    /// Mirrors JS `client.listDatasetVersions(datasetId, pagination?)` →
    /// `GET /datasets/:id/versions`.
    nonisolated func listDatasetVersions(
        datasetId: String,
        page: Int? = nil,
        perPage: Int? = nil
    ) async throws -> ListDatasetVersionsResponse {
        let encoded = datasetId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? datasetId
        var query: [URLQueryItem] = []
        if let page { query.append(.init(name: "page", value: String(page))) }
        if let perPage { query.append(.init(name: "perPage", value: String(perPage))) }
        return try await base.request("/datasets/\(encoded)/versions", query: query)
    }
}
