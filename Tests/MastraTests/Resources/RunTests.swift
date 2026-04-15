import XCTest
@testable import Mastra
import MastraTestingSupport

final class RunTests: XCTestCase {
    // MARK: - Helpers

    private func makeClient(
        handler: @escaping MockTransport.Handler = { _ in
            HTTPResponse(status: 200, statusText: "OK", headers: [:], body: Data("{}".utf8))
        },
        streamingHandler: @escaping MockTransport.StreamingHandler = { _ in
            HTTPStreamingResponse(
                status: 200, statusText: "OK", headers: [:],
                bytes: AsyncThrowingStream { $0.finish() }
            )
        }
    ) throws -> (MastraClient, MockTransport) {
        let mock = MockTransport(handler: handler, streamingHandler: streamingHandler)
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

    private func makeRun(_ client: MastraClient, workflowId: String = "wf", runId: String = "run-1") -> Run {
        Run(base: client.base, workflowId: workflowId, runId: runId)
    }

    // MARK: - start / startAsync

    func testStartPostsShape() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["message": "ok"])
        })
        let run = makeRun(client)
        let resp = try await run.start(
            StartParams(
                inputData: .object(["x": .int(1)]),
                initialState: .object(["flag": .bool(true)])
            )
        )
        XCTAssertEqual(resp.message, "ok")

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/workflows/wf/start")
        XCTAssertTrue(req.query.contains(.init(name: "runId", value: "run-1")))

        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["inputData"]?["x"]?.intValue, 1)
        XCTAssertEqual(body["initialState"]?["flag"]?.boolValue, true)
        // JS `start` does not forward `resourceId`.
        XCTAssertNil(body["resourceId"])
    }

    func testStartAsyncPathAndDecodesResult() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "status": "success",
                "result": ["value": 42],
                "runId": "run-1",
            ])
        })
        let run = makeRun(client)
        let result = try await run.startAsync(
            StartParams(inputData: .object([:]), resourceId: "res-1")
        )
        XCTAssertEqual(result.status, "success")
        XCTAssertEqual(result.result?["value"]?.intValue, 42)
        XCTAssertEqual(result.runId, "run-1")
        XCTAssertNil(result.error)

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.fullPath, "/api/workflows/wf/start-async")
        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["resourceId"]?.stringValue, "res-1")
    }

    func testStartAsyncSurfacesFailedError() async throws {
        let (client, _) = try makeClient(handler: { _ in
            self.jsonResponse([
                "status": "failed",
                "error": [
                    "message": "boom",
                    "name": "StepError",
                ],
            ])
        })
        let run = makeRun(client)
        let result = try await run.startAsync(
            StartParams(inputData: .object([:]))
        )
        XCTAssertEqual(result.status, "failed")
        let err = try XCTUnwrap(result.error)
        XCTAssertEqual(err.message, "boom")
        XCTAssertEqual(err.name, "StepError")
    }

    // MARK: - cancel

    func testCancelPostsToCancelPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["message": "Workflow run canceled"])
        })
        let run = makeRun(client, runId: "r-9")
        let resp = try await run.cancel()
        XCTAssertEqual(resp.message, "Workflow run canceled")
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/workflows/wf/runs/r-9/cancel")
    }

    // MARK: - stream (record-separator)

    func testStreamYieldsMultipleRSChunks() async throws {
        let rs = "\u{1E}"
        let streamBody =
            "{\"type\":\"start\",\"payload\":{}}" + rs +
            "{\"type\":\"step-result\",\"payload\":{\"k\":1}}" + rs +
            "{\"type\":\"finish\",\"payload\":{}}" + rs
        let (client, mock) = try makeClient(streamingHandler: { _ in
            HTTPStreamingResponse(
                status: 200, statusText: "OK", headers: [:],
                bytes: MockTransport.bytes(streamBody)
            )
        })
        let run = makeRun(client)
        let stream = try await run.stream(
            StartParams(inputData: .object([:]), closeOnSuspend: true)
        )
        var chunks: [JSONValue] = []
        for try await chunk in stream { chunks.append(chunk) }
        XCTAssertEqual(chunks.count, 3)
        XCTAssertEqual(chunks[0]["type"]?.stringValue, "start")
        XCTAssertEqual(chunks[1]["type"]?.stringValue, "step-result")
        XCTAssertEqual(chunks[1]["payload"]?["k"]?.intValue, 1)
        XCTAssertEqual(chunks[2]["type"]?.stringValue, "finish")

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/workflows/wf/stream")
        XCTAssertTrue(req.query.contains(.init(name: "runId", value: "run-1")))
        // JS `stream` forwards `closeOnSuspend`.
        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["closeOnSuspend"]?.boolValue, true)
    }

    // MARK: - resume / resumeStream

    func testResumeStreamPostsShape() async throws {
        let rs = "\u{1E}"
        let streamBody =
            "{\"type\":\"step-result\",\"payload\":{}}" + rs
        let (client, mock) = try makeClient(streamingHandler: { _ in
            HTTPStreamingResponse(
                status: 200, statusText: "OK", headers: [:],
                bytes: MockTransport.bytes(streamBody)
            )
        })
        let run = makeRun(client, runId: "rid")
        let stream = try await run.resumeStream(
            ResumeParams(
                step: ["inner", "check"],
                resumeData: .object(["answer": .string("yes")])
            )
        )
        var chunks: [JSONValue] = []
        for try await chunk in stream { chunks.append(chunk) }
        XCTAssertEqual(chunks.count, 1)

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/workflows/wf/resume-stream")
        XCTAssertTrue(req.query.contains(.init(name: "runId", value: "rid")))
        let body = try XCTUnwrap(self.decodeBody(req))
        // Multi-step array is preserved.
        let steps = try XCTUnwrap(body["step"]?.arrayValue)
        XCTAssertEqual(steps.compactMap { $0.stringValue }, ["inner", "check"])
        XCTAssertEqual(body["resumeData"]?["answer"]?.stringValue, "yes")
    }

    // MARK: - time travel

    func testTimeTravelPostsShape() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["message": "ok"])
        })
        let run = makeRun(client, runId: "tt")
        _ = try await run.timeTravel(
            TimeTravelParams(
                step: ["step-a"],
                inputData: .object(["x": .int(2)]),
                context: .object(["prev": .string("yes")])
            )
        )
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.fullPath, "/api/workflows/wf/time-travel")
        XCTAssertTrue(req.query.contains(.init(name: "runId", value: "tt")))
        let body = try XCTUnwrap(self.decodeBody(req))
        // Single-step becomes a string, matching JS behavior.
        XCTAssertEqual(body["step"]?.stringValue, "step-a")
        XCTAssertEqual(body["inputData"]?["x"]?.intValue, 2)
        XCTAssertEqual(body["context"]?["prev"]?.stringValue, "yes")
    }
}
