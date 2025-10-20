import SwiftUI

struct GoalsView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var showCustomGoalInput = false
    @FocusState private var isCustomGoalFocused: Bool

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Text("Conversation Goals")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("What are your goals for conversations with \(viewModel.childName.isEmpty ? "your child" : viewModel.childName)? Select up to 3.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 32)
            .padding(.horizontal, 32)

            // Helper text
            Text(helperText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Goals list
            ScrollView {
                VStack(spacing: 12) {
                    // Predefined goals
                    ForEach(viewModel.availableGoals, id: \.self) { goal in
                        GoalCard(
                            title: goal,
                            isSelected: viewModel.selectedGoals.contains(goal),
                            onTap: {
                                toggleGoal(goal)
                            }
                        )
                        .accessibilityIdentifier("goal_\(goalIdentifier(goal))")
                    }

                    // Other option
                    VStack(spacing: 12) {
                        GoalCard(
                            title: "Other",
                            isSelected: showCustomGoalInput,
                            onTap: {
                                withAnimation {
                                    showCustomGoalInput.toggle()
                                    if showCustomGoalInput {
                                        isCustomGoalFocused = true
                                    } else {
                                        viewModel.customGoal = ""
                                    }
                                }
                            }
                        )

                        if showCustomGoalInput {
                            TextField("Enter your custom goal", text: $viewModel.customGoal)
                                .textFieldStyle(.roundedBorder)
                                .focused($isCustomGoalFocused)
                                .submitLabel(.done)
                                .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.horizontal, 32)
            }

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
                    .background(viewModel.canProceedFromGoals ? Color.accentColor : Color.gray)
                    .cornerRadius(12)
            }
            .disabled(!viewModel.canProceedFromGoals)
            .accessibilityIdentifier("nextButton")
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }

    private var helperText: String {
        let totalGoals = viewModel.selectedGoals.count + (viewModel.customGoal.isEmpty ? 0 : 1)
        if totalGoals == 0 {
            return "Select at least 1 goal"
        } else if totalGoals < 3 {
            return "\(totalGoals) selected - you can select \(3 - totalGoals) more"
        } else if totalGoals == 3 {
            return "3 goals selected"
        } else {
            return "Too many goals selected (max 3)"
        }
    }

    private func toggleGoal(_ goal: String) {
        if viewModel.selectedGoals.contains(goal) {
            viewModel.selectedGoals.removeAll { $0 == goal }
        } else {
            let totalGoals = viewModel.selectedGoals.count + (viewModel.customGoal.isEmpty ? 0 : 1)
            if totalGoals < 3 {
                viewModel.selectedGoals.append(goal)
            }
        }
    }

    private func goalIdentifier(_ goal: String) -> String {
        goal.lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "'", with: "")
            .prefix(20)
            .description
    }
}

struct GoalCard: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(title)
                    .font(.body)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .multilineTextAlignment(.leading)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .white : .secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.accentColor : Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    GoalsView(viewModel: {
        let vm = OnboardingViewModel()
        vm.childName = "Emma"
        return vm
    }())
}
