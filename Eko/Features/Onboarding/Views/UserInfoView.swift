import SwiftUI

struct UserInfoView: View {
    @Bindable var viewModel: OnboardingViewModel
    @FocusState private var isNameFieldFocused: Bool

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Header
            VStack(spacing: 12) {
                Text("Welcome!")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Let's get to know each other")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 20)

            // Input field
            VStack(alignment: .leading, spacing: 8) {
                Text("What's your name?")
                    .font(.headline)

                TextField("Your name", text: $viewModel.parentName)
                    .textFieldStyle(.roundedBorder)
                    .focused($isNameFieldFocused)
                    .textContentType(.name)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("parentNameField")
                    .accessibilityLabel("Your name")
                    .accessibilityHint("Enter your name to continue with onboarding")
                    .submitLabel(.next)
                    .onSubmit {
                        if viewModel.canProceedFromUserInfo {
                            Task {
                                await viewModel.moveToNextStep()
                            }
                        }
                    }
            }
            .padding(.horizontal, 32)

            Spacer()

            // Next button
            Button {
                Task {
                    await viewModel.moveToNextStep()
                }
            } label: {
                Text("Next")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.canProceedFromUserInfo ? Color.accentColor : Color.gray)
                    .cornerRadius(12)
            }
            .disabled(!viewModel.canProceedFromUserInfo)
            .accessibilityIdentifier("nextButton")
            .accessibilityLabel("Next")
            .accessibilityHint("Proceed to child information step")
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .onAppear {
            isNameFieldFocused = true
        }
    }
}

#Preview {
    UserInfoView(viewModel: OnboardingViewModel())
}
