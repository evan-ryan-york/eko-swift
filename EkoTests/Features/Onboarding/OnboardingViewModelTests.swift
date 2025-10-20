import XCTest
@testable import Eko
import EkoCore

@MainActor
final class OnboardingViewModelTests: XCTestCase {

    var sut: OnboardingViewModel!
    var mockService: MockSupabaseService!

    override func setUp() {
        super.setUp()
        mockService = MockSupabaseService()
        sut = OnboardingViewModel(supabaseService: mockService)
    }

    override func tearDown() {
        sut = nil
        mockService = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func test_initialization_setsDefaultState() {
        // Then
        XCTAssertEqual(sut.currentState, .notStarted)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.parentName, "")
        XCTAssertEqual(sut.childName, "")
        XCTAssertEqual(sut.selectedGoals, [])
        XCTAssertEqual(sut.selectedTopics, [])
        XCTAssertEqual(sut.talkativeScore, 5)
        XCTAssertEqual(sut.sensitiveScore, 5)
        XCTAssertEqual(sut.accountableScore, 5)
    }

    // MARK: - User Info Validation Tests

    func test_canProceedFromUserInfo_returnsFalse_whenNameIsEmpty() {
        // Given
        sut.parentName = ""

        // When
        let canProceed = sut.canProceedFromUserInfo

        // Then
        XCTAssertFalse(canProceed)
    }

    func test_canProceedFromUserInfo_returnsFalse_whenNameIsWhitespace() {
        // Given
        sut.parentName = "   "

        // When
        let canProceed = sut.canProceedFromUserInfo

        // Then
        XCTAssertFalse(canProceed)
    }

    func test_canProceedFromUserInfo_returnsTrue_whenNameIsValid() {
        // Given
        sut.parentName = "John Doe"

        // When
        let canProceed = sut.canProceedFromUserInfo

        // Then
        XCTAssertTrue(canProceed)
    }

    func test_canProceedFromUserInfo_returnsTrue_whenNameHasLeadingTrailingSpaces() {
        // Given
        sut.parentName = "  Jane Smith  "

        // When
        let canProceed = sut.canProceedFromUserInfo

        // Then
        XCTAssertTrue(canProceed)
    }

    // MARK: - Child Info Validation Tests

    func test_canProceedFromChildInfo_returnsFalse_whenNameIsEmpty() {
        // Given
        sut.childName = ""

        // When
        let canProceed = sut.canProceedFromChildInfo

        // Then
        XCTAssertFalse(canProceed)
    }

    func test_canProceedFromChildInfo_returnsFalse_whenNameIsWhitespace() {
        // Given
        sut.childName = "    \n\t   "

        // When
        let canProceed = sut.canProceedFromChildInfo

        // Then
        XCTAssertFalse(canProceed)
    }

    func test_canProceedFromChildInfo_returnsTrue_whenNameIsValid() {
        // Given
        sut.childName = "Jane Doe"

        // When
        let canProceed = sut.canProceedFromChildInfo

        // Then
        XCTAssertTrue(canProceed)
    }

    // MARK: - Goals Validation Tests

    func test_canProceedFromGoals_returnsFalse_whenNoGoalsSelected() {
        // Given
        sut.selectedGoals = []
        sut.customGoal = ""

        // When
        let canProceed = sut.canProceedFromGoals

        // Then
        XCTAssertFalse(canProceed)
    }

    func test_canProceedFromGoals_returnsTrue_whenOneGoalSelected() {
        // Given
        sut.selectedGoals = ["Understanding their thoughts and feelings better"]
        sut.customGoal = ""

        // When
        let canProceed = sut.canProceedFromGoals

        // Then
        XCTAssertTrue(canProceed)
    }

    func test_canProceedFromGoals_returnsTrue_whenTwoGoalsSelected() {
        // Given
        sut.selectedGoals = [
            "Understanding their thoughts and feelings better",
            "Helping them navigate challenges"
        ]
        sut.customGoal = ""

        // When
        let canProceed = sut.canProceedFromGoals

        // Then
        XCTAssertTrue(canProceed)
    }

    func test_canProceedFromGoals_returnsTrue_whenThreeGoalsSelected() {
        // Given
        sut.selectedGoals = [
            "Understanding their thoughts and feelings better",
            "Helping them navigate challenges",
            "Connecting with them on a deeper level"
        ]
        sut.customGoal = ""

        // When
        let canProceed = sut.canProceedFromGoals

        // Then
        XCTAssertTrue(canProceed)
    }

    func test_canProceedFromGoals_returnsFalse_whenMoreThanThreeGoalsSelected() {
        // Given
        sut.selectedGoals = [
            "Understanding their thoughts and feelings better",
            "Helping them navigate challenges",
            "Connecting with them on a deeper level",
            "Encouraging them to open up more"
        ]
        sut.customGoal = ""

        // When
        let canProceed = sut.canProceedFromGoals

        // Then
        XCTAssertFalse(canProceed)
    }

    func test_canProceedFromGoals_returnsTrue_whenCustomGoalProvided() {
        // Given
        sut.selectedGoals = []
        sut.customGoal = "Building trust"

        // When
        let canProceed = sut.canProceedFromGoals

        // Then
        XCTAssertTrue(canProceed)
    }

    func test_canProceedFromGoals_returnsTrue_whenTwoSelectedPlusCustomGoal() {
        // Given
        sut.selectedGoals = [
            "Understanding their thoughts and feelings better",
            "Helping them navigate challenges"
        ]
        sut.customGoal = "Building confidence"

        // When
        let canProceed = sut.canProceedFromGoals

        // Then
        XCTAssertTrue(canProceed)
    }

    func test_canProceedFromGoals_returnsFalse_whenThreeSelectedPlusCustomGoal() {
        // Given
        sut.selectedGoals = [
            "Understanding their thoughts and feelings better",
            "Helping them navigate challenges",
            "Connecting with them on a deeper level"
        ]
        sut.customGoal = "Building confidence"

        // When
        let canProceed = sut.canProceedFromGoals

        // Then
        XCTAssertFalse(canProceed)
    }

    // MARK: - Topics Validation Tests

    func test_canProceedFromTopics_returnsFalse_whenNoTopicsSelected() {
        // Given
        sut.selectedTopics = []

        // When
        let canProceed = sut.canProceedFromTopics

        // Then
        XCTAssertFalse(canProceed)
    }

    func test_canProceedFromTopics_returnsFalse_whenLessThanThreeTopicsSelected() {
        // Given
        sut.selectedTopics = ["emotions", "friends"]

        // When
        let canProceed = sut.canProceedFromTopics

        // Then
        XCTAssertFalse(canProceed)
    }

    func test_canProceedFromTopics_returnsTrue_whenExactlyThreeTopicsSelected() {
        // Given
        sut.selectedTopics = ["emotions", "friends", "school"]

        // When
        let canProceed = sut.canProceedFromTopics

        // Then
        XCTAssertTrue(canProceed)
    }

    func test_canProceedFromTopics_returnsTrue_whenMoreThanThreeTopicsSelected() {
        // Given
        sut.selectedTopics = ["emotions", "friends", "school", "family", "conflict"]

        // When
        let canProceed = sut.canProceedFromTopics

        // Then
        XCTAssertTrue(canProceed)
    }

    func test_canProceedFromTopics_returnsTrue_whenAllTopicsSelected() {
        // Given
        sut.selectedTopics = [
            "emotions", "friends", "school", "family", "conflict",
            "values", "confidence", "health", "diversity", "future",
            "technology", "creativity"
        ]

        // When
        let canProceed = sut.canProceedFromTopics

        // Then
        XCTAssertTrue(canProceed)
    }

    // MARK: - Dispositions Validation Tests

    func test_canProceedFromDispositions_alwaysReturnsTrue() {
        // Given (default values)

        // When
        let canProceed = sut.canProceedFromDispositions

        // Then
        XCTAssertTrue(canProceed)
    }

    func test_canProceedFromDispositions_returnsTrueWithCustomValues() {
        // Given
        sut.talkativeScore = 8
        sut.sensitiveScore = 3
        sut.accountableScore = 10

        // When
        let canProceed = sut.canProceedFromDispositions

        // Then
        XCTAssertTrue(canProceed)
    }

    // MARK: - State Transition Tests

    func test_moveToNextStep_transitionsFromUserInfoToChildInfo() async {
        // Given
        sut.currentState = .userInfo
        sut.parentName = "John Doe"
        mockService.shouldSucceed = true

        // When
        await sut.moveToNextStep()

        // Then
        XCTAssertEqual(sut.currentState, .childInfo)
        XCTAssertTrue(mockService.updateDisplayNameCalled)
        XCTAssertEqual(mockService.capturedDisplayName, "John Doe")
        XCTAssertTrue(mockService.updateOnboardingStateCalled)
        XCTAssertEqual(mockService.capturedOnboardingState, .childInfo)
    }

    func test_moveToNextStep_transitionsFromChildInfoToGoals() async {
        // Given
        sut.currentState = .childInfo
        mockService.shouldSucceed = true

        // When
        await sut.moveToNextStep()

        // Then
        XCTAssertEqual(sut.currentState, .goals)
        XCTAssertTrue(mockService.updateOnboardingStateCalled)
        XCTAssertEqual(mockService.capturedOnboardingState, .goals)
    }

    func test_moveToNextStep_transitionsFromGoalsToTopics() async {
        // Given
        sut.currentState = .goals
        mockService.shouldSucceed = true

        // When
        await sut.moveToNextStep()

        // Then
        XCTAssertEqual(sut.currentState, .topics)
        XCTAssertTrue(mockService.updateOnboardingStateCalled)
    }

    func test_moveToNextStep_transitionsFromTopicsToDispositions() async {
        // Given
        sut.currentState = .topics
        mockService.shouldSucceed = true

        // When
        await sut.moveToNextStep()

        // Then
        XCTAssertEqual(sut.currentState, .dispositions)
        XCTAssertTrue(mockService.updateOnboardingStateCalled)
    }

    func test_moveToNextStep_transitionsFromDispositionsToReview() async {
        // Given
        sut.currentState = .dispositions
        sut.childName = "Jane Doe"
        sut.childBirthday = TestFixtures.childBirthday(yearsAgo: 10)
        sut.selectedGoals = ["Understanding feelings"]
        sut.selectedTopics = ["emotions", "friends", "school"]
        mockService.shouldSucceed = true
        mockService.mockUser = TestFixtures.testUser

        // When
        await sut.moveToNextStep()

        // Then
        XCTAssertEqual(sut.currentState, .review)
        XCTAssertTrue(mockService.createChildCalled)
        XCTAssertTrue(mockService.updateOnboardingStateCalled)
        XCTAssertEqual(mockService.capturedOnboardingState, .review)
    }

    func test_moveToNextStep_transitionsFromReviewToComplete() async {
        // Given
        sut.currentState = .review
        mockService.shouldSucceed = true

        // When
        await sut.moveToNextStep()

        // Then
        XCTAssertEqual(sut.currentState, .complete)
        XCTAssertTrue(mockService.updateOnboardingStateCalled)
        XCTAssertEqual(mockService.capturedOnboardingState, .complete)
    }

    func test_moveToNextStep_doesNothing_whenAtCompleteState() async {
        // Given
        sut.currentState = .complete
        mockService.shouldSucceed = true

        // When
        await sut.moveToNextStep()

        // Then
        XCTAssertEqual(sut.currentState, .complete)
        XCTAssertFalse(mockService.updateOnboardingStateCalled)
    }

    func test_moveToNextStep_setsErrorMessage_whenServiceFails() async {
        // Given
        sut.currentState = .userInfo
        sut.parentName = "John Doe"
        mockService.shouldSucceed = false

        // When
        await sut.moveToNextStep()

        // Then
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage!.contains("Failed to proceed"))
        XCTAssertEqual(sut.currentState, .userInfo) // Should not transition on error
    }

    func test_moveToNextStep_setsLoadingStateCorrectly() async {
        // Given
        sut.currentState = .childInfo
        mockService.shouldSucceed = true

        // When
        let loadingBeforeTask = sut.isLoading

        await sut.moveToNextStep()

        let loadingAfterTask = sut.isLoading

        // Then
        XCTAssertFalse(loadingBeforeTask)
        XCTAssertFalse(loadingAfterTask)
    }

    // MARK: - Child Data Save Tests

    func test_saveChildData_createsChild_withAllData() async throws {
        // Given
        sut.childName = "Jane Doe"
        sut.childBirthday = TestFixtures.childBirthday(yearsAgo: 10)
        sut.selectedGoals = ["Understanding feelings"]
        sut.selectedTopics = ["emotions", "friends", "school"]
        sut.talkativeScore = 7
        sut.sensitiveScore = 5
        sut.accountableScore = 8
        mockService.shouldSucceed = true
        mockService.mockUser = TestFixtures.testUser

        // When
        try await sut.saveChildData()

        // Then
        XCTAssertTrue(mockService.createChildCalled)
        XCTAssertNotNil(mockService.mockChild)
        XCTAssertEqual(mockService.mockChild?.name, "Jane Doe")
        XCTAssertEqual(mockService.mockChild?.goals, ["Understanding feelings"])
        XCTAssertEqual(mockService.mockChild?.topics.count, 3)
        XCTAssertEqual(mockService.mockChild?.temperamentTalkative, 7)
        XCTAssertEqual(mockService.mockChild?.temperamentSensitivity, 5)
        XCTAssertEqual(mockService.mockChild?.temperamentAccountability, 8)
        XCTAssertNotNil(sut.currentChildId)
    }

    func test_saveChildData_includesCustomGoal_whenProvided() async throws {
        // Given
        sut.childName = "Jane Doe"
        sut.childBirthday = TestFixtures.childBirthday(yearsAgo: 10)
        sut.selectedGoals = ["Understanding feelings"]
        sut.customGoal = "Building confidence"
        sut.selectedTopics = ["emotions", "friends", "school"]
        mockService.shouldSucceed = true
        mockService.mockUser = TestFixtures.testUser

        // When
        try await sut.saveChildData()

        // Then
        XCTAssertEqual(mockService.mockChild?.goals.count, 2)
        XCTAssertTrue(mockService.mockChild?.goals.contains("Understanding feelings") ?? false)
        XCTAssertTrue(mockService.mockChild?.goals.contains("Building confidence") ?? false)
    }

    func test_saveChildData_calculatesAgeCorrectly() async throws {
        // Given
        let tenYearsAgo = TestFixtures.childBirthday(yearsAgo: 10)
        sut.childName = "Test Child"
        sut.childBirthday = tenYearsAgo
        sut.selectedGoals = ["Goal"]
        sut.selectedTopics = ["emotions", "friends", "school"]
        mockService.shouldSucceed = true
        mockService.mockUser = TestFixtures.testUser

        // When
        try await sut.saveChildData()

        // Then
        XCTAssertEqual(mockService.mockChild?.age, 10)
    }

    func test_saveChildData_throwsError_whenNameIsEmpty() async {
        // Given
        sut.childName = "   "

        // When/Then
        do {
            try await sut.saveChildData()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error is ValidationError)
            if let validationError = error as? ValidationError {
                XCTAssertEqual(validationError, .emptyName)
            }
        }
    }

    func test_saveChildData_throwsError_whenServiceFails() async {
        // Given
        sut.childName = "Valid Name"
        sut.childBirthday = Date()
        sut.selectedGoals = ["Goal"]
        sut.selectedTopics = ["emotions", "friends", "school"]
        mockService.shouldSucceed = false
        mockService.mockUser = TestFixtures.testUser

        // When/Then
        do {
            try await sut.saveChildData()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error is TestError)
        }
    }

    // MARK: - Multiple Children Tests

    func test_addAnotherChild_resetsForm() async {
        // Given
        sut.currentState = .review
        sut.childName = "First Child"
        sut.selectedGoals = ["Goal 1"]
        sut.selectedTopics = ["emotions", "friends", "school"]
        sut.customGoal = "Custom"
        sut.talkativeScore = 8
        mockService.shouldSucceed = true

        // When
        await sut.addAnotherChild()

        // Then
        XCTAssertEqual(sut.childName, "")
        XCTAssertTrue(sut.selectedGoals.isEmpty)
        XCTAssertTrue(sut.selectedTopics.isEmpty)
        XCTAssertEqual(sut.customGoal, "")
        XCTAssertEqual(sut.talkativeScore, 5)
        XCTAssertEqual(sut.sensitiveScore, 5)
        XCTAssertEqual(sut.accountableScore, 5)
        XCTAssertEqual(sut.currentDispositionPage, 0)
    }

    func test_addAnotherChild_transitionsToChildInfo() async {
        // Given
        sut.currentState = .review
        mockService.shouldSucceed = true

        // When
        await sut.addAnotherChild()

        // Then
        XCTAssertEqual(sut.currentState, .childInfo)
        XCTAssertTrue(mockService.updateOnboardingStateCalled)
        XCTAssertEqual(mockService.capturedOnboardingState, .childInfo)
    }

    func test_addAnotherChild_generatesNewChildId() async {
        // Given
        sut.currentState = .review
        let previousChildId = sut.currentChildId
        mockService.shouldSucceed = true

        // When
        await sut.addAnotherChild()

        // Then
        XCTAssertNotNil(sut.currentChildId)
        XCTAssertNotEqual(sut.currentChildId, previousChildId)
    }

    func test_addAnotherChild_setsErrorMessage_whenServiceFails() async {
        // Given
        sut.currentState = .review
        mockService.shouldSucceed = false

        // When
        await sut.addAnotherChild()

        // Then
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage!.contains("Failed to start new child"))
        XCTAssertEqual(sut.currentState, .review) // Should not transition on error
    }

    // MARK: - Completion Tests

    func test_completeOnboarding_updatesStateToComplete() async {
        // Given
        mockService.shouldSucceed = true

        // When
        await sut.completeOnboarding()

        // Then
        XCTAssertEqual(sut.currentState, .complete)
        XCTAssertTrue(mockService.updateOnboardingStateCalled)
        XCTAssertEqual(mockService.capturedOnboardingState, .complete)
        XCTAssertNil(mockService.capturedCurrentChildId)
    }

    func test_completeOnboarding_setsErrorMessage_whenServiceFails() async {
        // Given
        mockService.shouldSucceed = false

        // When
        await sut.completeOnboarding()

        // Then
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage!.contains("Failed to complete onboarding"))
        XCTAssertNotEqual(sut.currentState, .complete)
    }

    // MARK: - Load State Tests

    func test_loadOnboardingState_loadsProfileSuccessfully() async {
        // Given
        mockService.mockUserProfile = TestFixtures.testUserProfileInProgress
        mockService.shouldSucceed = true

        // When
        await sut.loadOnboardingState()

        // Then
        XCTAssertTrue(mockService.getUserProfileCalled)
        XCTAssertEqual(sut.currentState, .goals)
        XCTAssertEqual(sut.currentChildId, TestFixtures.testChildId)
    }

    func test_loadOnboardingState_loadsChildren_whenInReviewState() async {
        // Given
        mockService.mockUserProfile = UserProfile(
            id: TestFixtures.testUserId,
            onboardingState: .review,
            currentChildId: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        mockService.mockUser = TestFixtures.testUser
        mockService.mockChildren = [TestFixtures.testChild]
        mockService.shouldSucceed = true

        // When
        await sut.loadOnboardingState()

        // Then
        XCTAssertEqual(sut.currentState, .review)
        XCTAssertTrue(mockService.fetchChildrenCalled)
        XCTAssertEqual(sut.completedChildren.count, 1)
    }

    func test_loadOnboardingState_setsErrorMessage_onFailure() async {
        // Given
        mockService.networkError = URLError(.notConnectedToInternet)

        // When
        await sut.loadOnboardingState()

        // Then
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage!.contains("Failed to load onboarding state"))
    }

    // MARK: - Helper Method Tests

    func test_startChildEntry_generatesNewChildId() async {
        // Given
        sut.currentChildId = nil

        // When
        await sut.startChildEntry()

        // Then
        XCTAssertNotNil(sut.currentChildId)
    }

    func test_startChildEntry_resetsForm() async {
        // Given
        sut.childName = "Old Name"
        sut.selectedGoals = ["Goal"]
        sut.selectedTopics = ["topic"]

        // When
        await sut.startChildEntry()

        // Then
        XCTAssertEqual(sut.childName, "")
        XCTAssertTrue(sut.selectedGoals.isEmpty)
        XCTAssertTrue(sut.selectedTopics.isEmpty)
    }
}
