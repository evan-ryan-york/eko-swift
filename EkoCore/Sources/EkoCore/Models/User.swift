import Foundation

// MARK: - User Model
public struct User: Codable, Identifiable, Sendable {
    public let id: UUID
    public let email: String
    public let createdAt: Date
    public var updatedAt: Date
    public var displayName: String?
    public var avatarURL: URL?

    public init(
        id: UUID,
        email: String,
        createdAt: Date,
        updatedAt: Date,
        displayName: String? = nil,
        avatarURL: URL? = nil
    ) {
        self.id = id
        self.email = email
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.displayName = displayName
        self.avatarURL = avatarURL
    }

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case displayName = "display_name"
        case avatarURL = "avatar_url"
    }
}
