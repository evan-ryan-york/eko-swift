// SingleChoicePromptView.swift
// Standard single-choice selection (used for most prompt types)

import SwiftUI
import EkoKit
import EkoCore

struct SingleChoicePromptView: View {
    let prompt: DailyPracticePrompt
    @Binding var selectedOption: String?
    let isOptionDisabled: (String) -> Bool

    var body: some View {
        VStack(alignment: .leading, spacing: .ekoSpacingMD) {
            // Prompt text
            Text(prompt.promptText)
                .font(.ekoHeadline)

            // Options
            ForEach(prompt.options) { option in
                optionButton(option: option)
            }
        }
    }

    private func optionButton(option: PromptOption) -> some View {
        let isSelected = selectedOption == option.optionId
        let isDisabled = isOptionDisabled(option.optionId)

        return Button {
            if !isDisabled {
                selectedOption = option.optionId
            }
        } label: {
            HStack {
                Text(option.optionText)
                    .font(.ekoBody)
                    .foregroundColor(isDisabled ? .secondary : .primary)
                    .multilineTextAlignment(.leading)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.ekoPrimary)
                }
            }
            .padding(.ekoSpacingMD)
            .background(
                isDisabled ? Color(.systemGray5) :
                isSelected ? Color.ekoPrimary.opacity(0.1) :
                Color(.systemGray6)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.ekoPrimary : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .disabled(isDisabled)
    }
}
