import Foundation
import EkoCore

/// Reusable test data fixtures for consistent testing
enum TestFixtures {
    // MARK: - Test IDs
    static let testUserId = UUID(uuidString: "12345678-1234-1234-1234-123456789012")!
    static let testChildId = UUID(uuidString: "87654321-4321-4321-4321-210987654321")!
    static let testChildId2 = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!

    // MARK: - User Fixtures

    static var testUser: User {
        User(
            id: testUserId,
            email: "test@example.com",
            createdAt: Date(),
            updatedAt: Date(),
            displayName: "Test Parent",
            avatarURL: nil,
            onboardingState: .notStarted,
            currentChildId: nil
        )
    }

    static var testUserWithOnboardingComplete: User {
        User(
            id: testUserId,
            email: "test@example.com",
            createdAt: Date(),
            updatedAt: Date(),
            displayName: "Test Parent",
            avatarURL: nil,
            onboardingState: .complete,
            currentChildId: nil
        )
    }

    static var testUserInProgress: User {
        User(
            id: testUserId,
            email: "test@example.com",
            createdAt: Date(),
            updatedAt: Date(),
            displayName: "Test Parent",
            avatarURL: nil,
            onboardingState: .goals,
            currentChildId: testChildId
        )
    }

    // MARK: - UserProfile Fixtures

    static var testUserProfile: UserProfile {
        UserProfile(
            id: testUserId,
            onboardingState: .notStarted,
            currentChildId: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    static var testUserProfileComplete: UserProfile {
        UserProfile(
            id: testUserId,
            onboardingState: .complete,
            currentChildId: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    static var testUserProfileInProgress: UserProfile {
        UserProfile(
            id: testUserId,
            onboardingState: .goals,
            currentChildId: testChildId,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    // MARK: - Child Fixtures

    static var testChild: Child {
        Child(
            id: testChildId,
            userId: testUserId,
            name: "Test Child",
            age: 10,
            birthday: Calendar.current.date(byAdding: .year, value: -10, to: Date())!,
            goals: ["Understanding their thoughts and feelings better"],
            topics: ["emotions", "friends", "school"],
            temperament: .easygoing,
            temperamentTalkative: 7,
            temperamentSensitivity: 5,
            temperamentAccountability: 8,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    static var testChild2: Child {
        Child(
            id: testChildId2,
            userId: testUserId,
            name: "Second Child",
            age: 8,
            birthday: Calendar.current.date(byAdding: .year, value: -8, to: Date())!,
            goals: [
                "Helping them navigate challenges",
                "Connecting with them on a deeper level"
            ],
            topics: ["family", "conflict", "values", "confidence"],
            temperament: .spirited,
            temperamentTalkative: 4,
            temperamentSensitivity: 8,
            temperamentAccountability: 6,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    static var testChildMinimal: Child {
        Child(
            id: UUID(),
            userId: testUserId,
            name: "Minimal Child",
            age: 5,
            birthday: Calendar.current.date(byAdding: .year, value: -5, to: Date())!,
            goals: ["Supporting their mental and emotional well-being"],
            topics: ["emotions", "health", "creativity"],
            temperament: .easygoing,
            temperamentTalkative: 5,
            temperamentSensitivity: 5,
            temperamentAccountability: 5,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    // MARK: - Test Data Arrays

    static var testGoals: [String] {
        [
            "Understanding their thoughts and feelings better",
            "Helping them navigate challenges",
            "Connecting with them on a deeper level"
        ]
    }

    static var testTopics: [String] {
        ["emotions", "friends", "school"]
    }

    static var testTopicsMany: [String] {
        ["emotions", "friends", "school", "family", "conflict", "values"]
    }

    // MARK: - Date Helpers

    static func childBirthday(yearsAgo: Int) -> Date {
        Calendar.current.date(byAdding: .year, value: -yearsAgo, to: Date())!
    }

    static func recentDate(daysAgo: Int = 0) -> Date {
        Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
    }
}
