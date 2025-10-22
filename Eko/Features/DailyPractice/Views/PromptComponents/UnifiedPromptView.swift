// UnifiedPromptView.swift
// Routes to the appropriate prompt component based on prompt type

import SwiftUI
import EkoKit
import EkoCore

struct UnifiedPromptView: View {
    let prompt: DailyPracticePrompt
    @Binding var selectedOption: String?
    @Binding var selectedOptions: Set<String>
    @Binding var orderedOptions: [String]
    @Binding var textInput: String
    @Binding var matches: [String: String]
    let isOptionDisabled: (String) -> Bool

    var body: some View {
        Group {
            switch prompt.type {
            // Single-choice types
            case .stateIdentification,
                 .bestResponse,
                 .spotMistake,
                 .whatHappensNext,
                 .sequentialChoice:
                SingleChoicePromptView(
                    prompt: prompt,
                    selectedOption: $selectedOption,
                    isOptionDisabled: isOptionDisabled
                )

            // Before/After comparison
            case .beforeAfterComparison:
                BeforeAfterPromptView(
                    prompt: prompt,
                    selectedOption: $selectedOption,
                    isOptionDisabled: isOptionDisabled
                )

            // Multi-select
            case .selectAll:
                SelectAllPromptView(
                    prompt: prompt,
                    selectedOptions: $selectedOptions,
                    isOptionDisabled: isOptionDisabled
                )

            // Sequencing
            case .sequencing:
                SequencingPromptView(
                    prompt: prompt,
                    orderedOptions: $orderedOptions,
                    isOptionDisabled: isOptionDisabled
                )

            // Text input types
            case .textInput,
                 .dialogueCompletion,
                 .reflection:
                TextInputPromptView(
                    prompt: prompt,
                    textInput: $textInput
                )

            // Rating scale
            case .rating:
                RatingScalePromptView(
                    prompt: prompt,
                    selectedOption: $selectedOption
                )

            // Matching
            case .matching:
                MatchingPromptView(
                    prompt: prompt,
                    matches: $matches
                )
            }
        }
    }
}
