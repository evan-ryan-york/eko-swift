import Foundation

// MARK: - Conversation Status
public enum ConversationStatus: String, Codable, Sendable {
    case active
    case completed
}

// MARK: - Conversation
public struct Conversation: Identifiable, Codable, Sendable {
    public let id: UUID
    public let userId: UUID
    public let childId: UUID
    public var status: ConversationStatus
    public var title: String?
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID,
        userId: UUID,
        childId: UUID,
        status: ConversationStatus,
        title: String? = nil,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.userId = userId
        self.childId = childId
        self.status = status
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case childId = "child_id"
        case status
        case title
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
