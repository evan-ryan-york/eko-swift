import Foundation

// MARK: - Message Role
public enum MessageRole: String, Codable, Sendable {
    case user
    case assistant
    case system
}

// MARK: - Citation
public struct Citation: Codable, Identifiable, Sendable {
    public let id: UUID
    public let title: String
    public let url: URL?
    public let excerpt: String

    public init(
        id: UUID,
        title: String,
        url: URL?,
        excerpt: String
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.excerpt = excerpt
    }
}

// MARK: - Message
public struct Message: Identifiable, Codable, Sendable {
    public let id: UUID
    public let conversationId: UUID?
    public let role: MessageRole
    public var content: String
    public let timestamp: Date
    public var sources: [Citation]?

    public init(
        id: UUID,
        conversationId: UUID? = nil,
        role: MessageRole,
        content: String,
        timestamp: Date,
        sources: [Citation]? = nil
    ) {
        self.id = id
        self.conversationId = conversationId
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.sources = sources
    }

    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case role
        case content
        case timestamp = "created_at"
        case sources
    }
}
