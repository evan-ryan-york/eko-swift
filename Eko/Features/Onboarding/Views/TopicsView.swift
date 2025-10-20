import SwiftUI
import EkoCore

struct TopicsView: View {
    @Bindable var viewModel: OnboardingViewModel

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Text("Conversation Topics")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Select at least 3 topics you'd like to focus on with \(viewModel.childName.isEmpty ? "your child" : viewModel.childName)")
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

            // Topics grid
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(ConversationTopics.all) { topic in
                        TopicCard(
                            topic: topic,
                            isSelected: viewModel.selectedTopics.contains(topic.id),
                            onTap: {
                                toggleTopic(topic.id)
                            }
                        )
                        .accessibilityIdentifier("topic_\(topic.id)")
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
                    .background(viewModel.canProceedFromTopics ? Color.accentColor : Color.gray)
                    .cornerRadius(12)
            }
            .disabled(!viewModel.canProceedFromTopics)
            .accessibilityIdentifier("nextButton")
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }

    private var helperText: String {
        let selectedCount = viewModel.selectedTopics.count
        if selectedCount < 3 {
            let remaining = 3 - selectedCount
            return "Select \(remaining) more topic\(remaining == 1 ? "" : "s")"
        } else {
            return "\(selectedCount) topics selected"
        }
    }

    private func toggleTopic(_ topicId: String) {
        if viewModel.selectedTopics.contains(topicId) {
            viewModel.selectedTopics.removeAll { $0 == topicId }
        } else {
            viewModel.selectedTopics.append(topicId)
        }
    }
}

struct TopicCard: View {
    let topic: ConversationTopic
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(topic.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .padding(.horizontal, 8)
            .background(isSelected ? Color.accentColor : Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TopicsView(viewModel: {
        let vm = OnboardingViewModel()
        vm.childName = "Emma"
        return vm
    }())
}
