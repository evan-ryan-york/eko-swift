import SwiftUI
import EkoKit

struct LoginView: View {
    @State private var viewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showingSignUp = false

    init(viewModel: AuthViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .ekoSpacingXL) {
                    // Logo/Header
                    VStack(spacing: .ekoSpacingSM) {
                        Text("Eko")
                            .ekoDisplayStyle()

                        Text("Better conversations with your kids")
                            .ekoSubheadlineStyle()
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, .ekoSpacingXXL)

                    // Google Sign In Button
                    VStack(spacing: .ekoSpacingLG) {
                        PrimaryButton(
                            title: "Continue with Google",
                            isLoading: viewModel.isLoading
                        ) {
                            Task {
                                await viewModel.signInWithGoogle()
                            }
                        }

                        // Error Message
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.ekoFootnote)
                                .foregroundStyle(Color.ekoError)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        // Divider
                        HStack {
                            Rectangle()
                                .fill(Color.ekoSeparator)
                                .frame(height: 1)

                            Text("or")
                                .font(.ekoCaption)
                                .foregroundStyle(Color.ekoTertiaryLabel)
                                .padding(.horizontal, .ekoSpacingXS)

                            Rectangle()
                                .fill(Color.ekoSeparator)
                                .frame(height: 1)
                        }
                        .padding(.vertical, .ekoSpacingSM)

                        // Email/Password Form
                        FormTextField(
                            title: "Email",
                            placeholder: "Enter your email",
                            text: $email,
                            keyboardType: .emailAddress
                        )

                        FormTextField(
                            title: "Password",
                            placeholder: "Enter your password",
                            text: $password,
                            isSecure: true
                        )

                        SecondaryButton(
                            title: "Sign In with Email",
                            isLoading: viewModel.isLoading
                        ) {
                            Task {
                                await viewModel.signIn(email: email, password: password)
                            }
                        }
                    }

                    // Secondary Actions
                    VStack(spacing: .ekoSpacingMD) {
                        Button("Forgot Password?") {
                            Task {
                                await viewModel.resetPassword(email: email)
                            }
                        }
                        .font(.ekoCallout)
                        .foregroundStyle(Color.ekoPrimary)

                        HStack {
                            Text("Don't have an account?")
                                .font(.ekoCallout)
                                .foregroundStyle(Color.ekoSecondaryLabel)

                            Button("Sign Up") {
                                showingSignUp = true
                            }
                            .font(.ekoCallout)
                            .foregroundStyle(Color.ekoPrimary)
                        }
                    }
                }
                .padding(.ekoSpacingLG)
            }
            .navigationTitle("Welcome Back")
            .sheet(isPresented: $showingSignUp) {
                SignUpView(viewModel: viewModel)
            }
        }
    }
}

#Preview {
    LoginView(viewModel: AuthViewModel())
}
