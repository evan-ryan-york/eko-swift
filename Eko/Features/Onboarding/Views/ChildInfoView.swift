import SwiftUI

struct ChildInfoView: View {
    @Bindable var viewModel: OnboardingViewModel
    @FocusState private var isNameFieldFocused: Bool

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Header
            VStack(spacing: 12) {
                Text("Child Information")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Tell us about your child")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 20)

            // Form fields
            VStack(spacing: 24) {
                // Child's name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Child's Name")
                        .font(.headline)

                    TextField("Child's name", text: $viewModel.childName)
                        .textFieldStyle(.roundedBorder)
                        .focused($isNameFieldFocused)
                        .textContentType(.name)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("childNameField")
                        .submitLabel(.next)
                        .onSubmit {
                            isNameFieldFocused = false
                        }
                }

                // Child's birthday
                VStack(alignment: .leading, spacing: 8) {
                    Text("Child's Birthday")
                        .font(.headline)

                    DatePicker(
                        "Birthday",
                        selection: $viewModel.childBirthday,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .accessibilityIdentifier("childBirthdayPicker")
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
                    .background(viewModel.canProceedFromChildInfo ? Color.accentColor : Color.gray)
                    .cornerRadius(12)
            }
            .disabled(!viewModel.canProceedFromChildInfo)
            .accessibilityIdentifier("nextButton")
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .onAppear {
            isNameFieldFocused = true
        }
    }
}

#Preview {
    ChildInfoView(viewModel: OnboardingViewModel())
}
