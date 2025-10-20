import XCTest
@testable import Eko
import EkoCore

final class OnboardingStateTests: XCTestCase {

    // MARK: - Raw Value Tests

    func test_rawValues_matchDatabaseValues() {
        XCTAssertEqual(OnboardingState.notStarted.rawValue, "NOT_STARTED")
        XCTAssertEqual(OnboardingState.userInfo.rawValue, "USER_INFO")
        XCTAssertEqual(OnboardingState.childInfo.rawValue, "CHILD_INFO")
        XCTAssertEqual(OnboardingState.goals.rawValue, "GOALS")
        XCTAssertEqual(OnboardingState.topics.rawValue, "TOPICS")
        XCTAssertEqual(OnboardingState.dispositions.rawValue, "DISPOSITIONS")
        XCTAssertEqual(OnboardingState.review.rawValue, "REVIEW")
        XCTAssertEqual(OnboardingState.complete.rawValue, "COMPLETE")
    }

    // MARK: - Description Tests

    func test_description_returnsReadableNames() {
        XCTAssertEqual(OnboardingState.notStarted.description, "Not Started")
        XCTAssertEqual(OnboardingState.userInfo.description, "User Information")
        XCTAssertEqual(OnboardingState.childInfo.description, "Child Information")
        XCTAssertEqual(OnboardingState.goals.description, "Conversation Goals")
        XCTAssertEqual(OnboardingState.topics.description, "Conversation Topics")
        XCTAssertEqual(OnboardingState.dispositions.description, "Child's Disposition")
        XCTAssertEqual(OnboardingState.review.description, "Review")
        XCTAssertEqual(OnboardingState.complete.description, "Complete")
    }

    // MARK: - isComplete Tests

    func test_isComplete_returnsTrueForCompleteState() {
        XCTAssertTrue(OnboardingState.complete.isComplete)
    }

    func test_isComplete_returnsFalseForNonCompleteStates() {
        XCTAssertFalse(OnboardingState.notStarted.isComplete)
        XCTAssertFalse(OnboardingState.userInfo.isComplete)
        XCTAssertFalse(OnboardingState.childInfo.isComplete)
        XCTAssertFalse(OnboardingState.goals.isComplete)
        XCTAssertFalse(OnboardingState.topics.isComplete)
        XCTAssertFalse(OnboardingState.dispositions.isComplete)
        XCTAssertFalse(OnboardingState.review.isComplete)
    }

    // MARK: - next() Tests

    func test_next_returnsCorrectSequence() {
        XCTAssertEqual(OnboardingState.notStarted.next(), .userInfo)
        XCTAssertEqual(OnboardingState.userInfo.next(), .childInfo)
        XCTAssertEqual(OnboardingState.childInfo.next(), .goals)
        XCTAssertEqual(OnboardingState.goals.next(), .topics)
        XCTAssertEqual(OnboardingState.topics.next(), .dispositions)
        XCTAssertEqual(OnboardingState.dispositions.next(), .review)
        XCTAssertEqual(OnboardingState.review.next(), .complete)
    }

    func test_next_returnsNil_whenAtCompleteState() {
        XCTAssertNil(OnboardingState.complete.next())
    }

    // MARK: - previous() Tests

    func test_previous_returnsCorrectSequence() {
        XCTAssertEqual(OnboardingState.childInfo.previous(), .userInfo)
        XCTAssertEqual(OnboardingState.goals.previous(), .childInfo)
        XCTAssertEqual(OnboardingState.topics.previous(), .goals)
        XCTAssertEqual(OnboardingState.dispositions.previous(), .topics)
    }

    func test_previous_returnsNil_whenAtFirstStep() {
        XCTAssertNil(OnboardingState.notStarted.previous())
        XCTAssertNil(OnboardingState.userInfo.previous())
    }

    func test_previous_returnsNil_whenAtReviewOrComplete() {
        XCTAssertNil(OnboardingState.review.previous())
        XCTAssertNil(OnboardingState.complete.previous())
    }

    // MARK: - Codable Tests

    func test_encoding_producesCorrectRawValue() throws {
        let state = OnboardingState.childInfo
        let encoder = JSONEncoder()
        let data = try encoder.encode(state)
        let jsonString = String(data: data, encoding: .utf8)

        XCTAssertEqual(jsonString, "\"CHILD_INFO\"")
    }

    func test_decoding_fromRawValue() throws {
        let jsonString = "\"GOALS\""
        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let state = try decoder.decode(OnboardingState.self, from: data)

        XCTAssertEqual(state, .goals)
    }

    func test_decoding_allStates() throws {
        let testCases: [(String, OnboardingState)] = [
            ("\"NOT_STARTED\"", .notStarted),
            ("\"USER_INFO\"", .userInfo),
            ("\"CHILD_INFO\"", .childInfo),
            ("\"GOALS\"", .goals),
            ("\"TOPICS\"", .topics),
            ("\"DISPOSITIONS\"", .dispositions),
            ("\"REVIEW\"", .review),
            ("\"COMPLETE\"", .complete)
        ]

        let decoder = JSONDecoder()

        for (jsonString, expectedState) in testCases {
            let data = jsonString.data(using: .utf8)!
            let state = try decoder.decode(OnboardingState.self, from: data)
            XCTAssertEqual(state, expectedState, "Failed to decode \(jsonString)")
        }
    }

    // MARK: - Flow Validation Tests

    func test_fullFlowSequence_reachesComplete() {
        var state: OnboardingState = .notStarted
        let expectedSequence: [OnboardingState] = [
            .notStarted, .userInfo, .childInfo, .goals,
            .topics, .dispositions, .review, .complete
        ]

        var actualSequence: [OnboardingState] = [state]

        while let nextState = state.next() {
            state = nextState
            actualSequence.append(state)
        }

        XCTAssertEqual(actualSequence, expectedSequence)
    }

    func test_backNavigation_stopsAtUserInfo() {
        var state: OnboardingState = .dispositions
        let steps: [OnboardingState] = [
            .dispositions, .topics, .goals, .childInfo, .userInfo
        ]

        var actualSteps: [OnboardingState] = [state]

        while let prevState = state.previous() {
            state = prevState
            actualSteps.append(state)
        }

        XCTAssertEqual(actualSteps, steps)
    }
}
