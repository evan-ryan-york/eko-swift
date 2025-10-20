import Foundation
import EkoCore
@testable import Eko

/// Mock implementation of SupabaseServiceProtocol for testing
@MainActor
final class MockSupabaseService: SupabaseServiceProtocol {
    // MARK: - Control Behavior
    var shouldSucceed = true
    var networkError: Error?

    // MARK: - Track Method Calls
    var updateDisplayNameCalled = false
    var updateOnboardingStateCalled = false
    var createChildCalled = false
    var fetchChildrenCalled = false
    var getUserProfileCalled = false
    var getCurrentUserCalled = false
    var getCurrentUserWithProfileCalled = false

    // MARK: - Mock Data
    var mockUserProfile: UserProfile?
    var mockUser: User?
    var mockChild: Child?
    var mockChildren: [Child] = []

    // MARK: - Captured Values
    var capturedDisplayName: String?
    var capturedOnboardingState: OnboardingState?
    var capturedCurrentChildId: UUID?

    // MARK: - Authentication

    func getCurrentUser() async throws -> User? {
        getCurrentUserCalled = true
        if let error = networkError { throw error }
        guard shouldSucceed else { throw TestError.operationFailed }
        return mockUser
    }

    func signOut() async throws {
        if let error = networkError { throw error }
        guard shouldSucceed else { throw TestError.operationFailed }
        mockUser = nil
    }

    // MARK: - User Profile / Onboarding

    func getUserProfile() async throws -> UserProfile {
        getUserProfileCalled = true
        if let error = networkError { throw error }
        guard shouldSucceed else { throw TestError.operationFailed }

        return mockUserProfile ?? UserProfile(
            id: UUID(),
            onboardingState: .notStarted,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    func updateOnboardingState(_ state: OnboardingState, currentChildId: UUID? = nil) async throws {
        updateOnboardingStateCalled = true
        capturedOnboardingState = state
        capturedCurrentChildId = currentChildId

        if let error = networkError { throw error }
        guard shouldSucceed else { throw TestError.operationFailed }

        mockUserProfile?.onboardingState = state
        mockUserProfile?.currentChildId = currentChildId
    }

    func updateDisplayName(_ displayName: String) async throws {
        updateDisplayNameCalled = true
        capturedDisplayName = displayName

        if let error = networkError { throw error }
        guard shouldSucceed else { throw TestError.operationFailed }

        mockUser?.displayName = displayName
    }

    func getCurrentUserWithProfile() async throws -> User? {
        getCurrentUserWithProfileCalled = true
        if let error = networkError { throw error }
        guard shouldSucceed else { throw TestError.operationFailed }
        return mockUser
    }

    // MARK: - Child Operations

    func createChild(
        name: String,
        age: Int,
        birthday: Date,
        goals: [String] = [],
        topics: [String] = [],
        temperament: Temperament,
        temperamentTalkative: Int = 5,
        temperamentSensitivity: Int = 5,
        temperamentAccountability: Int = 5
    ) async throws -> Child {
        createChildCalled = true

        if let error = networkError { throw error }
        guard shouldSucceed else { throw TestError.operationFailed }

        let child = Child(
            id: UUID(),
            userId: mockUser?.id ?? UUID(),
            name: name,
            age: age,
            birthday: birthday,
            goals: goals,
            topics: topics,
            temperament: temperament,
            temperamentTalkative: temperamentTalkative,
            temperamentSensitivity: temperamentSensitivity,
            temperamentAccountability: temperamentAccountability,
            createdAt: Date(),
            updatedAt: Date()
        )

        mockChild = child
        mockChildren.append(child)
        return child
    }

    func fetchChildren(forUserId userId: UUID) async throws -> [Child] {
        fetchChildrenCalled = true
        if let error = networkError { throw error }
        guard shouldSucceed else { throw TestError.operationFailed }
        return mockChildren
    }

    func updateChild(_ child: Child) async throws -> Child {
        if let error = networkError { throw error }
        guard shouldSucceed else { throw TestError.operationFailed }

        // Find and update in mockChildren array
        if let index = mockChildren.firstIndex(where: { $0.id == child.id }) {
            mockChildren[index] = child
        }
        return child
    }

    func deleteChild(id: UUID) async throws {
        if let error = networkError { throw error }
        guard shouldSucceed else { throw TestError.operationFailed }

        mockChildren.removeAll { $0.id == id }
    }

    // MARK: - Helper Methods

    func reset() {
        shouldSucceed = true
        networkError = nil
        updateDisplayNameCalled = false
        updateOnboardingStateCalled = false
        createChildCalled = false
        fetchChildrenCalled = false
        getUserProfileCalled = false
        getCurrentUserCalled = false
        getCurrentUserWithProfileCalled = false
        mockUserProfile = nil
        mockUser = nil
        mockChild = nil
        mockChildren = []
        capturedDisplayName = nil
        capturedOnboardingState = nil
        capturedCurrentChildId = nil
    }
}

// MARK: - Test Error

enum TestError: Error, LocalizedError {
    case operationFailed
    case networkUnavailable
    case invalidData

    var errorDescription: String? {
        switch self {
        case .operationFailed:
            return "Operation failed"
        case .networkUnavailable:
            return "Network unavailable"
        case .invalidData:
            return "Invalid data"
        }
    }
}
