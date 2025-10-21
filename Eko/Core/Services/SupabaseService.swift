import Foundation
import struct EkoCore.User
import struct EkoCore.Child
import enum EkoCore.Temperament
import struct EkoCore.Conversation
import struct EkoCore.Message
import struct EkoCore.CreateConversationDTO
import struct EkoCore.SendMessageDTO
import struct EkoCore.CompleteConversationDTO
import struct EkoCore.CompleteConversationResponse
import struct EkoCore.CreateRealtimeSessionDTO
import struct EkoCore.RealtimeSessionResponse
import enum EkoCore.OnboardingState
import struct EkoCore.UserProfile
import struct EkoCore.DailyPracticeActivity
import struct EkoCore.GetDailyActivityResponse
import struct EkoCore.CompleteActivityResponse
import struct EkoCore.SessionResponse
import struct EkoCore.PromptResult
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
    private let customDecoder: JSONDecoder

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
        let anonKey = Config.Supabase.anonKey

        // Configure decoder to handle both ISO8601 timestamps and date-only strings
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Try ISO8601 full timestamp first (for created_at, updated_at)
            let iso8601Formatter = ISO8601DateFormatter()
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }

            // Try date-only format (for birthday)
            let dateOnlyFormatter = ISO8601DateFormatter()
            dateOnlyFormatter.formatOptions = [.withFullDate]
            if let date = dateOnlyFormatter.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date string: \(dateString)"
            )
        }
        // Don't use .convertFromSnakeCase - models have explicit CodingKeys

        // Store for reuse in other methods
        self.customDecoder = decoder

        self.postgrestClient = PostgrestClient(
            url: url.appendingPathComponent("rest/v1"),
            schema: "public",
            headers: [
                "apikey": anonKey
            ],
            fetch: { @Sendable [weak authClient, anonKey] request in
                var authenticatedRequest = request
                // Get the current session token and add it to headers
                if let session = try? await authClient?.session {
                    let accessToken = session.accessToken
                    print("🔑 Using user token: \(accessToken.prefix(20))...")
                    authenticatedRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                } else {
                    print("⚠️ No session, using anon key")
                    // Fallback to anon key if no session
                    authenticatedRequest.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
                }

                print("📡 Request URL: \(authenticatedRequest.url?.absoluteString ?? "unknown")")
                print("📡 Request method: \(authenticatedRequest.httpMethod ?? "unknown")")

                let (data, response) = try await URLSession.shared.data(for: authenticatedRequest)

                if let httpResponse = response as? HTTPURLResponse {
                    print("📥 Response status: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("📥 Response body: \(responseString)")
                    }
                }

                return (data, response)
            },
            decoder: decoder
        )

        // Initialize Functions client for Edge Functions
        self.functionsClient = FunctionsClient(
            url: url.appendingPathComponent("functions/v1"),
            headers: [
                "apikey": anonKey
            ],
            fetch: { @Sendable [weak authClient, anonKey] request in
                var authenticatedRequest = request
                // Get the current session token and add it to headers
                if let session = try? await authClient?.session {
                    let accessToken = session.accessToken
                    print("🔑 [Functions] Using user token: \(accessToken.prefix(20))...")
                    authenticatedRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                } else {
                    print("⚠️ [Functions] No session, using anon key")
                    // Fallback to anon key if no session
                    authenticatedRequest.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
                }

                print("📡 [Functions] Request URL: \(authenticatedRequest.url?.absoluteString ?? "unknown")")
                print("📡 [Functions] Request method: \(authenticatedRequest.httpMethod ?? "unknown")")

                let (data, response) = try await URLSession.shared.data(for: authenticatedRequest)

                if let httpResponse = response as? HTTPURLResponse {
                    print("📥 [Functions] Response status: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("📥 [Functions] Response body: \(responseString.prefix(200))...")
                    }
                }

                return (data, response)
            }
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

    // MARK: - User Profile / Onboarding

    /// Fetch user profile including onboarding state
    func getUserProfile() async throws -> UserProfile {
        let session = try await authClient.session
        let userId = session.user.id
        let lowerUserId = userId.uuidString.lowercased()

        print("🟡 [getUserProfile] Fetching profile for user: \(lowerUserId)")

        // Use the postgrestClient's built-in decoder
        let profiles: [UserProfile] = try await postgrestClient
            .from("user_profiles")
            .select()
            .eq("id", value: lowerUserId)
            .execute()
            .value

        print("🟡 [getUserProfile] Found \(profiles.count) profiles")

        guard let profile = profiles.first else {
            // If profile doesn't exist, create it (fallback)
            print("🟡 [getUserProfile] No profile found, creating one...")
            return try await createUserProfile(userId: userId)
        }

        print("✅ [getUserProfile] Loaded profile with state: \(profile.onboardingState.rawValue)")
        return profile
    }

    /// Create user profile (fallback if trigger didn't fire)
    private func createUserProfile(userId: UUID) async throws -> UserProfile {
        let lowerUserId = userId.uuidString.lowercased()

        print("🟡 [createUserProfile] Creating profile for user: \(lowerUserId)")

        let newProfile: [String: Any] = [
            "id": lowerUserId,
            "onboarding_state": OnboardingState.notStarted.rawValue
        ]

        let profileData = try JSONSerialization.data(withJSONObject: newProfile)

        if let jsonString = String(data: profileData, encoding: .utf8) {
            print("🟡 [createUserProfile] Payload: \(jsonString)")
        }

        // Use the postgrestClient's built-in decoder but catch errors
        do {
            let profiles: [UserProfile] = try await postgrestClient
                .from("user_profiles")
                .insert(profileData)
                .select()
                .execute()
                .value

            guard let profile = profiles.first else {
                print("❌ [createUserProfile] Failed to create profile - no data returned")
                throw NSError(
                    domain: "SupabaseService",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to create user profile"]
                )
            }

            print("✅ [createUserProfile] Created profile with state: \(profile.onboardingState.rawValue)")
            return profile
        } catch {
            print("❌ [createUserProfile] Insert failed with error: \(error)")
            print("❌ [createUserProfile] Error details: \(error.localizedDescription)")
            throw error
        }
    }

    /// Update user's onboarding state
    func updateOnboardingState(_ state: OnboardingState, currentChildId: UUID? = nil) async throws {
        let session = try await authClient.session
        let userId = session.user.id
        let lowerUserId = userId.uuidString.lowercased()

        print("🟡 [updateOnboardingState] Updating user \(lowerUserId) to state: \(state.rawValue)")

        var updates: [String: Any] = [
            "onboarding_state": state.rawValue
        ]

        if let childId = currentChildId {
            let lowerChildId = childId.uuidString.lowercased()
            updates["current_child_id"] = lowerChildId
            print("🟡 [updateOnboardingState] Setting current_child_id to: \(lowerChildId)")
        } else {
            updates["current_child_id"] = NSNull()
            print("🟡 [updateOnboardingState] Setting current_child_id to NULL")
        }

        let updateData = try JSONSerialization.data(withJSONObject: updates)
        if let jsonString = String(data: updateData, encoding: .utf8) {
            print("🟡 [updateOnboardingState] Update payload: \(jsonString)")
        }

        // Make direct HTTP request with explicit Prefer header and query filter
        let accessToken = session.accessToken
        let urlString = "\(baseURL.appendingPathComponent("rest/v1/user_profiles"))?id=eq.\(lowerUserId)&select=*"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue(Config.Supabase.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        request.httpBody = updateData

        print("🟡 [updateOnboardingState] Making direct PATCH request to: \(urlString)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        print("🟡 [updateOnboardingState] Response status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ [updateOnboardingState] PATCH failed: \(errorMessage)")
            throw NSError(domain: "SupabaseService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }

        // Verify the update worked
        if let responseString = String(data: data, encoding: .utf8) {
            if responseString == "[]" {
                print("❌ [updateOnboardingState] UPDATE RETURNED EMPTY - No rows matched!")
                throw NSError(
                    domain: "SupabaseService",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to update user profile - no rows matched"]
                )
            } else {
                print("✅ [updateOnboardingState] Update successful: \(responseString)")
            }
        }
    }

    /// Update user's display name in auth metadata
    func updateDisplayName(_ displayName: String) async throws {
        try await authClient.update(user: UserAttributes(data: ["full_name": .string(displayName)]))
    }

    /// Get combined user data (auth + profile)
    func getCurrentUserWithProfile() async throws -> User? {
        do {
            let session = try await authClient.session
            let profile = try await getUserProfile()

            guard let email = session.user.email else {
                throw AuthError.unknown(NSError(domain: "No email", code: -1))
            }

            return User(
                id: session.user.id,
                email: email,
                createdAt: session.user.createdAt,
                updatedAt: session.user.updatedAt,
                displayName: session.user.userMetadata["full_name"] as? String,
                avatarURL: {
                    if let avatarString = session.user.userMetadata["avatar_url"] as? String {
                        return URL(string: avatarString)
                    }
                    return nil
                }(),
                onboardingState: profile.onboardingState,
                currentChildId: profile.currentChildId
            )
        } catch {
            return nil
        }
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

        // Get session token for auth
        let session = try await authClient.session
        let accessToken = session.accessToken

        // Encode request body
        let encoder = JSONEncoder()
        let bodyData = try encoder.encode(dto)

        // Create request
        var request = URLRequest(url: baseURL.appendingPathComponent("functions/v1/create-conversation"))
        request.httpMethod = "POST"
        request.setValue(Config.Supabase.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])
        }

        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "SupabaseService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }

        // Decode with custom decoder
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return try decoder.decode(Conversation.self, from: data)
    }

    func getActiveConversation(childId: UUID) async throws -> Conversation? {
        let conversations: [Conversation] = try await postgrestClient
            .from("conversations")
            .select()
            .eq("child_id", value: childId.uuidString)
            .eq("status", value: "active")
            .order("updated_at", ascending: false)
            .limit(1)
            .execute()
            .value

        return conversations.first
    }

    func getMessages(conversationId: UUID) async throws -> [Message] {
        return try await postgrestClient
            .from("messages")
            .select()
            .eq("conversation_id", value: conversationId.uuidString)
            .order("created_at", ascending: true)
            .execute()
            .value
    }

    func saveVoiceMessages(_ messages: [Message]) async throws {
        // Filter out placeholder messages and save to database
        let messagesToSave = messages.filter { $0.content != "..." }

        guard !messagesToSave.isEmpty else {
            print("⚠️ [Supabase] No voice messages to save")
            return
        }

        try await postgrestClient
            .from("messages")
            .insert(messagesToSave)
            .execute()

        print("✅ [Supabase] Saved \(messagesToSave.count) voice messages")
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
                    // Get session token for auth
                    let session = try await authClient.session
                    let accessToken = session.accessToken

                    // Encode request body (DTO already has correct CodingKeys)
                    let encoder = JSONEncoder()
                    let bodyData = try encoder.encode(dto)

                    // Debug: Print request body
                    if let jsonString = String(data: bodyData, encoding: .utf8) {
                        print("📤 [Streaming] Request body: \(jsonString)")
                    }

                    // Create streaming request
                    var request = URLRequest(url: baseURL.appendingPathComponent("functions/v1/send-message"))
                    request.httpMethod = "POST"
                    request.setValue(Config.Supabase.anonKey, forHTTPHeaderField: "apikey")
                    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.httpBody = bodyData

                    // Use URLSession for streaming
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])
                    }

                    print("📥 [Streaming] Response status: \(httpResponse.statusCode)")

                    guard httpResponse.statusCode == 200 else {
                        // Try to read error message from response
                        var errorMessage = "HTTP \(httpResponse.statusCode)"
                        do {
                            var errorData = Data()
                            for try await line in bytes.lines {
                                if let lineData = line.data(using: .utf8) {
                                    errorData.append(lineData)
                                }
                            }
                            if let errorString = String(data: errorData, encoding: .utf8) {
                                errorMessage = errorString
                                print("📥 [Streaming] Error body: \(errorString)")
                            }
                        } catch {
                            print("📥 [Streaming] Could not read error body")
                        }
                        throw NSError(domain: "SupabaseService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                    }

                    // Parse SSE stream
                    for try await line in bytes.lines {
                        if line.hasPrefix("data: ") {
                            let content = String(line.dropFirst(6)) // Remove "data: " prefix
                            if !content.isEmpty {
                                continuation.yield(content)
                                // Yield control to prevent blocking the main thread
                                await Task.yield()
                            }
                        }
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func completeConversation(conversationId: UUID) async throws -> CompleteConversationResponse {
        let dto = CompleteConversationDTO(conversationId: conversationId)

        // Get session token for auth
        let session = try await authClient.session
        let accessToken = session.accessToken

        // Encode request body
        let encoder = JSONEncoder()
        let bodyData = try encoder.encode(dto)

        // Create request
        var request = URLRequest(url: baseURL.appendingPathComponent("functions/v1/complete-conversation"))
        request.httpMethod = "POST"
        request.setValue(Config.Supabase.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "SupabaseService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }

        // Decode with custom decoder
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return try decoder.decode(CompleteConversationResponse.self, from: data)
    }

    func createRealtimeSession(
        conversationId: UUID,
        childId: UUID
    ) async throws -> RealtimeSessionResponse {
        let dto = CreateRealtimeSessionDTO(
            conversationId: conversationId,
            childId: childId
        )

        let response: RealtimeSessionResponse = try await functionsClient.invoke(
            "create-realtime-session",
            options: FunctionInvokeOptions(body: dto)
        )

        return response
    }

    // MARK: - Data Operations

    func fetchChildren(forUserId userId: UUID) async throws -> [Child] {
        return try await postgrestClient
            .from("children")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
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
        // Get current user and session
        guard let currentUser = try await getCurrentUser() else {
            throw NSError(
                domain: "SupabaseService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]
            )
        }

        // Get session token
        let session = try await authClient.session
        let accessToken = session.accessToken

        // Create DTO for insert (without auto-generated fields)
        struct CreateChildDTO: Encodable {
            let userId: UUID
            let name: String
            let age: Int
            let birthday: String
            let goals: [String]
            let topics: [String]
            let temperament: String
            let temperamentTalkative: Int
            let temperamentSensitivity: Int
            let temperamentAccountability: Int

            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case name
                case age
                case birthday
                case goals
                case topics
                case temperament
                case temperamentTalkative = "temperament_talkative"
                case temperamentSensitivity = "temperament_sensitivity"
                case temperamentAccountability = "temperament_accountability"
            }
        }

        // Format birthday as ISO8601 date string
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        let birthdayString = dateFormatter.string(from: birthday)

        let dto = CreateChildDTO(
            userId: currentUser.id,
            name: name,
            age: age,
            birthday: birthdayString,
            goals: goals,
            topics: topics,
            temperament: temperament.rawValue,
            temperamentTalkative: temperamentTalkative,
            temperamentSensitivity: temperamentSensitivity,
            temperamentAccountability: temperamentAccountability
        )

        let encoder = JSONEncoder()
        let childData = try encoder.encode(dto)

        print("🟡 Sending to Supabase:")
        if let jsonString = String(data: childData, encoding: .utf8) {
            print("  JSON: \(jsonString)")
        }
        print("🔑 Using access token: \(accessToken.prefix(30))...")

        // Make direct HTTP request with proper auth header
        var request = URLRequest(url: baseURL.appendingPathComponent("rest/v1/children"))
        request.httpMethod = "POST"
        request.setValue(Config.Supabase.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        request.httpBody = childData

        print("📡 Making direct request to: \(request.url?.absoluteString ?? "unknown")")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                print("📥 Response status: \(httpResponse.statusCode)")
                let responseString = String(data: data, encoding: .utf8)
                if let responseString {
                    print("📥 Response body: \(responseString)")
                }

                guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
                    throw NSError(
                        domain: "SupabaseService",
                        code: httpResponse.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: responseString ?? "Unknown error"]
                    )
                }
            }

            // Decode using the same custom decoder configured for postgrestClient
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = customDecoder.dateDecodingStrategy
            // Don't use .convertFromSnakeCase - Child model has explicit CodingKeys

            // Response is an array with one item
            let children = try decoder.decode([Child].self, from: data)
            guard let result = children.first else {
                throw NSError(
                    domain: "SupabaseService",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "No child returned from database"]
                )
            }

            print("🟢 Received from Supabase: \(result)")
            return result
        } catch {
            print("🔴 Supabase error: \(error)")
            throw error
        }
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

    // MARK: - Daily Practice

    /// Fetch today's daily practice activity
    func getTodayActivity() async throws -> GetDailyActivityResponse {
        let session = try await authClient.session
        let accessToken = session.accessToken

        // Create request
        var request = URLRequest(url: baseURL.appendingPathComponent("functions/v1/get-daily-activity"))
        request.httpMethod = "POST"
        request.setValue(Config.Supabase.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])
        }

        // Decode response (handle both success and error states)
        let decoder = JSONDecoder()
        return try decoder.decode(GetDailyActivityResponse.self, from: data)
    }

    /// Start a practice session (non-blocking analytics)
    func startSession(activityId: UUID, dayNumber: Int) async -> UUID? {
        do {
            let session = try await authClient.session
            let accessToken = session.accessToken

            // Create request body
            let body: [String: Any] = [
                "activityId": activityId.uuidString,
                "dayNumber": dayNumber
            ]
            let bodyData = try JSONSerialization.data(withJSONObject: body)

            // Create request
            var request = URLRequest(url: baseURL.appendingPathComponent("functions/v1/start-practice-session"))
            request.httpMethod = "POST"
            request.setValue(Config.Supabase.anonKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = bodyData

            // Make request and decode response
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let response = try decoder.decode(SessionResponse.self, from: data)

            return response.sessionId
        } catch {
            print("⚠️ [Daily Practice] Failed to start session (non-critical): \(error)")
            return nil
        }
    }

    /// Update prompt result (non-blocking analytics)
    func updatePromptResult(sessionId: UUID?, promptResult: PromptResult) async {
        guard let sessionId = sessionId else { return }

        do {
            let session = try await authClient.session
            let accessToken = session.accessToken

            // Create request body
            let encoder = JSONEncoder()
            let promptData = try encoder.encode(promptResult)
            let promptObject = try JSONSerialization.jsonObject(with: promptData)

            let body: [String: Any] = [
                "sessionId": sessionId.uuidString,
                "promptResult": promptObject
            ]
            let bodyData = try JSONSerialization.data(withJSONObject: body)

            // Create request
            var request = URLRequest(url: baseURL.appendingPathComponent("functions/v1/update-prompt-result"))
            request.httpMethod = "POST"
            request.setValue(Config.Supabase.anonKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = bodyData

            // Make request (ignore errors - this is analytics only)
            _ = try await URLSession.shared.data(for: request)
        } catch {
            print("⚠️ [Daily Practice] Failed to update prompt result (non-critical): \(error)")
        }
    }

    /// Complete activity (CRITICAL - must succeed)
    func completeActivity(dayNumber: Int, totalScore: Int, sessionId: UUID?) async throws -> CompleteActivityResponse {
        let session = try await authClient.session
        let accessToken = session.accessToken

        // Create request body
        var body: [String: Any] = [
            "dayNumber": dayNumber,
            "totalScore": totalScore
        ]

        if let sessionId = sessionId {
            body["sessionId"] = sessionId.uuidString
        }

        let bodyData = try JSONSerialization.data(withJSONObject: body)

        // Create request
        var request = URLRequest(url: baseURL.appendingPathComponent("functions/v1/complete-activity"))
        request.httpMethod = "POST"
        request.setValue(Config.Supabase.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "SupabaseService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }

        // Decode response
        let decoder = JSONDecoder()
        return try decoder.decode(CompleteActivityResponse.self, from: data)
    }
}
