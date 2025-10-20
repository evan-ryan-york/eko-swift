import Foundation

/// Represents the current step in the user onboarding flow
public enum OnboardingState: String, Codable, Sendable {
    case notStarted = "NOT_STARTED"
    case userInfo = "USER_INFO"
    case childInfo = "CHILD_INFO"
    case goals = "GOALS"
    case topics = "TOPICS"
    case dispositions = "DISPOSITIONS"
    case review = "REVIEW"
    case complete = "COMPLETE"

    /// Human-readable description of the step
    public var description: String {
        switch self {
        case .notStarted: return "Not Started"
        case .userInfo: return "User Information"
        case .childInfo: return "Child Information"
        case .goals: return "Conversation Goals"
        case .topics: return "Conversation Topics"
        case .dispositions: return "Child's Disposition"
        case .review: return "Review"
        case .complete: return "Complete"
        }
    }

    /// Whether onboarding is finished
    public var isComplete: Bool {
        return self == .complete
    }

    /// Get next state in the flow (nil if at end)
    public func next() -> OnboardingState? {
        switch self {
        case .notStarted: return .userInfo
        case .userInfo: return .childInfo
        case .childInfo: return .goals
        case .goals: return .topics
        case .topics: return .dispositions
        case .dispositions: return .review
        case .review: return .complete
        case .complete: return nil
        }
    }

    /// Get previous state in the flow (nil if at beginning)
    public func previous() -> OnboardingState? {
        switch self {
        case .notStarted: return nil
        case .userInfo: return nil // Can't go back from first step
        case .childInfo: return .userInfo
        case .goals: return .childInfo
        case .topics: return .goals
        case .dispositions: return .topics
        case .review: return nil // Can't go back from review
        case .complete: return nil
        }
    }
}
