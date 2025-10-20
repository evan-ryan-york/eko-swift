import Foundation

/// Extended user profile data including onboarding state
public struct UserProfile: Codable, Identifiable, Sendable {
    public let id: UUID
    public var onboardingState: OnboardingState
    public var currentChildId: UUID?
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID,
        onboardingState: OnboardingState,
        currentChildId: UUID? = nil,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.onboardingState = onboardingState
        self.currentChildId = currentChildId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case onboardingState = "onboarding_state"
        case currentChildId = "current_child_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
