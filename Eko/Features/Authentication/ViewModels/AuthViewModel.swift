import Foundation
import EkoCore
import Observation

// MARK: - Authentication ViewModel
@MainActor
@Observable
final class AuthViewModel {
    // MARK: - Published State
    var isAuthenticated = false
    var currentUser: User?
    var isLoading = false
    var errorMessage: String?

    // MARK: - Services
    private let supabaseService = SupabaseService.shared

    // MARK: - Initialization
    init() {
        Task {
            await checkAuthStatus()
        }
    }

    // MARK: - Authentication Methods

    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil

        do {
            let user = try await supabaseService.signInWithGoogle()
            currentUser = user
            isAuthenticated = true
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Google sign in failed. Please try again."
        }

        isLoading = false
    }

    func handleOAuthCallback(url: URL) async {
        isLoading = true
        errorMessage = nil

        do {
            let user = try await supabaseService.handleOAuthCallback(url: url)
            currentUser = user
            isAuthenticated = true
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Authentication callback failed. Please try again."
        }

        isLoading = false
    }

    func signUp(email: String, password: String) async {
        guard validateEmail(email) else {
            errorMessage = "Please enter a valid email address"
            return
        }

        guard validatePassword(password) else {
            errorMessage = "Password must be at least 8 characters"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let user = try await supabaseService.signUp(email: email, password: password)
            currentUser = user
            isAuthenticated = true
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Sign up failed. Please try again."
        }

        isLoading = false
    }

    func signIn(email: String, password: String) async {
        guard validateEmail(email) else {
            errorMessage = "Please enter a valid email address"
            return
        }

        guard !password.isEmpty else {
            errorMessage = "Please enter your password"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let user = try await supabaseService.signIn(email: email, password: password)
            currentUser = user
            isAuthenticated = true
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Sign in failed. Please try again."
        }

        isLoading = false
    }

    func signOut() async {
        isLoading = true
        errorMessage = nil

        do {
            try await supabaseService.signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            errorMessage = "Sign out failed. Please try again."
        }

        isLoading = false
    }

    func resetPassword(email: String) async {
        guard validateEmail(email) else {
            errorMessage = "Please enter a valid email address"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await supabaseService.resetPassword(email: email)
            // Show success message somehow (maybe add a successMessage property)
        } catch {
            errorMessage = "Password reset failed. Please try again."
        }

        isLoading = false
    }

    // MARK: - Private Methods

    private func checkAuthStatus() async {
        do {
            if let user = try await supabaseService.getCurrentUser() {
                currentUser = user
                isAuthenticated = true
            }
        } catch {
            isAuthenticated = false
        }
    }

    private func validateEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    private func validatePassword(_ password: String) -> Bool {
        password.count >= 8
    }
}
