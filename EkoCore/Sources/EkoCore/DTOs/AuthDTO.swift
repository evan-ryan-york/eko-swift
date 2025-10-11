import Foundation

// MARK: - Authentication DTOs

public struct SignUpRequest: Codable, Sendable {
    public let email: String
    public let password: String

    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}

public struct SignInRequest: Codable, Sendable {
    public let email: String
    public let password: String

    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}

public struct AuthResponse: Codable, Sendable {
    public let user: User
    public let session: Session

    public init(user: User, session: Session) {
        self.user = user
        self.session = session
    }
}

public struct Session: Codable, Sendable {
    public let accessToken: String
    public let refreshToken: String
    public let expiresAt: Date

    public init(accessToken: String, refreshToken: String, expiresAt: Date) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
    }

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresAt = "expires_at"
    }
}

public struct PasswordResetRequest: Codable, Sendable {
    public let email: String

    public init(email: String) {
        self.email = email
    }
}
