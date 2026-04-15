import XCTest
@testable import Mastra
import MastraTestingSupport

final class AgentTests: XCTestCase {
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

    // MARK: - details

    func testDetailsUsesGetOnAgentsPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "id": "a1",
                "name": "Alpha",
                "instructions": "Say hi",
            ])
        })
        let agent = client.agent(id: "a1")
        let details = try await agent.details()
        XCTAssertEqual(details.id, "a1")
        XCTAssertEqual(details.name, "Alpha")
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/agents/a1")
    }

    func testDetailsWithVersionAddsQuery() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "id": "a1", "name": "Alpha", "instructions": "x",
            ])
        })
        let agent = client.agent(id: "a1", version: .status(.draft))
        _ = try await agent.details()
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertTrue(req.query.contains(.init(name: "status", value: "draft")))
    }

    // MARK: - enhanceInstructions

    func testEnhanceInstructionsPostsBody() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["explanation": "e", "new_prompt": "p"])
        })
        let agent = client.agent(id: "agent-x")
        let out = try await agent.enhanceInstructions(instructions: "hi", comment: "please")
        XCTAssertEqual(out.explanation, "e")
        XCTAssertEqual(out.new_prompt, "p")
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/agents/agent-x/instructions/enhance")
        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["instructions"]?.stringValue, "hi")
        XCTAssertEqual(body["comment"]?.stringValue, "please")
    }

    // MARK: - generate

    func testGeneratePostsExpectedShape() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["finishReason": "stop", "text": "ok"])
        })
        let agent = client.agent(id: "a2")
        let params = GenerateParams(
            messages: .array([
                .object(["role": .string("user"), "content": .string("hi")])
            ]),
            threadId: "thread-1"
        )
        _ = try await agent.generate(params)
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/agents/a2/generate")
        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["threadId"]?.stringValue, "thread-1")
        XCTAssertNotNil(body["messages"]?.arrayValue)
    }

    // MARK: - client tools loop

    func testGenerateClientToolLoopCompletes() async throws {
        // Simulate server first returning tool-calls, then a final answer.
        let callCount = Counter()
        let (client, mock) = try makeClient(handler: { req in
            callCount.increment()
            switch callCount.value {
            case 1:
                return self.jsonResponse([
                    "finishReason": "tool-calls",
                    "toolCalls": [
                        [
                            "payload": [
                                "toolName": "echo",
                                "args": ["text": "hello"],
                                "toolCallId": "call-1",
                            ]
                        ]
                    ],
                    "response": [
                        "messages": [
                            ["role": "assistant", "content": "calling echo"]
                        ]
                    ]
                ])
            default:
                return self.jsonResponse([
                    "finishReason": "stop",
                    "text": "done",
                ])
            }
        })

        let echoInvocations = Counter()
        let echoTool = ClientTool(
            id: "echo",
            description: "Echo text",
            execute: { args in
                echoInvocations.increment()
                let text = args["text"]?.stringValue ?? ""
                return .object(["echoed": .string(text)])
            }
        )

        let agent = client.agent(id: "loop-agent")
        let params = GenerateParams(
            messages: .array([.object(["role": .string("user"), "content": .string("echo hello")])]),
            threadId: "t",
            clientTools: [echoTool]
        )
        let final = try await agent.generate(params)

        XCTAssertEqual(final["finishReason"]?.stringValue, "stop")
        XCTAssertEqual(echoInvocations.value, 1)
        XCTAssertEqual(callCount.value, 2)
        XCTAssertEqual(mock.requests.count, 2)

        // Second request should include the tool-result message.
        let secondBody = try XCTUnwrap(self.decodeBody(mock.requests[1]))
        let messages = try XCTUnwrap(secondBody["messages"]?.arrayValue)
        XCTAssertTrue(
            messages.contains(where: { msg in
                msg["role"]?.stringValue == "tool"
            }),
            "expected a tool-role message in recursive call"
        )
    }

    func testGenerateSerializesClientToolsOnTheWire() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["finishReason": "stop"])
        })
        let schema: JSONValue = .object(["type": .string("object")])
        let tool = ClientTool(
            id: "weather",
            description: "Returns the weather",
            inputSchema: schema,
            execute: { _ in .null }
        )
        let agent = client.agent(id: "a")
        _ = try await agent.generate(
            GenerateParams(
                messages: .array([]),
                clientTools: [tool]
            )
        )
        let body = try XCTUnwrap(self.decodeBody(mock.requests[0]))
        let tools = try XCTUnwrap(body["clientTools"]?.objectValue)
        let weather = try XCTUnwrap(tools["weather"])
        XCTAssertEqual(weather["id"]?.stringValue, "weather")
        XCTAssertEqual(weather["description"]?.stringValue, "Returns the weather")
        XCTAssertEqual(weather["inputSchema"]?["type"]?.stringValue, "object")
    }

    // MARK: - stream

    func testStreamConsumesMDSChunks() async throws {
        let sse = """
        data: {"type":"text-delta","payload":{"text":"hi"}}

        data: {"type":"finish","payload":{}}

        data: [DONE]

        """
        let (client, _) = try makeClient(streamingHandler: { _ in
            HTTPStreamingResponse(
                status: 200, statusText: "OK", headers: [:],
                bytes: MockTransport.bytes(sse)
            )
        })
        let agent = client.agent(id: "s1")
        let stream = try await agent.stream(
            GenerateParams(messages: .array([]))
        )
        var chunks: [JSONValue] = []
        for try await chunk in stream { chunks.append(chunk) }
        XCTAssertEqual(chunks.count, 2)
        XCTAssertEqual(chunks[0]["type"]?.stringValue, "text-delta")
        XCTAssertEqual(chunks[1]["type"]?.stringValue, "finish")
    }

    // MARK: - executeTool

    func testExecuteToolPostsShape() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["ok": true])
        })
        let agent = client.agent(id: "a1")
        _ = try await agent.executeTool(
            toolId: "greet",
            data: .object(["name": .string("Ada")])
        )
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/agents/a1/tools/greet/execute")
        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["data"]?["name"]?.stringValue, "Ada")
    }

    // MARK: - versions

    func testListVersionsGetsStoredAgentsPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "versions": [],
                "total": 0,
                "page": 1,
                "hasMore": false,
            ])
        })
        let agent = client.agent(id: "a1")
        _ = try await agent.listVersions(
            ListAgentVersionsParams(page: 2, perPage: 25, orderBy: .versionNumber, sortDirection: .DESC)
        )
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/stored/agents/a1/versions")
        XCTAssertTrue(req.query.contains(.init(name: "page", value: "2")))
        XCTAssertTrue(req.query.contains(.init(name: "sortDirection", value: "DESC")))
    }

    // MARK: - model updates

    func testUpdateModelPostsBody() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["message": "ok"])
        })
        let agent = client.agent(id: "a1")
        let resp = try await agent.updateModel(
            UpdateModelParams(modelId: "gpt-4", provider: "openai")
        )
        XCTAssertEqual(resp.message, "ok")
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.fullPath, "/api/agents/a1/model")
        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["modelId"]?.stringValue, "gpt-4")
        XCTAssertEqual(body["provider"]?.stringValue, "openai")
    }

    func testReorderModelListPostsBody() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["message": "ok"])
        })
        let agent = client.agent(id: "a1")
        _ = try await agent.reorderModelList(
            ReorderModelListParams(reorderedModelIds: ["a", "b", "c"])
        )
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.fullPath, "/api/agents/a1/models/reorder")
        let body = try XCTUnwrap(self.decodeBody(req))
        let ids = try XCTUnwrap(body["reorderedModelIds"]?.arrayValue)
        XCTAssertEqual(ids.compactMap { $0.stringValue }, ["a", "b", "c"])
    }

    // MARK: - top-level listAgents

    func testListAgentsPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([:])
        })
        _ = try await client.listAgents()
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.fullPath, "/api/agents")
    }

    func testListAgentsModelProvidersPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["providers": []])
        })
        _ = try await client.listAgentsModelProviders()
        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.fullPath, "/api/agents/providers")
    }
}

// Helper: thread-safe counter for test expectations.
final class Counter: @unchecked Sendable {
    private let lock = NSLock()
    private var _value = 0
    var value: Int { lock.lock(); defer { lock.unlock() }; return _value }
    func increment() { lock.lock(); _value += 1; lock.unlock() }
}
