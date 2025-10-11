import Foundation

// MARK: - Network Errors
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError(String)
    case decodingError(Error)
    case networkUnavailable
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL is invalid."
        case .invalidResponse:
            return "The server response was invalid."
        case .unauthorized:
            return "You are not authorized. Please sign in again."
        case .serverError(let message):
            return "Server error: \(message)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkUnavailable:
            return "Network connection unavailable. Please check your internet connection."
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
}

// MARK: - Authentication Errors
enum AuthError: Error, LocalizedError {
    case invalidCredentials
    case emailAlreadyInUse
    case weakPassword
    case userNotFound
    case sessionExpired
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password."
        case .emailAlreadyInUse:
            return "This email is already registered."
        case .weakPassword:
            return "Password must be at least 8 characters long."
        case .userNotFound:
            return "No account found with this email."
        case .sessionExpired:
            return "Your session has expired. Please sign in again."
        case .unknown(let error):
            return "Authentication error: \(error.localizedDescription)"
        }
    }
}
