// Daily Practice Activity View
// Interactive activity screen for daily practice

import SwiftUI
import EkoKit
import EkoCore

struct DailyPracticeActivityView: View {
    @State private var viewModel: DailyPracticeActivityViewModel
    @State private var showTakeaway = false
    @State private var showResults = false
    @State private var showCompletionError = false
    @State private var completionErrorMessage = ""
    @Environment(\.dismiss) private var dismiss

    init(activity: DailyPracticeActivity, dayNumber: Int) {
        self._viewModel = State(initialValue: DailyPracticeActivityViewModel(
            activity: activity,
            dayNumber: dayNumber
        ))
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: .ekoSpacingLG) {
                    // Header
                    headerView

                    // Progress
                    progressView

                    // Scenario
                    scenarioView

                    // Prompt
                    promptView

                    // Feedback
                    if viewModel.showFeedback, let feedback = viewModel.currentFeedback {
                        feedbackView(feedback: feedback)
                    }

                    Spacer(minLength: 120)
                }
                .padding(.ekoSpacingLG)
            }

            // Action Button
            VStack {
                Spacer()
                actionButton
                    .padding(.ekoSpacingLG)
                    .background(.ultraThinMaterial)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showTakeaway) {
            takeawaySheet
        }
        .sheet(isPresented: $showResults) {
            resultsSheet
        }
        .alert("Error Completing Activity", isPresented: $showCompletionError) {
            Button("Try Again") {
                Task {
                    await attemptCompletion()
                }
            }
            Button("Cancel", role: .cancel) {
                dismiss()
            }
        } message: {
            Text(completionErrorMessage)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: .ekoSpacingSM) {
                Text("Day \(viewModel.dayNumber)")
                    .font(.ekoCaption)
                    .foregroundColor(.secondary)

                Text(viewModel.activity.title)
                    .font(.ekoTitle3)
            }

            Spacer()

            Text("\(viewModel.totalScore) pts")
                .font(.ekoHeadline)
                .foregroundStyle(Color.ekoPrimary)
        }
    }

    // MARK: - Progress

    private var progressView: some View {
        VStack(alignment: .leading, spacing: .ekoSpacingSM) {
            HStack {
                Text("Question \(viewModel.currentPromptIndex + 1) of \(viewModel.activity.prompts.count)")
                    .font(.ekoCaption)
                    .foregroundColor(.secondary)
                Spacer()
            }

            ProgressView(value: viewModel.progress)
                .tint(.ekoPrimary)
        }
    }

    // MARK: - Scenario

    private var scenarioView: some View {
        VStack(alignment: .leading, spacing: .ekoSpacingMD) {
            Text("Scenario")
                .font(.ekoHeadline)
                .foregroundColor(.secondary)

            Text(viewModel.activity.scenario)
                .font(.ekoBody)
                .padding(.ekoSpacingMD)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(12)
        }
    }

    // MARK: - Prompt

    private var promptView: some View {
        UnifiedPromptView(
            prompt: viewModel.currentPrompt,
            selectedOption: $viewModel.selectedOption,
            selectedOptions: $viewModel.selectedOptions,
            orderedOptions: $viewModel.orderedOptions,
            textInput: $viewModel.textInput,
            matches: $viewModel.matches,
            isOptionDisabled: viewModel.isOptionDisabled
        )
    }

    // MARK: - Feedback

    private func feedbackView(feedback: PromptOption) -> some View {
        VStack(alignment: .leading, spacing: .ekoSpacingMD) {
            HStack {
                Image(systemName: feedback.correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(feedback.correct ? Color.ekoSuccess : Color.ekoError)
                Text(feedback.correct ? "Correct!" : "Not quite")
                    .font(.ekoHeadline)
                    .foregroundStyle(feedback.correct ? Color.ekoSuccess : Color.ekoError)
            }

            Text(feedback.feedback)
                .font(.ekoBody)

            if let scienceNote = feedback.scienceNote {
                VStack(alignment: .leading, spacing: .ekoSpacingSM) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(Color.ekoInfo)
                        Text("Why this matters")
                            .font(.ekoCaption)
                            .fontWeight(.semibold)
                    }

                    Text(scienceNote.brief)
                        .font(.ekoCaption)
                        .foregroundColor(.secondary)
                }
                .padding(.ekoSpacingMD)
                .background(Color.ekoInfo.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(.ekoSpacingMD)
        .background(feedback.correct ? Color.ekoSuccess.opacity(0.1) : Color.ekoError.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Action Button

    private var actionButton: some View {
        Group {
            if viewModel.showFeedback {
                if viewModel.currentFeedback?.correct == true {
                    if viewModel.isLastPrompt {
                        PrimaryButton(title: "See Your Takeaway") {
                            showTakeaway = true
                        }
                    } else {
                        PrimaryButton(title: "Continue") {
                            viewModel.continueToNext()
                        }
                    }
                } else {
                    SecondaryButton(title: "Try Again") {
                        viewModel.tryAgain()
                    }
                }
            } else {
                PrimaryButton(title: "Submit Answer") {
                    viewModel.submitAnswer()
                }
                .disabled(!viewModel.canSubmit || viewModel.isSubmitting)
                .opacity(viewModel.canSubmit && !viewModel.isSubmitting ? 1.0 : 0.5)
            }
        }
    }

    // MARK: - Takeaway Sheet

    private var takeawaySheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: .ekoSpacingLG) {
                    Text("Your Actionable Takeaway")
                        .font(.ekoTitle2)

                    VStack(alignment: .leading, spacing: .ekoSpacingMD) {
                        Text(viewModel.activity.actionableTakeaway.toolName)
                            .font(.ekoTitle3)
                            .foregroundStyle(Color.ekoPrimary)

                        Text("When to use it")
                            .font(.ekoHeadline)
                        Text(viewModel.activity.actionableTakeaway.whenToUse)
                            .font(.ekoBody)

                        Text("How to do it")
                            .font(.ekoHeadline)
                        ForEach(Array(viewModel.activity.actionableTakeaway.howTo.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: .ekoSpacingSM) {
                                Text("\(index + 1).")
                                    .font(.ekoBody)
                                    .fontWeight(.semibold)
                                Text(step)
                                    .font(.ekoBody)
                            }
                        }

                        Text("Why it works")
                            .font(.ekoHeadline)
                        Text(viewModel.activity.actionableTakeaway.whyItWorks)
                            .font(.ekoBody)

                        Text("Example")
                            .font(.ekoHeadline)
                        VStack(alignment: .leading, spacing: .ekoSpacingSM) {
                            Text("Situation: \(viewModel.activity.actionableTakeaway.example.situation)")
                                .font(.ekoCaption)
                            Text("Action: \(viewModel.activity.actionableTakeaway.example.action)")
                                .font(.ekoCaption)
                            Text("Outcome: \(viewModel.activity.actionableTakeaway.example.outcome)")
                                .font(.ekoCaption)
                        }
                        .padding(.ekoSpacingMD)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }

                    Spacer(minLength: 80)
                }
                .padding(.ekoSpacingLG)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    PrimaryButton(title: "Complete") {
                        showTakeaway = false
                        Task {
                            await attemptCompletion()
                        }
                    }
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Results Sheet

    private var resultsSheet: some View {
        VStack(spacing: .ekoSpacingLG) {
            Text("🎉")
                .font(.system(size: 80))

            Text("Day \(viewModel.dayNumber) Complete!")
                .font(.ekoTitle1)

            VStack(spacing: .ekoSpacingSM) {
                Text("You earned")
                    .font(.ekoBody)
                    .foregroundColor(.secondary)

                Text("\(viewModel.totalScore)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.ekoPrimary)

                Text("points")
                    .font(.ekoBody)
                    .foregroundColor(.secondary)
            }

            PrimaryButton(title: "Done") {
                showResults = false
                dismiss()
            }
            .padding(.horizontal, .ekoSpacingLG)
        }
        .padding(.ekoSpacingLG)
        .presentationDetents([.medium])
    }

    // MARK: - Helpers

    private func attemptCompletion() async {
        do {
            try await viewModel.completeActivity()
            showResults = true
        } catch {
            completionErrorMessage = error.localizedDescription
            showCompletionError = true
        }
    }
}

#Preview {
    // Create a mock activity for preview
    let mockActivity = DailyPracticeActivity(
        id: UUID(),
        createdAt: nil,
        updatedAt: nil,
        dayNumber: 1,
        ageBand: "6-9",
        moduleName: "test",
        moduleDisplayName: "Test Module",
        title: "Understanding Your Child's Emotions",
        description: nil,
        skillFocus: "Emotion Recognition",
        category: nil,
        activityType: "basic-scenario",
        isReflection: false,
        scenario: "Your 7-year-old comes home from school and slams the door. When you ask what's wrong, they yell 'Nothing!' and stomp to their room.",
        researchConcept: nil,
        researchKeyInsight: nil,
        researchCitation: nil,
        researchAdditionalContext: nil,
        bestApproach: nil,
        followUpQuestions: nil,
        prompts: [
            DailyPracticePrompt(
                promptId: "p1",
                type: .stateIdentification,
                promptText: "What state is your child in?",
                order: 1,
                points: 10,
                branchLogic: nil,
                options: [
                    PromptOption(
                        optionId: "o1",
                        optionText: "State 1 (Regulated)",
                        correct: false,
                        points: 0,
                        feedback: "Not quite. Their behavior shows signs of dysregulation."
                    ),
                    PromptOption(
                        optionId: "o2",
                        optionText: "State 2 (Dysregulated)",
                        correct: true,
                        points: 10,
                        feedback: "Correct! The door slamming and yelling indicate they're in State 2.",
                        scienceNote: ScienceNote(
                            brief: "When children are dysregulated, their prefrontal cortex is less active, making logical conversation difficult.",
                            citation: nil,
                            showCitation: false
                        )
                    )
                ]
            )
        ],
        actionableTakeaway: ActionableTakeaway(
            toolName: "Regulated Presence",
            toolType: "diagnostic",
            whenToUse: "When your child is dysregulated",
            howTo: [
                "Stay calm yourself",
                "Give them space if needed",
                "Let them know you're available"
            ],
            whyItWorks: "Your calm presence helps their nervous system regulate.",
            tryItWhen: "Try it the next time your child comes home upset",
            example: TakeawayExample(
                situation: "Child is upset after school",
                action: "Parent stays calm and says 'I'm here when you're ready'",
                outcome: "Child calms down and opens up after 10 minutes"
            )
        )
    )

    return NavigationStack {
        DailyPracticeActivityView(activity: mockActivity, dayNumber: 1)
    }
}
