import Foundation
import struct EkoCore.User
import struct EkoCore.Child
import Auth

// MARK: - UserDefaults Storage Adapter
private final class UserDefaultsStorage: AuthLocalStorage, @unchecked Sendable {
    nonisolated func store(key: String, value: Data) throws {
        UserDefaults.standard.set(value, forKey: key)
    }

    nonisolated func retrieve(key: String) throws -> Data? {
        UserDefaults.standard.data(forKey: key)
    }

    nonisolated func remove(key: String) throws {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

// MARK: - Supabase Service
@MainActor
final class SupabaseService: @unchecked Sendable {
    static let shared = SupabaseService()

    private let authClient: AuthClient

    private init() {
        guard let url = URL(string: Config.Supabase.url) else {
            fatalError("Invalid Supabase URL")
        }

        // Initialize the Auth client directly
        self.authClient = AuthClient(
            url: url.appendingPathComponent("auth/v1"),
            headers: ["apikey": Config.Supabase.anonKey],
            localStorage: UserDefaultsStorage()
        )
    }

    // MARK: - Authentication

    func signInWithGoogle() async throws -> User {
        // Start OAuth flow with Google
        let redirectURL = URL(string: Config.Supabase.redirectURL)!

        do {
            // This will open Safari and redirect back to the app
            try await authClient.signInWithOAuth(
                provider: .google,
                redirectTo: redirectURL,
                scopes: nil
            )

            // After OAuth completes, get the current session
            let session = try await authClient.session
            return try convertToUser(from: session.user)
        } catch {
            throw AuthError.unknown(error)
        }
    }

    func signUp(email: String, password: String) async throws -> User {
        do {
            let session = try await authClient.signUp(
                email: email,
                password: password
            )

            return try convertToUser(from: session.user)
        } catch {
            if let authError = error as? AuthError {
                throw authError
            }
            throw AuthError.unknown(error)
        }
    }

    func signIn(email: String, password: String) async throws -> User {
        do {
            let session = try await authClient.signIn(
                email: email,
                password: password
            )

            return try convertToUser(from: session.user)
        } catch {
            throw AuthError.invalidCredentials
        }
    }

    func signOut() async throws {
        try await authClient.signOut()
    }

    func getCurrentUser() async throws -> User? {
        do {
            let session = try await authClient.session
            return try convertToUser(from: session.user)
        } catch {
            return nil
        }
    }

    func resetPassword(email: String) async throws {
        try await authClient.resetPasswordForEmail(email)
    }

    // MARK: - OAuth Callback Handler

    func handleOAuthCallback(url: URL) async throws -> User {
        // Handle the OAuth redirect callback
        try await authClient.session(from: url)

        let session = try await authClient.session
        return try convertToUser(from: session.user)
    }

    // MARK: - Private Helpers

    private func convertToUser(from authUser: Auth.User) throws -> User {
        guard let email = authUser.email else {
            throw AuthError.unknown(NSError(domain: "No email", code: -1))
        }

        return User(
            id: authUser.id,
            email: email,
            createdAt: authUser.createdAt,
            updatedAt: authUser.updatedAt,
            displayName: authUser.userMetadata["full_name"] as? String,
            avatarURL: {
                if let avatarString = authUser.userMetadata["avatar_url"] as? String {
                    return URL(string: avatarString)
                }
                return nil
            }()
        )
    }

    // MARK: - Data Operations

    func fetchChildren(forUserId userId: UUID) async throws -> [Child] {
        // TODO: Implement with PostgREST
        return []
    }

    func createChild(_ child: Child) async throws -> Child {
        // TODO: Implement with PostgREST
        throw NetworkError.unknown(NSError(domain: "Not implemented", code: -1))
    }

    func updateChild(_ child: Child) async throws -> Child {
        // TODO: Implement with PostgREST
        throw NetworkError.unknown(NSError(domain: "Not implemented", code: -1))
    }

    func deleteChild(id: UUID) async throws {
        // TODO: Implement with PostgREST
    }
}
