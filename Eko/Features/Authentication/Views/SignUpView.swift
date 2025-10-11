import SwiftUI
import EkoKit

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    init(viewModel: AuthViewModel) {
        self.viewModel = viewModel
    }

    var passwordsMatch: Bool {
        password == confirmPassword && !password.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .ekoSpacingXL) {
                    // Header
                    VStack(spacing: .ekoSpacingSM) {
                        Text("Create Account")
                            .ekoTitle1Style()

                        Text("Join Eko and start having better conversations")
                            .ekoSubheadlineStyle()
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, .ekoSpacingLG)

                    // Form
                    VStack(spacing: .ekoSpacingLG) {
                        FormTextField(
                            title: "Email",
                            placeholder: "Enter your email",
                            text: $email,
                            keyboardType: .emailAddress,
                            errorMessage: viewModel.errorMessage
                        )

                        FormTextField(
                            title: "Password",
                            placeholder: "At least 8 characters",
                            text: $password,
                            isSecure: true
                        )

                        FormTextField(
                            title: "Confirm Password",
                            placeholder: "Re-enter your password",
                            text: $confirmPassword,
                            isSecure: true,
                            errorMessage: !passwordsMatch && !confirmPassword.isEmpty ? "Passwords do not match" : nil
                        )

                        PrimaryButton(
                            title: "Sign Up",
                            isLoading: viewModel.isLoading,
                            isDisabled: !passwordsMatch
                        ) {
                            Task {
                                await viewModel.signUp(email: email, password: password)
                                if viewModel.isAuthenticated {
                                    dismiss()
                                }
                            }
                        }
                    }

                    // Terms and Conditions
                    Text("By signing up, you agree to our Terms of Service and Privacy Policy")
                        .font(.ekoCaption)
                        .foregroundStyle(Color.ekoTertiaryLabel)
                        .multilineTextAlignment(.center)
                }
                .padding(.ekoSpacingLG)
            }
            .navigationTitle("Sign Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SignUpView(viewModel: AuthViewModel())
}
