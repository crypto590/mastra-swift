import Foundation

/// A single bubble in the chat transcript.
struct ChatMessage: Identifiable, Hashable, Sendable {
    enum Role: String, Sendable { case user, assistant }

    let id: UUID
    let role: Role
    var text: String

    init(id: UUID = UUID(), role: Role, text: String) {
        self.id = id
        self.role = role
        self.text = text
    }
}
