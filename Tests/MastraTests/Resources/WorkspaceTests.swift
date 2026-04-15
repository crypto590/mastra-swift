import XCTest
@testable import Mastra
import MastraTestingSupport

final class WorkspaceTests: XCTestCase {
    // MARK: - Helpers

    private func makeClient(
        handler: @escaping MockTransport.Handler
    ) throws -> (MastraClient, MockTransport) {
        let mock = MockTransport(
            handler: handler,
            streamingHandler: { _ in
                HTTPStreamingResponse(
                    status: 200, statusText: "OK", headers: [:],
                    bytes: AsyncThrowingStream { $0.finish() }
                )
            }
        )
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

    // MARK: - info

    func testInfoGetsWorkspacesPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "isWorkspaceConfigured": true,
                "id": "ws-1",
                "name": "Default",
                "status": "ready",
                "capabilities": [
                    "hasFilesystem": true,
                    "hasSandbox": false,
                    "canBM25": true,
                    "canVector": false,
                    "canHybrid": false,
                    "hasSkills": true,
                ],
                "safety": ["readOnly": false],
            ])
        })
        let workspace = client.workspace(id: "ws-1")
        let info = try await workspace.info()
        XCTAssertTrue(info.isWorkspaceConfigured)
        XCTAssertEqual(info.id, "ws-1")
        XCTAssertEqual(info.capabilities?.hasSkills, true)
        XCTAssertEqual(info.safety?.readOnly, false)

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/workspaces/ws-1")
    }

    // MARK: - fs.readFile

    func testReadFileGetsFsReadWithQuery() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "path": "/notes.md",
                "content": "hello",
                "type": "file",
                "size": 5,
                "mimeType": "text/markdown",
            ])
        })
        let workspace = client.workspace(id: "ws-1")
        let response = try await workspace.readFile(path: "/notes.md", encoding: "utf-8")
        XCTAssertEqual(response.content, "hello")
        XCTAssertEqual(response.type, .file)

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/workspaces/ws-1/fs/read")
        XCTAssertTrue(req.query.contains(.init(name: "path", value: "/notes.md")))
        XCTAssertTrue(req.query.contains(.init(name: "encoding", value: "utf-8")))
    }

    // MARK: - fs.writeFile

    func testWriteFilePostsBody() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["success": true, "path": "/out.txt"])
        })
        let workspace = client.workspace(id: "ws-1")
        let response = try await workspace.writeFile(
            path: "/out.txt",
            content: "data",
            options: WorkspaceWriteOptions(encoding: .utf8, recursive: true)
        )
        XCTAssertTrue(response.success)
        XCTAssertEqual(response.path, "/out.txt")

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/workspaces/ws-1/fs/write")
        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["path"]?.stringValue, "/out.txt")
        XCTAssertEqual(body["content"]?.stringValue, "data")
        XCTAssertEqual(body["encoding"]?.stringValue, "utf-8")
        XCTAssertEqual(body["recursive"]?.boolValue, true)
    }

    // MARK: - fs.listFiles

    func testListFilesGetsFsListWithRecursive() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "path": "/",
                "entries": [
                    ["name": "a.txt", "type": "file", "size": 3],
                    ["name": "dir", "type": "directory"],
                ],
            ])
        })
        let workspace = client.workspace(id: "ws-1")
        let response = try await workspace.listFiles(path: "/", recursive: true)
        XCTAssertEqual(response.entries.count, 2)
        XCTAssertEqual(response.entries[0].name, "a.txt")
        XCTAssertEqual(response.entries[0].type, .file)
        XCTAssertEqual(response.entries[1].type, .directory)

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/workspaces/ws-1/fs/list")
        XCTAssertTrue(req.query.contains(.init(name: "path", value: "/")))
        XCTAssertTrue(req.query.contains(.init(name: "recursive", value: "true")))
    }

    // MARK: - fs.delete

    func testDeleteUsesDeleteMethodWithQuery() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["success": true, "path": "/junk"])
        })
        let workspace = client.workspace(id: "ws-1")
        _ = try await workspace.delete(
            path: "/junk",
            options: WorkspaceDeleteOptions(recursive: true, force: true)
        )

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .DELETE)
        XCTAssertEqual(req.fullPath, "/api/workspaces/ws-1/fs/delete")
        XCTAssertTrue(req.query.contains(.init(name: "path", value: "/junk")))
        XCTAssertTrue(req.query.contains(.init(name: "recursive", value: "true")))
        XCTAssertTrue(req.query.contains(.init(name: "force", value: "true")))
    }

    // MARK: - fs.mkdir

    func testMkdirPostsBody() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["success": true, "path": "/new-dir"])
        })
        let workspace = client.workspace(id: "ws-1")
        _ = try await workspace.mkdir(path: "/new-dir", recursive: true)

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/workspaces/ws-1/fs/mkdir")
        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["path"]?.stringValue, "/new-dir")
        XCTAssertEqual(body["recursive"]?.boolValue, true)
    }

    // MARK: - fs.stat

    func testStatGetsFsStat() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "path": "/file.md",
                "type": "file",
                "size": 42,
            ])
        })
        let workspace = client.workspace(id: "ws-1")
        let response = try await workspace.stat(path: "/file.md")
        XCTAssertEqual(response.size, 42)
        XCTAssertEqual(response.type, .file)

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/workspaces/ws-1/fs/stat")
        XCTAssertTrue(req.query.contains(.init(name: "path", value: "/file.md")))
    }

    // MARK: - search

    func testSearchGetsWithQuery() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "results": [
                    [
                        "id": "doc-1",
                        "content": "match",
                        "score": 0.9,
                    ]
                ],
                "query": "needle",
                "mode": "hybrid",
            ])
        })
        let workspace = client.workspace(id: "ws-1")
        let response = try await workspace.search(
            WorkspaceSearchParams(query: "needle", topK: 5, mode: .hybrid, minScore: 0.5)
        )
        XCTAssertEqual(response.results.count, 1)
        XCTAssertEqual(response.mode, .hybrid)
        XCTAssertEqual(response.results[0].id, "doc-1")

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/workspaces/ws-1/search")
        XCTAssertTrue(req.query.contains(.init(name: "query", value: "needle")))
        XCTAssertTrue(req.query.contains(.init(name: "topK", value: "5")))
        XCTAssertTrue(req.query.contains(.init(name: "mode", value: "hybrid")))
        XCTAssertTrue(req.query.contains(.init(name: "minScore", value: "0.5")))
    }

    // MARK: - index

    func testIndexPostsBody() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["success": true, "path": "/doc.md"])
        })
        let workspace = client.workspace(id: "ws-1")
        _ = try await workspace.index(
            WorkspaceIndexParams(
                path: "/doc.md",
                content: "body",
                metadata: ["tag": .string("note")]
            )
        )

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.fullPath, "/api/workspaces/ws-1/index")
        let body = try XCTUnwrap(self.decodeBody(req))
        XCTAssertEqual(body["path"]?.stringValue, "/doc.md")
        XCTAssertEqual(body["content"]?.stringValue, "body")
        XCTAssertEqual(body["metadata"]?["tag"]?.stringValue, "note")
    }

    // MARK: - skills list

    func testListSkillsGetsSkillsPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "skills": [
                    [
                        "name": "web-search",
                        "description": "Searches the web",
                        "path": "/skills/web-search",
                    ]
                ],
                "isSkillsConfigured": true,
            ])
        })
        let workspace = client.workspace(id: "ws-1")
        let response = try await workspace.listSkills()
        XCTAssertTrue(response.isSkillsConfigured)
        XCTAssertEqual(response.skills.count, 1)
        XCTAssertEqual(response.skills[0].name, "web-search")

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/workspaces/ws-1/skills")
    }

    // MARK: - skills search

    func testSearchSkillsBuildsQuery() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["results": [], "query": "q"])
        })
        let workspace = client.workspace(id: "ws-1")
        _ = try await workspace.searchSkills(
            SearchSkillsParams(
                query: "q",
                topK: 3,
                minScore: 0.1,
                skillNames: ["a", "b"],
                includeReferences: true
            )
        )

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/workspaces/ws-1/skills/search")
        XCTAssertTrue(req.query.contains(.init(name: "query", value: "q")))
        XCTAssertTrue(req.query.contains(.init(name: "topK", value: "3")))
        XCTAssertTrue(req.query.contains(.init(name: "minScore", value: "0.1")))
        XCTAssertTrue(req.query.contains(.init(name: "skillNames", value: "a,b")))
        XCTAssertTrue(req.query.contains(.init(name: "includeReferences", value: "true")))
    }

    // MARK: - skill details

    func testSkillDetailsGetsSkillPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "name": "web-search",
                "description": "Searches the web",
                "path": "/skills/web-search",
                "instructions": "do the thing",
                "source": ["type": "managed", "mastraPath": "/mastra/skills/web-search"],
                "references": ["ref.md"],
                "scripts": [],
                "assets": [],
            ])
        })
        let workspace = client.workspace(id: "ws-1")
        let skill = workspace.skill(name: "web-search")
        let details = try await skill.details()
        XCTAssertEqual(details.name, "web-search")
        XCTAssertEqual(details.instructions, "do the thing")
        if case .managed(let mastraPath) = details.source {
            XCTAssertEqual(mastraPath, "/mastra/skills/web-search")
        } else {
            XCTFail("expected managed source")
        }

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/workspaces/ws-1/skills/web-search")
        XCTAssertFalse(req.query.contains(where: { $0.name == "path" }))
    }

    func testSkillDetailsAppendsPathQueryWhenProvided() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "name": "web-search",
                "description": "Searches the web",
                "path": "/skills/web-search",
                "instructions": "x",
                "source": ["type": "local", "projectPath": "/proj/skills/web-search"],
                "references": [],
                "scripts": [],
                "assets": [],
            ])
        })
        let workspace = client.workspace(id: "ws-1")
        let skill = workspace.skill(name: "web-search", path: "/proj/skills/web-search")
        _ = try await skill.details()

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.fullPath, "/api/workspaces/ws-1/skills/web-search")
        XCTAssertTrue(req.query.contains(.init(name: "path", value: "/proj/skills/web-search")))
    }

    // MARK: - skill references

    func testListReferencesGetsReferencesPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "skillName": "web-search",
                "references": ["ref1.md", "ref2.md"],
            ])
        })
        let workspace = client.workspace(id: "ws-1")
        let response = try await workspace.skill(name: "web-search").listReferences()
        XCTAssertEqual(response.references, ["ref1.md", "ref2.md"])

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.fullPath, "/api/workspaces/ws-1/skills/web-search/references")
    }

    func testGetReferenceEncodesReferencePath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse([
                "skillName": "web-search",
                "referencePath": "refs/a.md",
                "content": "body",
            ])
        })
        let workspace = client.workspace(id: "ws-1")
        let response = try await workspace
            .skill(name: "web-search")
            .getReference(referencePath: "refs/a.md")
        XCTAssertEqual(response.content, "body")

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/workspaces/ws-1/skills/web-search/references/refs/a.md")
    }

    // MARK: - top-level listWorkspaces

    func testListWorkspacesPath() async throws {
        let (client, mock) = try makeClient(handler: { _ in
            self.jsonResponse(["workspaces": []])
        })
        let response = try await client.listWorkspaces()
        XCTAssertEqual(response.workspaces.count, 0)

        let req = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(req.method, .GET)
        XCTAssertEqual(req.fullPath, "/api/workspaces")
    }
}
