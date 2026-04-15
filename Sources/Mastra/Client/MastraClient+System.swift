import Foundation

public extension MastraClient {
    /// Mirrors JS `client.getSystemPackages()` → `GET /system/packages`.
    nonisolated func systemPackages() async throws -> GetSystemPackagesResponse {
        try await base.request("/system/packages")
    }
}
