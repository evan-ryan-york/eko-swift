// Daily Practice Activity View Model
// Manages the state during a daily practice activity session

import Foundation
import Observation
import EkoCore

@MainActor
@Observable
final class DailyPracticeActivityViewModel {
    // MARK: - Activity Data

    let activity: DailyPracticeActivity
    let dayNumber: Int

    // MARK: - Session Tracking

    private(set) var sessionId: UUID?

    // MARK: - Progress Tracking

    private(set) var currentPromptIndex = 0
    private(set) var totalScore = 0
    private(set) var promptAttempts: [String: PromptAttempt] = [:]

    // MARK: - UI State

    var selectedOption: String?
    var selectedOptions: Set<String> = []
    var orderedOptions: [String] = []
    var textInput: String = ""
    var matches: [String: String] = [:] // [leftId: rightId]
    var showFeedback = false
    var currentFeedback: PromptOption?
    var isSubmitting = false
    var isCompleting = false

    private let supabase: SupabaseService

    // MARK: - Computed Properties

    var currentPrompt: DailyPracticePrompt {
        activity.prompts[currentPromptIndex]
    }

    var isLastPrompt: Bool {
        currentPromptIndex == activity.prompts.count - 1
    }

    var canSubmit: Bool {
        switch currentPrompt.type {
        case .selectAll:
            // Check if minimum required selections are met
            if let config = currentPrompt.config, let minCorrect = config.minCorrect {
                return selectedOptions.count >= minCorrect
            }
            return !selectedOptions.isEmpty

        case .sequencing:
            return orderedOptions.count == currentPrompt.options.count

        case .textInput, .dialogueCompletion, .reflection:
            return !textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        case .matching:
            return matches.count == (currentPrompt.options.count / 2)

        default:
            return selectedOption != nil
        }
    }

    var progress: Double {
        Double(currentPromptIndex + 1) / Double(activity.prompts.count)
    }

    // MARK: - Initialization

    init(activity: DailyPracticeActivity, dayNumber: Int, supabase: SupabaseService = .shared) {
        self.activity = activity
        self.dayNumber = dayNumber
        self.supabase = supabase

        // Start session (non-blocking analytics)
        Task {
            await startSession()
        }
    }

    // MARK: - Private Methods

    private func startSession() async {
        sessionId = await supabase.startSession(activityId: activity.id, dayNumber: dayNumber)
    }

    // MARK: - Public Methods - Option Selection

    func selectOption(_ optionId: String) {
        selectedOption = optionId
    }

    func toggleOptionSelection(_ optionId: String) {
        if selectedOptions.contains(optionId) {
            selectedOptions.remove(optionId)
        } else {
            selectedOptions.insert(optionId)
        }
    }

    func addToSequence(_ optionId: String) {
        if !orderedOptions.contains(optionId) {
            orderedOptions.append(optionId)
        }
    }

    func removeFromSequence(at index: Int) {
        orderedOptions.remove(at: index)
    }

    func isOptionDisabled(_ optionId: String) -> Bool {
        guard let attempt = promptAttempts[currentPrompt.promptId] else {
            return false
        }
        return attempt.attemptedOptions.contains(optionId)
    }

    // MARK: - Public Methods - Answer Submission

    func submitAnswer() {
        isSubmitting = true

        // Get current attempts for this prompt
        var attempt = promptAttempts[currentPrompt.promptId] ?? PromptAttempt(
            promptId: currentPrompt.promptId,
            attemptedOptions: [],
            pointsEarned: 0,
            completed: false
        )

        let attemptNumber = attempt.attemptedOptions.count + 1
        var isCorrect = false
        var feedbackOption: PromptOption?
        var pointsEarned = 0

        // Evaluate answer based on prompt type
        switch currentPrompt.type {
        case .selectAll:
            // Check if all selected options are correct
            let correctOptions = currentPrompt.options.filter { $0.correct }
            let allCorrectSelected = correctOptions.allSatisfy { selectedOptions.contains($0.optionId) }
            let noIncorrectSelected = selectedOptions.allSatisfy { id in
                currentPrompt.options.first(where: { $0.optionId == id })?.correct ?? false
            }
            isCorrect = allCorrectSelected && noIncorrectSelected

            // Find feedback (use first selected option's feedback for now)
            if let firstSelected = selectedOptions.first {
                feedbackOption = currentPrompt.options.first(where: { $0.optionId == firstSelected })
            }

            // Record attempt
            attempt.attemptedOptions.append(selectedOptions.joined(separator: ","))

        case .sequencing:
            // Check if sequence is in correct order
            isCorrect = orderedOptions.enumerated().allSatisfy { index, optionId in
                if let option = currentPrompt.options.first(where: { $0.optionId == optionId }),
                   let correctOrder = option.metadata?.correctOrder {
                    return correctOrder == index + 1
                }
                return false
            }

            // Use first option's feedback
            if let firstId = orderedOptions.first {
                feedbackOption = currentPrompt.options.first(where: { $0.optionId == firstId })
            }

            attempt.attemptedOptions.append(orderedOptions.joined(separator: ","))

        case .textInput, .dialogueCompletion:
            // For text input, always award points for completion
            isCorrect = true
            // Create synthetic feedback option
            feedbackOption = PromptOption(
                optionId: "text-input",
                optionText: textInput,
                correct: true,
                points: currentPrompt.points,
                feedback: "Great! Your response shows thoughtful consideration."
            )

            attempt.attemptedOptions.append("text:\(textInput)")

        case .reflection:
            // Reflection has no wrong answer, always award points
            isCorrect = true
            feedbackOption = PromptOption(
                optionId: "reflection",
                optionText: textInput,
                correct: true,
                points: currentPrompt.points,
                feedback: "Thank you for sharing your thoughts."
            )

            attempt.attemptedOptions.append("reflection:\(textInput)")

        case .matching:
            // Check if all matches are correct
            isCorrect = matches.allSatisfy { leftId, rightId in
                if let leftOption = currentPrompt.options.first(where: { $0.optionId == leftId }),
                   let matchTarget = leftOption.metadata?.matchTarget {
                    return matchTarget == rightId
                }
                return false
            }

            // Use first match's feedback
            if let firstMatch = matches.first {
                feedbackOption = currentPrompt.options.first(where: { $0.optionId == firstMatch.key })
            }

            attempt.attemptedOptions.append(matches.map { "\($0.key):\($0.value)" }.joined(separator: ","))

        default:
            // Single-choice prompts
            guard let selectedId = selectedOption,
                  let option = currentPrompt.options.first(where: { $0.optionId == selectedId }) else {
                isSubmitting = false
                return
            }

            isCorrect = option.correct
            feedbackOption = option
            attempt.attemptedOptions.append(selectedId)
        }

        // Calculate points
        pointsEarned = calculatePoints(
            totalPoints: currentPrompt.points,
            totalOptions: currentPrompt.options.count,
            attemptNumber: attemptNumber,
            isCorrect: isCorrect
        )

        // Update attempt
        if isCorrect {
            attempt.completed = true
            attempt.pointsEarned = pointsEarned
            totalScore += pointsEarned
        }
        promptAttempts[currentPrompt.promptId] = attempt

        // Show feedback
        currentFeedback = feedbackOption
        showFeedback = true
        isSubmitting = false

        // Track analytics (non-blocking)
        Task {
            let promptResult = PromptResult(
                promptId: currentPrompt.promptId,
                tries: attemptNumber,
                logs: attempt.attemptedOptions.map { optId in
                    AttemptLog(
                        optionId: optId,
                        correct: isCorrect,
                        timestamp: ISO8601DateFormatter().string(from: Date())
                    )
                },
                pointsEarned: attempt.pointsEarned,
                completed: attempt.completed
            )
            await supabase.updatePromptResult(sessionId: sessionId, promptResult: promptResult)
        }
    }

    func tryAgain() {
        showFeedback = false
        selectedOption = nil
        selectedOptions = []
        textInput = ""
        matches = [:]
        currentFeedback = nil
    }

    func continueToNext() {
        showFeedback = false
        selectedOption = nil
        selectedOptions = []
        orderedOptions = []
        textInput = ""
        matches = [:]
        currentFeedback = nil
        currentPromptIndex += 1
    }

    // MARK: - Public Methods - Completion

    func completeActivity() async throws {
        isCompleting = true

        do {
            let response = try await supabase.completeActivity(
                dayNumber: dayNumber,
                totalScore: totalScore,
                sessionId: sessionId
            )

            if !response.success {
                throw NSError(domain: "DailyPractice", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: response.message ?? "Failed to complete activity"
                ])
            }

            isCompleting = false
        } catch {
            isCompleting = false
            throw error
        }
    }

    // MARK: - Private Helpers

    private func calculatePoints(totalPoints: Int, totalOptions: Int, attemptNumber: Int, isCorrect: Bool) -> Int {
        // Full points on first correct attempt
        if attemptNumber == 1 && isCorrect {
            return totalPoints
        }

        // No points for wrong answers
        if !isCorrect {
            return 0
        }

        // No partial credit for binary choices
        if totalOptions <= 2 {
            return 0
        }

        // Calculate partial credit based on remaining options
        let remainingAttempts = totalOptions - attemptNumber
        if remainingAttempts <= 0 {
            return 0
        }

        let numerator = Double(totalPoints * remainingAttempts)
        let denominator = Double(totalOptions - 1)
        let points = Int(ceil(numerator / denominator))

        return max(0, points)
    }
}

// MARK: - Supporting Types

struct PromptAttempt {
    let promptId: String
    var attemptedOptions: [String]
    var pointsEarned: Int
    var completed: Bool
}
