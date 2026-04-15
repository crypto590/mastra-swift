import Foundation

/// Equivalent of JS `StoredSkill` resource. No version endpoints; exposes
/// only `details` / `update` / `delete`.
public struct StoredSkill: Sendable {
    public let storedSkillId: String
    let base: BaseResource

    init(base: BaseResource, storedSkillId: String) {
        self.base = base
        self.storedSkillId = storedSkillId
    }

    private var rootPath: String { "/stored/skills/\(storedSkillId)" }

    /// Mirrors JS `storedSkill.details()`.
    public func details() async throws -> StoredSkillResponse {
        try await base.request(rootPath)
    }

    /// Mirrors JS `storedSkill.update(params)`.
    public func update(
        _ params: UpdateStoredSkillParams
    ) async throws -> StoredSkillResponse {
        try await base.request(rootPath, method: .PATCH, body: .json(params.body()))
    }

    /// Mirrors JS `storedSkill.delete()`.
    public func delete() async throws -> DeleteStoredSkillResponse {
        try await base.request(rootPath, method: .DELETE)
    }
}
