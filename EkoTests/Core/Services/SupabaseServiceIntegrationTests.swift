import XCTest
@testable import Eko
import EkoCore

/// Integration tests for SupabaseService
/// These tests use mocks for MVP - can be converted to real Supabase calls post-MVP
@MainActor
final class SupabaseServiceIntegrationTests: XCTestCase {

    var mockService: MockSupabaseService!

    override func setUp() {
        super.setUp()
        mockService = MockSupabaseService()
    }

    override func tearDown() {
        mockService = nil
        super.tearDown()
    }

    // MARK: - User Profile Tests

    func test_getUserProfile_returnsProfile_forAuthenticatedUser() async throws {
        // Given
        mockService.mockUserProfile = TestFixtures.testUserProfile
        mockService.shouldSucceed = true

        // When
        let profile = try await mockService.getUserProfile()

        // Then
        XCTAssertNotNil(profile.id)
        XCTAssertNotNil(profile.onboardingState)
        XCTAssertEqual(profile.onboardingState, .notStarted)
    }

    func test_getUserProfile_throwsError_whenNotAuthenticated() async {
        // Given
        mockService.mockUserProfile = nil
        mockService.shouldSucceed = false

        // When/Then
        do {
            _ = try await mockService.getUserProfile()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error is TestError)
        }
    }

    func test_updateOnboardingState_updatesDatabase() async throws {
        // Given
        let newState = OnboardingState.childInfo
        let childId = UUID()
        mockService.mockUserProfile = TestFixtures.testUserProfile
        mockService.shouldSucceed = true

        // When
        try await mockService.updateOnboardingState(newState, currentChildId: childId)

        // Then
        XCTAssertTrue(mockService.updateOnboardingStateCalled)
        XCTAssertEqual(mockService.capturedOnboardingState, newState)
        XCTAssertEqual(mockService.capturedCurrentChildId, childId)
    }

    func test_updateOnboardingState_handlesNilChildId() async throws {
        // Given
        let newState = OnboardingState.complete
        mockService.mockUserProfile = TestFixtures.testUserProfile
        mockService.shouldSucceed = true

        // When
        try await mockService.updateOnboardingState(newState, currentChildId: nil)

        // Then
        XCTAssertTrue(mockService.updateOnboardingStateCalled)
        XCTAssertEqual(mockService.capturedOnboardingState, newState)
        XCTAssertNil(mockService.capturedCurrentChildId)
    }

    func test_updateDisplayName_updatesUserMetadata() async throws {
        // Given
        let displayName = "Test User"
        mockService.mockUser = TestFixtures.testUser
        mockService.shouldSucceed = true

        // When
        try await mockService.updateDisplayName(displayName)

        // Then
        XCTAssertTrue(mockService.updateDisplayNameCalled)
        XCTAssertEqual(mockService.capturedDisplayName, displayName)
    }

    func test_getCurrentUserWithProfile_returnsCombinedData() async throws {
        // Given
        mockService.mockUser = TestFixtures.testUserWithOnboardingComplete
        mockService.shouldSucceed = true

        // When
        let user = try await mockService.getCurrentUserWithProfile()

        // Then
        XCTAssertNotNil(user)
        XCTAssertEqual(user?.email, "test@example.com")
        XCTAssertEqual(user?.displayName, "Test Parent")
        XCTAssertEqual(user?.onboardingState, .complete)
    }

    // MARK: - Child CRUD Tests

    func test_createChild_savesChildToDatabase() async throws {
        // Given
        let childData = TestFixtures.testChild
        mockService.mockUser = TestFixtures.testUser
        mockService.shouldSucceed = true

        // When
        let createdChild = try await mockService.createChild(
            name: childData.name,
            age: childData.age,
            birthday: childData.birthday,
            goals: childData.goals,
            topics: childData.topics,
            temperament: childData.temperament,
            temperamentTalkative: childData.temperamentTalkative,
            temperamentSensitivity: childData.temperamentSensitivity,
            temperamentAccountability: childData.temperamentAccountability
        )

        // Then
        XCTAssertTrue(mockService.createChildCalled)
        XCTAssertNotNil(createdChild.id)
        XCTAssertEqual(createdChild.name, childData.name)
        XCTAssertEqual(createdChild.age, childData.age)
        XCTAssertEqual(createdChild.goals, childData.goals)
        XCTAssertEqual(createdChild.topics.count, 3)
        XCTAssertEqual(createdChild.temperamentTalkative, 7)
        XCTAssertEqual(createdChild.temperamentSensitivity, 5)
        XCTAssertEqual(createdChild.temperamentAccountability, 8)
    }

    func test_createChild_withMinimalData() async throws {
        // Given
        mockService.mockUser = TestFixtures.testUser
        mockService.shouldSucceed = true

        // When
        let child = try await mockService.createChild(
            name: "New Child",
            age: 5,
            birthday: TestFixtures.childBirthday(yearsAgo: 5),
            goals: ["Single goal"],
            topics: ["emotions", "friends", "school"],
            temperament: .easygoing
        )

        // Then
        XCTAssertNotNil(child.id)
        XCTAssertEqual(child.name, "New Child")
        XCTAssertEqual(child.age, 5)
        XCTAssertEqual(child.goals.count, 1)
        XCTAssertEqual(child.topics.count, 3)
        XCTAssertEqual(child.temperamentTalkative, 5) // Default
        XCTAssertEqual(child.temperamentSensitivity, 5) // Default
        XCTAssertEqual(child.temperamentAccountability, 5) // Default
    }

    func test_fetchChildren_returnsAllUserChildren() async throws {
        // Given
        let userId = TestFixtures.testUserId
        mockService.mockChildren = [TestFixtures.testChild, TestFixtures.testChild2]
        mockService.shouldSucceed = true

        // When
        let children = try await mockService.fetchChildren(forUserId: userId)

        // Then
        XCTAssertTrue(mockService.fetchChildrenCalled)
        XCTAssertEqual(children.count, 2)
        XCTAssertEqual(children[0].name, "Test Child")
        XCTAssertEqual(children[1].name, "Second Child")
    }

    func test_fetchChildren_returnsEmptyArray_whenNoChildren() async throws {
        // Given
        let userId = TestFixtures.testUserId
        mockService.mockChildren = []
        mockService.shouldSucceed = true

        // When
        let children = try await mockService.fetchChildren(forUserId: userId)

        // Then
        XCTAssertTrue(mockService.fetchChildrenCalled)
        XCTAssertEqual(children.count, 0)
    }

    func test_updateChild_modifiesExistingChild() async throws {
        // Given
        var child = TestFixtures.testChild
        mockService.mockChildren = [child]
        mockService.shouldSucceed = true

        // Modify child
        child.name = "Updated Name"
        child.age = 11

        // When
        let updatedChild = try await mockService.updateChild(child)

        // Then
        XCTAssertEqual(updatedChild.name, "Updated Name")
        XCTAssertEqual(updatedChild.age, 11)
        XCTAssertEqual(updatedChild.id, child.id)
    }

    func test_deleteChild_removesChild() async throws {
        // Given
        let child = TestFixtures.testChild
        mockService.mockChildren = [child]
        mockService.shouldSucceed = true

        // When
        try await mockService.deleteChild(id: child.id)
        let children = try await mockService.fetchChildren(forUserId: TestFixtures.testUserId)

        // Then
        XCTAssertEqual(children.count, 0)
    }

    // MARK: - Error Handling Tests

    func test_createChild_throwsError_whenNetworkFails() async {
        // Given
        mockService.mockUser = TestFixtures.testUser
        mockService.networkError = URLError(.notConnectedToInternet)

        // When/Then
        do {
            _ = try await mockService.createChild(
                name: "Test",
                age: 10,
                birthday: Date(),
                goals: ["Goal"],
                topics: ["topic1", "topic2", "topic3"],
                temperament: .easygoing
            )
            XCTFail("Should have thrown network error")
        } catch {
            XCTAssertTrue(error is URLError)
        }
    }

    func test_getUserProfile_throwsError_whenNetworkFails() async {
        // Given
        mockService.networkError = URLError(.timedOut)

        // When/Then
        do {
            _ = try await mockService.getUserProfile()
            XCTFail("Should have thrown network error")
        } catch {
            XCTAssertTrue(error is URLError)
        }
    }

    func test_updateOnboardingState_throwsError_whenOperationFails() async {
        // Given
        mockService.shouldSucceed = false

        // When/Then
        do {
            try await mockService.updateOnboardingState(.childInfo)
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error is TestError)
        }
    }

    // MARK: - Multiple Operations Tests

    func test_createMultipleChildren_maintainsArray() async throws {
        // Given
        mockService.mockUser = TestFixtures.testUser
        mockService.shouldSucceed = true

        // When - Create first child
        _ = try await mockService.createChild(
            name: "First Child",
            age: 10,
            birthday: TestFixtures.childBirthday(yearsAgo: 10),
            goals: ["Goal 1"],
            topics: ["emotions", "friends", "school"],
            temperament: .easygoing
        )

        // When - Create second child
        _ = try await mockService.createChild(
            name: "Second Child",
            age: 8,
            birthday: TestFixtures.childBirthday(yearsAgo: 8),
            goals: ["Goal 2"],
            topics: ["family", "conflict", "values"],
            temperament: .spirited
        )

        // Then
        let children = try await mockService.fetchChildren(forUserId: TestFixtures.testUserId)
        XCTAssertEqual(children.count, 2)
        XCTAssertEqual(children[0].name, "First Child")
        XCTAssertEqual(children[1].name, "Second Child")
    }

    func test_sequentialOnboardingStateUpdates_workCorrectly() async throws {
        // Given
        mockService.mockUserProfile = TestFixtures.testUserProfile
        mockService.shouldSucceed = true

        // When - Update through multiple states
        try await mockService.updateOnboardingState(.userInfo)
        try await mockService.updateOnboardingState(.childInfo)
        try await mockService.updateOnboardingState(.goals)

        // Then
        XCTAssertEqual(mockService.capturedOnboardingState, .goals)
    }
}
