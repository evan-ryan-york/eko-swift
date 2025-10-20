import XCTest
@testable import Eko
import EkoCore

final class ConversationTopicTests: XCTestCase {

    // MARK: - All Topics Tests

    func test_all_containsExpectedCount() {
        XCTAssertEqual(ConversationTopics.all.count, 12)
    }

    func test_all_containsExpectedTopicIds() {
        let ids = ConversationTopics.all.map { $0.id }

        XCTAssertTrue(ids.contains("emotions"))
        XCTAssertTrue(ids.contains("friends"))
        XCTAssertTrue(ids.contains("school"))
        XCTAssertTrue(ids.contains("family"))
        XCTAssertTrue(ids.contains("conflict"))
        XCTAssertTrue(ids.contains("values"))
        XCTAssertTrue(ids.contains("confidence"))
        XCTAssertTrue(ids.contains("health"))
        XCTAssertTrue(ids.contains("diversity"))
        XCTAssertTrue(ids.contains("future"))
        XCTAssertTrue(ids.contains("technology"))
        XCTAssertTrue(ids.contains("creativity"))
    }

    func test_all_hasUniqueIds() {
        let ids = ConversationTopics.all.map { $0.id }
        let uniqueIds = Set(ids)

        XCTAssertEqual(ids.count, uniqueIds.count, "Topic IDs should be unique")
    }

    // MARK: - Display Name Tests

    func test_displayNames_areNotEmpty() {
        for topic in ConversationTopics.all {
            XCTAssertFalse(topic.displayName.isEmpty, "Display name should not be empty for \(topic.id)")
        }
    }

    func test_specificTopics_haveCorrectDisplayNames() {
        XCTAssertEqual(
            ConversationTopics.all.first(where: { $0.id == "emotions" })?.displayName,
            "Emotions & Feelings"
        )
        XCTAssertEqual(
            ConversationTopics.all.first(where: { $0.id == "friends" })?.displayName,
            "Friendship & Relationships"
        )
        XCTAssertEqual(
            ConversationTopics.all.first(where: { $0.id == "school" })?.displayName,
            "School & Learning"
        )
        XCTAssertEqual(
            ConversationTopics.all.first(where: { $0.id == "family" })?.displayName,
            "Family Dynamics"
        )
        XCTAssertEqual(
            ConversationTopics.all.first(where: { $0.id == "conflict" })?.displayName,
            "Conflict Resolution"
        )
    }

    // MARK: - displayName(for:) Helper Tests

    func test_displayNameFor_returnsCorrectName_forValidId() {
        XCTAssertEqual(ConversationTopics.displayName(for: "emotions"), "Emotions & Feelings")
        XCTAssertEqual(ConversationTopics.displayName(for: "technology"), "Technology & Screen Time")
        XCTAssertEqual(ConversationTopics.displayName(for: "creativity"), "Creativity & Imagination")
    }

    func test_displayNameFor_returnsId_forInvalidId() {
        XCTAssertEqual(ConversationTopics.displayName(for: "invalid_topic"), "invalid_topic")
        XCTAssertEqual(ConversationTopics.displayName(for: ""), "")
        XCTAssertEqual(ConversationTopics.displayName(for: "nonexistent"), "nonexistent")
    }

    // MARK: - Topic Structure Tests

    func test_topic_conformsToIdentifiable() {
        let topic = ConversationTopics.all.first!

        // Should be able to use in ForEach and other SwiftUI components
        XCTAssertEqual(topic.id, topic.id)
    }

    func test_allTopics_matchFeatureSpec() {
        // Verify all topics from feature specification are present
        let expectedTopics: [String: String] = [
            "emotions": "Emotions & Feelings",
            "friends": "Friendship & Relationships",
            "school": "School & Learning",
            "family": "Family Dynamics",
            "conflict": "Conflict Resolution",
            "values": "Values & Ethics",
            "confidence": "Self-Confidence",
            "health": "Health & Wellness",
            "diversity": "Diversity & Inclusion",
            "future": "Future & Goals",
            "technology": "Technology & Screen Time",
            "creativity": "Creativity & Imagination"
        ]

        for (expectedId, expectedName) in expectedTopics {
            let topic = ConversationTopics.all.first(where: { $0.id == expectedId })
            XCTAssertNotNil(topic, "Topic with id '\(expectedId)' should exist")
            XCTAssertEqual(topic?.displayName, expectedName, "Display name mismatch for '\(expectedId)'")
        }
    }
}
