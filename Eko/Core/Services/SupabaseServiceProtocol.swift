import Foundation
import EkoCore

/// Protocol defining the interface for Supabase operations
/// This allows for dependency injection and testing with mocks
@MainActor
protocol SupabaseServiceProtocol {
    // MARK: - Authentication
    func getCurrentUser() async throws -> User?
    func signOut() async throws

    // MARK: - User Profile / Onboarding
    func getUserProfile() async throws -> UserProfile
    func updateOnboardingState(_ state: OnboardingState, currentChildId: UUID?) async throws
    func updateDisplayName(_ displayName: String) async throws
    func getCurrentUserWithProfile() async throws -> User?

    // MARK: - Child Operations
    func createChild(
        name: String,
        age: Int,
        birthday: Date,
        goals: [String],
        topics: [String],
        temperament: Temperament,
        temperamentTalkative: Int,
        temperamentSensitivity: Int,
        temperamentAccountability: Int
    ) async throws -> Child
    func fetchChildren(forUserId userId: UUID) async throws -> [Child]
    func updateChild(_ child: Child) async throws -> Child
    func deleteChild(id: UUID) async throws
}

// MARK: - SupabaseService Conformance
extension SupabaseService: SupabaseServiceProtocol {}
