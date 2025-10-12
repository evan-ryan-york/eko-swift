import Foundation
import struct EkoCore.User
import struct EkoCore.Child
import struct EkoCore.Conversation
import struct EkoCore.Message
import struct EkoCore.CreateConversationDTO
import struct EkoCore.SendMessageDTO
import struct EkoCore.CompleteConversationDTO
import struct EkoCore.CompleteConversationResponse
import struct EkoCore.CreateRealtimeSessionDTO
import struct EkoCore.RealtimeSessionResponse
import Auth
import PostgREST
import Functions

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
    private let postgrestClient: PostgrestClient
    private let functionsClient: FunctionsClient
    private let baseURL: URL

    private init() {
        guard let url = URL(string: Config.Supabase.url) else {
            fatalError("Invalid Supabase URL")
        }

        self.baseURL = url

        // Initialize the Auth client
        self.authClient = AuthClient(
            url: url.appendingPathComponent("auth/v1"),
            headers: ["apikey": Config.Supabase.anonKey],
            localStorage: UserDefaultsStorage()
        )

        // Initialize PostgREST client for database operations
        self.postgrestClient = PostgrestClient(
            url: url.appendingPathComponent("rest/v1"),
            schema: "public",
            headers: [
                "apikey": Config.Supabase.anonKey,
                "Authorization": "Bearer \(Config.Supabase.anonKey)"
            ]
        )

        // Initialize Functions client for Edge Functions
        self.functionsClient = FunctionsClient(
            url: url.appendingPathComponent("functions/v1"),
            headers: [
                "apikey": Config.Supabase.anonKey,
                "Authorization": "Bearer \(Config.Supabase.anonKey)"
            ]
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

    // MARK: - Lyra Conversations

    func createConversation(childId: UUID) async throws -> Conversation {
        let dto = CreateConversationDTO(childId: childId)

        return try await functionsClient.invoke(
            "create-conversation",
            options: FunctionInvokeOptions(body: dto)
        )
    }

    func getActiveConversation(childId: UUID) async throws -> Conversation? {
        let response = try await postgrestClient
            .from("conversations")
            .select()
            .eq("child_id", value: childId.uuidString)
            .eq("status", value: "active")
            .order("updated_at", ascending: false)
            .limit(1)
            .execute()

        let conversations: [Conversation] = response.value
        return conversations.first
    }

    func getMessages(conversationId: UUID) async throws -> [Message] {
        let response = try await postgrestClient
            .from("messages")
            .select()
            .eq("conversation_id", value: conversationId.uuidString)
            .order("created_at", ascending: true)
            .execute()

        let messages: [Message] = response.value
        return messages
    }

    func sendMessage(
        conversationId: UUID,
        message: String,
        childId: UUID
    ) async throws -> AsyncThrowingStream<String, Error> {
        let dto = SendMessageDTO(
            conversationId: conversationId,
            message: message,
            childId: childId
        )

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    // Note: For streaming responses, we may need to use a custom HTTP client
                    // For now, invoke returns the full response
                    struct StreamResponse: Codable {
                        let content: String
                    }

                    let response: StreamResponse = try await functionsClient.invoke(
                        "send-message",
                        options: FunctionInvokeOptions(body: dto)
                    )

                    // For now, yield the complete response
                    // TODO: Implement true streaming when needed
                    continuation.yield(response.content)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func completeConversation(conversationId: UUID) async throws -> CompleteConversationResponse {
        let dto = CompleteConversationDTO(conversationId: conversationId)

        return try await functionsClient.invoke(
            "complete-conversation",
            options: FunctionInvokeOptions(body: dto)
        )
    }

    func createRealtimeSession(
        sdp: String,
        conversationId: UUID,
        childId: UUID
    ) async throws -> RealtimeSessionResponse {
        let dto = CreateRealtimeSessionDTO(
            sdp: sdp,
            conversationId: conversationId,
            childId: childId
        )

        return try await functionsClient.invoke(
            "create-realtime-session",
            options: FunctionInvokeOptions(body: dto)
        )
    }

    // MARK: - Data Operations

    func fetchChildren(forUserId userId: UUID) async throws -> [Child] {
        let response = try await postgrestClient
            .from("children")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()

        let children: [Child] = response.value
        return children
    }

    func createChild(_ child: Child) async throws -> Child {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        let childData = try encoder.encode(child)

        return try await postgrestClient
            .from("children")
            .insert(childData)
            .select()
            .single()
            .execute()
            .value
    }

    func updateChild(_ child: Child) async throws -> Child {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        let childData = try encoder.encode(child)

        return try await postgrestClient
            .from("children")
            .update(childData)
            .eq("id", value: child.id.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    func deleteChild(id: UUID) async throws {
        try await postgrestClient
            .from("children")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}
