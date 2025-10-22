// BeforeAfterPromptView.swift
// Side-by-side comparison of two approaches

import SwiftUI
import EkoKit
import EkoCore

struct BeforeAfterPromptView: View {
    let prompt: DailyPracticePrompt
    @Binding var selectedOption: String?
    let isOptionDisabled: (String) -> Bool

    private var beforeOption: PromptOption? {
        prompt.options.first { $0.metadata?.version == "before" }
    }

    private var afterOption: PromptOption? {
        prompt.options.first { $0.metadata?.version == "after" }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .ekoSpacingMD) {
            // Prompt text
            Text(prompt.promptText)
                .font(.ekoHeadline)

            // Before/After comparison
            if let before = beforeOption, let after = afterOption {
                VStack(spacing: .ekoSpacingMD) {
                    // Before version
                    comparisonCard(
                        option: before,
                        label: "Approach A",
                        color: .orange
                    )

                    // After version
                    comparisonCard(
                        option: after,
                        label: "Approach B",
                        color: .blue
                    )
                }
            } else {
                // Fallback to standard options if before/after not marked
                ForEach(prompt.options) { option in
                    standardOptionButton(option: option)
                }
            }
        }
    }

    private func comparisonCard(option: PromptOption, label: String, color: Color) -> some View {
        let isSelected = selectedOption == option.optionId
        let isDisabled = isOptionDisabled(option.optionId)

        return Button {
            if !isDisabled {
                selectedOption = option.optionId
            }
        } label: {
            VStack(alignment: .leading, spacing: .ekoSpacingSM) {
                // Label
                HStack {
                    Text(label)
                        .font(.ekoCaption)
                        .fontWeight(.semibold)
                        .foregroundColor(color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(color.opacity(0.1))
                        .cornerRadius(8)

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.ekoPrimary)
                    }
                }

                // Option text
                Text(option.optionText)
                    .font(.ekoBody)
                    .foregroundColor(isDisabled ? .secondary : .primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
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

    private func standardOptionButton(option: PromptOption) -> some View {
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
