import XCTest
@testable import Mastra
import MastraTestingSupport

final class DatasetTests: XCTestCase {
    // MARK: - Helpers

    private func makeClient(
        handler: @escaping MockTransport.Handler = { _ in
            HTTPResponse(status: 200, statusText: "OK", headers: [:], body: Data("{}".utf8))
        }
    ) throws -> (MastraClient, MockTransport) {
        let mock = MockTransport(handler: handler)
        let config = Configuration(
            baseURL: URL(string: "https://example.com")!,
            transport: mock
        )
        let client = try MastraClient(configuration: config)
        return (client, mock)
    }

    private func jsonResponse(_ object: Any) -> HTTPResponse {
        let data = try! JSONSerialization.data(withJSONObject: object, options: [])
        return HTTPResponse(status: 200, statusText: "OK", headers: [:], body: data)
    }

    private func decodeBody(_ request: HTTPRequest) -> JSONValue? {
        guard case .json(let value) = request.body else { return nil }
        return value
    }

    private func datasetRecordJSON(id: String = "d1", name: String = "Eval") -> [String: Any] {
        [
            "id": id,
            "name": name,
            "version": 1,
            "createdAt": "2025-01-01T00:00:00Z",
            "updatedAt": "2025-01-01T00:00:00Z",
        ]
    }

    private func datasetItemJSON(id: String = "item-1", datasetId: String = "d1") -> [String: Any] {
        [
            "id": id,
            "datasetId": datasetId,
            "datasetVersion": 1,
            "input": ["q": "hello"],
            "createdAt": "2025-01-01T00:00:00Z",
            "updatedAt": "2025-01-01T00:00:00Z",
        ]
    }

    // MARK: - listDatasets

    func testListDatasetsWithPagination() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "datasets": [self.datasetRecordJSON(id: "d1", name: "Alpha")],
                "pagination": ["total": 1, "page": 2, "perPage": 10, "hasMore": false],
            ])
        })
        let resp = try await client.listDatasets(page: 2, perPage: 10)
        XCTAssertEqual(resp.datasets.count, 1)
        XCTAssertEqual(resp.datasets.first?.id, "d1")
        XCTAssertEqual(resp.pagination.page, 2)
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/datasets")
        XCTAssertTrue(req.query.contains(.init(name: "page", value: "2")))
        XCTAssertTrue(req.query.contains(.init(name: "perPage", value: "10")))
    }

    func testListDatasetsWithoutPagination() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "datasets": [],
                "pagination": ["total": 0, "page": 1, "perPage": 20, "hasMore": false],
            ])
        })
        _ = try await client.listDatasets()
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.fullPath, "/api/datasets")
        XCTAssertFalse(req.query.contains(where: { $0.name == "page" }))
        XCTAssertFalse(req.query.contains(where: { $0.name == "perPage" }))
    }

    // MARK: - getDataset

    func testGetDatasetUsesGetOnDatasetPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(self.datasetRecordJSON(id: "d1", name: "Alpha"))
        })
        let rec = try await client.dataset("d1")
        XCTAssertEqual(rec.id, "d1")
        XCTAssertEqual(rec.name, "Alpha")
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/datasets/d1")
    }

    func testGetDatasetEncodesDatasetId() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(self.datasetRecordJSON(id: "a b", name: "X"))
        })
        _ = try await client.dataset("a b")
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.fullPath, "/api/datasets/a%20b")
    }

    // MARK: - createDataset

    func testCreateDatasetPostsExpectedShape() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(self.datasetRecordJSON(id: "d-new", name: "Alpha"))
        })
        let params = CreateDatasetParams(
            name: "Alpha",
            description: "First eval",
            targetType: "agent",
            targetIds: ["agent-1"],
            scorerIds: ["s1", "s2"]
        )
        _ = try await client.createDataset(params)
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/datasets")
        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["name"]?.stringValue, "Alpha")
        XCTAssertEqual(body["description"]?.stringValue, "First eval")
        XCTAssertEqual(body["targetType"]?.stringValue, "agent")
        XCTAssertEqual(body["targetIds"]?.arrayValue?.count, 1)
        XCTAssertEqual(body["scorerIds"]?.arrayValue?.count, 2)
    }

    // MARK: - updateDataset

    func testUpdateDatasetUsesPatch() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(self.datasetRecordJSON(id: "d1", name: "New name"))
        })
        let params = UpdateDatasetParams(datasetId: "d1", name: "New name")
        _ = try await client.updateDataset(params)
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .PATCH)
        XCTAssertEqual(req.fullPath, "/api/datasets/d1")
        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["name"]?.stringValue, "New name")
        XCTAssertNil(body["datasetId"]) // path-scoped, must not leak into body
    }

    // MARK: - deleteDataset

    func testDeleteDatasetUsesDelete() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["success": true])
        })
        let resp = try await client.deleteDataset("d1")
        XCTAssertTrue(resp.success)
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .DELETE)
        XCTAssertEqual(req.fullPath, "/api/datasets/d1")
    }

    // MARK: - listDatasetItems

    func testListDatasetItemsIncludesSearchAndVersion() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "items": [self.datasetItemJSON()],
                "pagination": ["total": 1, "page": 1, "perPage": 50, "hasMore": false],
            ])
        })
        _ = try await client.listDatasetItems(
            datasetId: "d1",
            page: 1,
            perPage: 50,
            search: "hello",
            version: 3
        )
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.fullPath, "/api/datasets/d1/items")
        XCTAssertTrue(req.query.contains(.init(name: "page", value: "1")))
        XCTAssertTrue(req.query.contains(.init(name: "perPage", value: "50")))
        XCTAssertTrue(req.query.contains(.init(name: "search", value: "hello")))
        XCTAssertTrue(req.query.contains(.init(name: "version", value: "3")))
    }

    // MARK: - getDatasetItem

    func testGetDatasetItemPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(self.datasetItemJSON(id: "i1", datasetId: "d1"))
        })
        let item = try await client.datasetItem(datasetId: "d1", itemId: "i1")
        XCTAssertEqual(item.id, "i1")
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/datasets/d1/items/i1")
    }

    // MARK: - addDatasetItem

    func testAddDatasetItemPostsInputBody() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(self.datasetItemJSON(id: "new", datasetId: "d1"))
        })
        let params = AddDatasetItemParams(
            datasetId: "d1",
            input: .object(["q": .string("hi")]),
            groundTruth: .string("hello"),
            source: DatasetItemSource(type: .csv, referenceId: "file-1")
        )
        _ = try await client.addDatasetItem(params)
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/datasets/d1/items")
        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertNil(body["datasetId"])
        XCTAssertEqual(body["groundTruth"]?.stringValue, "hello")
        XCTAssertEqual(body["source"]?["type"]?.stringValue, "csv")
        XCTAssertEqual(body["source"]?["referenceId"]?.stringValue, "file-1")
    }

    // MARK: - updateDatasetItem

    func testUpdateDatasetItemUsesPatch() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(self.datasetItemJSON(id: "i1", datasetId: "d1"))
        })
        let params = UpdateDatasetItemParams(
            datasetId: "d1",
            itemId: "i1",
            input: .object(["q": .string("updated")])
        )
        _ = try await client.updateDatasetItem(params)
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .PATCH)
        XCTAssertEqual(req.fullPath, "/api/datasets/d1/items/i1")
    }

    // MARK: - deleteDatasetItem

    func testDeleteDatasetItem() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["success": true])
        })
        let resp = try await client.deleteDatasetItem(datasetId: "d1", itemId: "i1")
        XCTAssertTrue(resp.success)
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .DELETE)
        XCTAssertEqual(req.fullPath, "/api/datasets/d1/items/i1")
    }

    // MARK: - batchInsertDatasetItems

    func testBatchInsertDatasetItemsPostsItemsArray() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "items": [self.datasetItemJSON(id: "a"), self.datasetItemJSON(id: "b")],
                "count": 2,
            ])
        })
        let params = BatchInsertDatasetItemsParams(
            datasetId: "d1",
            items: [
                BatchInsertItem(input: .object(["q": .string("one")])),
                BatchInsertItem(
                    input: .object(["q": .string("two")]),
                    groundTruth: .string("answer")
                ),
            ]
        )
        let resp = try await client.batchInsertDatasetItems(params)
        XCTAssertEqual(resp.count, 2)
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/datasets/d1/items/batch")
        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["items"]?.arrayValue?.count, 2)
        XCTAssertEqual(body["items"]?.arrayValue?[1]["groundTruth"]?.stringValue, "answer")
    }

    // MARK: - batchDeleteDatasetItems

    func testBatchDeleteDatasetItemsSendsDeleteWithBody() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["success": true, "deletedCount": 3])
        })
        let params = BatchDeleteDatasetItemsParams(
            datasetId: "d1",
            itemIds: ["a", "b", "c"]
        )
        let resp = try await client.batchDeleteDatasetItems(params)
        XCTAssertEqual(resp.deletedCount, 3)
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .DELETE)
        XCTAssertEqual(req.fullPath, "/api/datasets/d1/items/batch")
        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["itemIds"]?.arrayValue?.count, 3)
    }

    // MARK: - generateDatasetItems

    func testGenerateDatasetItemsPostsPrompt() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "items": [
                    ["input": ["q": "auto-1"]],
                    ["input": ["q": "auto-2"], "groundTruth": "ans"],
                ]
            ])
        })
        let params = GenerateDatasetItemsParams(
            datasetId: "d1",
            modelId: "gpt-5",
            prompt: "Make some eval cases",
            count: 2,
            agentContext: GenerateDatasetItemsParams.AgentContext(
                description: "helpful",
                instructions: "be concise",
                tools: ["search"]
            )
        )
        let resp = try await client.generateDatasetItems(params)
        XCTAssertEqual(resp.items.count, 2)
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/datasets/d1/generate-items")
        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["modelId"]?.stringValue, "gpt-5")
        XCTAssertEqual(body["prompt"]?.stringValue, "Make some eval cases")
        XCTAssertEqual(body["count"]?.intValue, 2)
        XCTAssertEqual(body["agentContext"]?["instructions"]?.stringValue, "be concise")
    }

    // MARK: - clusterFailures

    func testClusterFailuresPostsItems() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "clusters": [
                    ["id": "c1", "label": "Timeouts", "description": "slow", "itemIds": ["a", "b"]]
                ]
            ])
        })
        let params = ClusterFailuresParams(
            modelId: "gpt-5",
            items: [
                ClusterFailureItem(
                    id: "a",
                    input: .string("input-a"),
                    output: .string("out-a"),
                    error: "timeout",
                    scores: ["accuracy": 0.2],
                    existingTags: ["slow"]
                )
            ],
            availableTags: ["slow", "flaky"],
            prompt: "Group failures"
        )
        let resp = try await client.clusterFailures(params)
        XCTAssertEqual(resp.clusters.count, 1)
        XCTAssertEqual(resp.clusters[0].itemIds, ["a", "b"])
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/datasets/cluster-failures")
        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["modelId"]?.stringValue, "gpt-5")
        XCTAssertEqual(body["items"]?.arrayValue?.count, 1)
        XCTAssertEqual(body["items"]?.arrayValue?[0]["error"]?.stringValue, "timeout")
        XCTAssertEqual(body["availableTags"]?.arrayValue?.count, 2)
        XCTAssertEqual(body["prompt"]?.stringValue, "Group failures")
    }

    // MARK: - getItemHistory

    func testGetItemHistoryPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "history": [
                    [
                        "id": "i1",
                        "datasetId": "d1",
                        "datasetVersion": 1,
                        "validTo": NSNull(),
                        "isDeleted": false,
                        "createdAt": "2025-01-01T00:00:00Z",
                        "updatedAt": "2025-01-01T00:00:00Z",
                    ]
                ]
            ])
        })
        let resp = try await client.itemHistory(datasetId: "d1", itemId: "i1")
        XCTAssertEqual(resp.history.count, 1)
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/datasets/d1/items/i1/history")
    }

    // MARK: - getDatasetItemVersion

    func testGetDatasetItemVersionPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "id": "i1",
                "datasetId": "d1",
                "datasetVersion": 5,
                "validTo": NSNull(),
                "isDeleted": false,
                "createdAt": "2025-01-01T00:00:00Z",
                "updatedAt": "2025-01-01T00:00:00Z",
            ])
        })
        let v = try await client.datasetItemVersion(
            datasetId: "d1",
            itemId: "i1",
            datasetVersion: 5
        )
        XCTAssertEqual(v.datasetVersion, 5)
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/datasets/d1/items/i1/versions/5")
    }

    // MARK: - listDatasetVersions

    func testListDatasetVersionsPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "versions": [
                    ["id": "v1", "datasetId": "d1", "version": 1, "createdAt": "2025-01-01T00:00:00Z"]
                ],
                "pagination": ["total": 1, "page": 1, "perPage": 10, "hasMore": false],
            ])
        })
        _ = try await client.listDatasetVersions(datasetId: "d1", page: 1, perPage: 10)
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/datasets/d1/versions")
        XCTAssertTrue(req.query.contains(.init(name: "page", value: "1")))
        XCTAssertTrue(req.query.contains(.init(name: "perPage", value: "10")))
    }
}
