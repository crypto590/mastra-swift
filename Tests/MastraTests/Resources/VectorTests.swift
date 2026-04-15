import XCTest
@testable import Mastra
import MastraTestingSupport

final class VectorTests: XCTestCase {
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

    // MARK: - createIndex

    func testCreateIndexPostsShape() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["success": true])
        })
        let vector = client.vector(name: "pinecone")
        let resp = try await vector.createIndex(
            CreateIndexParams(indexName: "docs", dimension: 1536, metric: .cosine)
        )
        XCTAssertTrue(resp.success)

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/vector/pinecone/create-index")

        let body = try XCTUnwrap(decodeBody(req))
        XCTAssertEqual(body["indexName"]?.stringValue, "docs")
        XCTAssertEqual(body["dimension"]?.intValue, 1536)
        XCTAssertEqual(body["metric"]?.stringValue, "cosine")
    }

    // MARK: - upsert

    func testUpsertPostsShape() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["a", "b"])
        })
        let vector = client.vector(name: "pinecone")
        let ids = try await vector.upsert(
            UpsertParams(
                indexName: "docs",
                vectors: [[0.1, 0.2, 0.3], [0.4, 0.5, 0.6]],
                metadata: [
                    ["source": .string("x")],
                    ["source": .string("y")],
                ],
                ids: ["a", "b"]
            )
        )
        XCTAssertEqual(ids, ["a", "b"])

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/vector/pinecone/upsert")

        let body = try XCTUnwrap(decodeBody(req))
        XCTAssertEqual(body["indexName"]?.stringValue, "docs")
        let vectors = try XCTUnwrap(body["vectors"]?.arrayValue)
        XCTAssertEqual(vectors.count, 2)
        XCTAssertEqual(vectors[0].arrayValue?.count, 3)
        XCTAssertEqual(body["ids"]?.arrayValue?.compactMap { $0.stringValue }, ["a", "b"])
        let metadata = try XCTUnwrap(body["metadata"]?.arrayValue)
        XCTAssertEqual(metadata[0]["source"]?.stringValue, "x")
    }

    // MARK: - query

    func testQueryPostsShape() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "results": [
                    ["id": "r1", "score": 0.9]
                ]
            ])
        })
        let vector = client.vector(name: "pinecone")
        let resp = try await vector.query(
            QueryParams(
                indexName: "docs",
                queryVector: [0.1, 0.2, 0.3],
                topK: 5,
                filter: ["source": .string("x")],
                includeVector: true
            )
        )
        XCTAssertEqual(resp.results.count, 1)
        XCTAssertEqual(resp.results.first?.id, "r1")

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/vector/pinecone/query")

        let body = try XCTUnwrap(decodeBody(req))
        XCTAssertEqual(body["indexName"]?.stringValue, "docs")
        XCTAssertEqual(body["queryVector"]?.arrayValue?.count, 3)
        XCTAssertEqual(body["topK"]?.intValue, 5)
        XCTAssertEqual(body["includeVector"]?.boolValue, true)
        XCTAssertEqual(body["filter"]?["source"]?.stringValue, "x")
    }

    // MARK: - delete

    func testDeleteIndexSendsDelete() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["success": true])
        })
        let vector = client.vector(name: "pinecone")
        let resp = try await vector.delete(indexName: "docs")
        XCTAssertTrue(resp.success)

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .DELETE)
        XCTAssertEqual(req.fullPath, "/api/vector/pinecone/indexes/docs")
    }

    // MARK: - getIndexes

    func testGetIndexesPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["indexes": ["a", "b"]])
        })
        let vector = client.vector(name: "pinecone")
        let resp = try await vector.getIndexes()
        XCTAssertEqual(resp.indexes, ["a", "b"])

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/vector/pinecone/indexes")
    }

    // MARK: - details

    func testDetailsPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "dimension": 1536,
                "metric": "cosine",
                "count": 42,
            ])
        })
        let vector = client.vector(name: "pinecone")
        let info = try await vector.details(indexName: "docs")
        XCTAssertEqual(info.dimension, 1536)
        XCTAssertEqual(info.metric, .cosine)
        XCTAssertEqual(info.count, 42)

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/vector/pinecone/indexes/docs")
    }

    // MARK: - top-level listVectors / listEmbedders

    func testListVectorsPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["vectors": []])
        })
        _ = try await client.listVectors()
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.fullPath, "/api/vectors")
    }

    func testListEmbeddersPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["embedders": []])
        })
        _ = try await client.listEmbedders()
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.fullPath, "/api/embedders")
    }
}
