import Foundation

// MARK: - User Model
public struct User: Codable, Identifiable, Sendable {
    public let id: UUID
    public let email: String
    public let createdAt: Date
    public var updatedAt: Date
    public var displayName: String?
    public var avatarURL: URL?

    // Onboarding-related fields
    public var onboardingState: OnboardingState
    public var currentChildId: UUID?

    public init(
        id: UUID,
        email: String,
        createdAt: Date,
        updatedAt: Date,
        displayName: String? = nil,
        avatarURL: URL? = nil,
        onboardingState: OnboardingState = .notStarted,
        currentChildId: UUID? = nil
    ) {
        self.id = id
        self.email = email
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.onboardingState = onboardingState
        self.currentChildId = currentChildId
    }

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case displayName = "display_name"
        case avatarURL = "avatar_url"
        case onboardingState = "onboarding_state"
        case currentChildId = "current_child_id"
    }
}
