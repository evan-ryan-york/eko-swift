import SwiftUI
import EkoCore

struct ReviewView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Text("All Set!")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Hi \(viewModel.parentName), here's a summary of your children:")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 32)
            .padding(.horizontal, 32)

            // Children list
            if viewModel.completedChildren.isEmpty {
                Spacer()
                Text("No children added yet")
                    .font(.body)
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(viewModel.completedChildren) { child in
                            ChildSummaryCard(child: child)
                        }
                    }
                    .padding(.horizontal, 32)
                }
            }

            Spacer()

            // Action buttons
            VStack(spacing: 12) {
                // Add another child button
                Button {
                    Task {
                        await viewModel.addAnotherChild()
                    }
                } label: {
                    Text("Add Another Child")
                        .font(.headline)
                        .foregroundStyle(Color.accentColor)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                .accessibilityIdentifier("addAnotherChildButton")

                // Complete setup button
                Button {
                    Task {
                        await viewModel.completeOnboarding()
                    }
                } label: {
                    Text("Complete Setup")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
                .accessibilityIdentifier("completeSetupButton")
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
}

struct ChildSummaryCard: View {
    let child: Child

    private var formattedBirthday: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: child.birthday)
    }

    private var topicNames: [String] {
        child.topics.map { topicId in
            ConversationTopics.displayName(for: topicId)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Child name
            Text(child.name)
                .font(.title2)
                .fontWeight(.semibold)

            // Birthday
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.secondary)
                Text(formattedBirthday)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Topics
            if !child.topics.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Focus Topics:")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(topicNames, id: \.self) { topicName in
                            HStack(alignment: .top, spacing: 6) {
                                Text("•")
                                    .font(.caption)
                                Text(topicName)
                                    .font(.caption)
                            }
                        }
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    ReviewView(viewModel: {
        let vm = OnboardingViewModel()
        vm.parentName = "Sarah"
        // Mock completed children
        return vm
    }())
}
