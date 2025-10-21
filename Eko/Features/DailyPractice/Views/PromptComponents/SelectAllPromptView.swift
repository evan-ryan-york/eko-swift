// SelectAllPromptView.swift
// Multiple selection prompt with checkboxes

import SwiftUI
import EkoKit
import EkoCore

struct SelectAllPromptView: View {
    let prompt: DailyPracticePrompt
    @Binding var selectedOptions: Set<String>
    let isOptionDisabled: (String) -> Bool

    var body: some View {
        VStack(alignment: .leading, spacing: .ekoSpacingMD) {
            // Prompt text
            Text(prompt.promptText)
                .font(.ekoHeadline)

            // Instructions
            if let config = prompt.config, let minCorrect = config.minCorrect {
                Text("Select at least \(minCorrect) option\(minCorrect > 1 ? "s" : "")")
                    .font(.ekoCaption)
                    .foregroundColor(.secondary)
            } else {
                Text("Select all that apply")
                    .font(.ekoCaption)
                    .foregroundColor(.secondary)
            }

            // Options
            ForEach(prompt.options) { option in
                optionCheckbox(option: option)
            }
        }
    }

    private func optionCheckbox(option: PromptOption) -> some View {
        Button {
            if !isOptionDisabled(option.optionId) {
                toggleSelection(option.optionId)
            }
        } label: {
            HStack(spacing: .ekoSpacingMD) {
                // Checkbox
                Image(systemName: selectedOptions.contains(option.optionId) ? "checkmark.square.fill" : "square")
                    .font(.system(size: 24))
                    .foregroundStyle(
                        isOptionDisabled(option.optionId)
                            ? Color.secondary
                            : (selectedOptions.contains(option.optionId) ? Color.ekoPrimary : Color.secondary)
                    )

                // Option text
                Text(option.optionText)
                    .font(.ekoBody)
                    .foregroundColor(isOptionDisabled(option.optionId) ? .secondary : .primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.ekoSpacingMD)
            .background(
                isOptionDisabled(option.optionId)
                    ? Color(.systemGray5)
                    : (selectedOptions.contains(option.optionId)
                       ? Color.ekoPrimary.opacity(0.1)
                       : Color(.systemGray6))
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        selectedOptions.contains(option.optionId) ? Color.ekoPrimary : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .disabled(isOptionDisabled(option.optionId))
    }

    private func toggleSelection(_ optionId: String) {
        if selectedOptions.contains(optionId) {
            selectedOptions.remove(optionId)
        } else {
            selectedOptions.insert(optionId)
        }
    }
}
