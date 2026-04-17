import Foundation

protocol ThreadStore: Sendable {
    func load() -> ThreadIdentity
    func save(_ identity: ThreadIdentity)
    func reset()
}

struct ThreadIdentity: Sendable, Equatable {
    var threadId: String?
    var resourceId: String

    static func fresh() -> ThreadIdentity {
        ThreadIdentity(threadId: nil, resourceId: UUID().uuidString)
    }
}

struct UserDefaultsThreadStore: ThreadStore, @unchecked Sendable {
    static let threadKey = "mastra.showcase.threadId"
    static let resourceKey = "mastra.showcase.resourceId"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> ThreadIdentity {
        let threadId = defaults.string(forKey: Self.threadKey)
        if let existing = defaults.string(forKey: Self.resourceKey) {
            return ThreadIdentity(threadId: threadId, resourceId: existing)
        }
        let fresh = ThreadIdentity.fresh()
        defaults.set(fresh.resourceId, forKey: Self.resourceKey)
        return fresh
    }

    func save(_ identity: ThreadIdentity) {
        defaults.set(identity.resourceId, forKey: Self.resourceKey)
        if let threadId = identity.threadId {
            defaults.set(threadId, forKey: Self.threadKey)
        } else {
            defaults.removeObject(forKey: Self.threadKey)
        }
    }

    func reset() {
        defaults.removeObject(forKey: Self.threadKey)
        defaults.removeObject(forKey: Self.resourceKey)
    }
}

