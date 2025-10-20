import Foundation

/// Represents a conversation topic that can be selected during onboarding
public struct ConversationTopic: Identifiable, Sendable {
    public let id: String
    public let displayName: String

    public init(id: String, displayName: String) {
        self.id = id
        self.displayName = displayName
    }
}

/// All available conversation topics
public enum ConversationTopics {
    public static let all: [ConversationTopic] = [
        ConversationTopic(id: "emotions", displayName: "Emotions & Feelings"),
        ConversationTopic(id: "friends", displayName: "Friendship & Relationships"),
        ConversationTopic(id: "school", displayName: "School & Learning"),
        ConversationTopic(id: "family", displayName: "Family Dynamics"),
        ConversationTopic(id: "conflict", displayName: "Conflict Resolution"),
        ConversationTopic(id: "values", displayName: "Values & Ethics"),
        ConversationTopic(id: "confidence", displayName: "Self-Confidence"),
        ConversationTopic(id: "health", displayName: "Health & Wellness"),
        ConversationTopic(id: "diversity", displayName: "Diversity & Inclusion"),
        ConversationTopic(id: "future", displayName: "Future & Goals"),
        ConversationTopic(id: "technology", displayName: "Technology & Screen Time"),
        ConversationTopic(id: "creativity", displayName: "Creativity & Imagination")
    ]

    /// Get display name from topic ID
    public static func displayName(for id: String) -> String {
        return all.first { $0.id == id }?.displayName ?? id
    }

    /// Get topic by ID
    public static func topic(for id: String) -> ConversationTopic? {
        return all.first { $0.id == id }
    }
}
