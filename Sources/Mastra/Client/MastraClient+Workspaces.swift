import Foundation

public extension MastraClient {
    /// Mirrors JS `client.listWorkspaces()` → `GET /workspaces`. Returns the
    /// full response envelope (`{ workspaces: [...] }`).
    nonisolated func listWorkspaces() async throws -> ListWorkspacesResponse {
        try await base.request("/workspaces")
    }

    /// Mirrors JS `client.getWorkspace(workspaceId)`. Returns a `Workspace`
    /// handle — no network call is made.
    nonisolated func workspace(id: String) -> Workspace {
        Workspace(base: base, workspaceId: id)
    }
}
