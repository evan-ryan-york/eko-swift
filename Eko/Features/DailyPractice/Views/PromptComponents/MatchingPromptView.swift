// MatchingPromptView.swift
// Match pairs of items (left column to right column)

import SwiftUI
import EkoKit
import EkoCore

struct MatchingPromptView: View {
    let prompt: DailyPracticePrompt
    @Binding var matches: [String: String] // [leftId: rightId]

    @State private var leftItems: [PromptOption] = []
    @State private var rightItems: [PromptOption] = []
    @State private var selectedLeft: String?

    var body: some View {
        VStack(alignment: .leading, spacing: .ekoSpacingMD) {
            // Prompt text
            Text(prompt.promptText)
                .font(.ekoHeadline)

            // Instructions
            Text("Tap an item on the left, then tap its match on the right")
                .font(.ekoCaption)
                .foregroundColor(.secondary)

            // Matching interface
            HStack(alignment: .top, spacing: .ekoSpacingMD) {
                // Left column
                VStack(spacing: .ekoSpacingSM) {
                    ForEach(leftItems) { option in
                        leftItemButton(option: option)
                    }
                }
                .frame(maxWidth: .infinity)

                // Right column
                VStack(spacing: .ekoSpacingSM) {
                    ForEach(rightItems) { option in
                        rightItemButton(option: option)
                    }
                }
                .frame(maxWidth: .infinity)
            }

            // Matched pairs display
            if !matches.isEmpty {
                VStack(alignment: .leading, spacing: .ekoSpacingSM) {
                    Text("Matches:")
                        .font(.ekoCaption)
                        .foregroundColor(.secondary)

                    ForEach(Array(matches.keys), id: \.self) { leftId in
                        if let rightId = matches[leftId],
                           let leftOption = leftItems.first(where: { $0.optionId == leftId }),
                           let rightOption = rightItems.first(where: { $0.optionId == rightId }) {
                            matchedPairView(left: leftOption, right: rightOption)
                        }
                    }
                }
                .padding(.top, .ekoSpacingMD)
            }
        }
        .onAppear {
            initializeItems()
        }
    }

    private func leftItemButton(option: PromptOption) -> some View {
        let isSelected = selectedLeft == option.optionId
        let isMatched = matches.keys.contains(option.optionId)

        return Button {
            if !isMatched {
                selectedLeft = option.optionId
            }
        } label: {
            Text(option.optionText)
                .font(.ekoBody)
                .padding(.ekoSpacingMD)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    isMatched ? Color.ekoSuccess.opacity(0.1) :
                    isSelected ? Color.ekoPrimary.opacity(0.2) :
                    Color(.systemGray6)
                )
                .foregroundColor(isMatched ? .secondary : .primary)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isMatched ? Color.ekoSuccess :
                            isSelected ? Color.ekoPrimary :
                            Color.clear,
                            lineWidth: 2
                        )
                )
        }
        .disabled(isMatched)
    }

    private func rightItemButton(option: PromptOption) -> some View {
        let isMatched = matches.values.contains(option.optionId)

        return Button {
            if let leftId = selectedLeft, !isMatched {
                matches[leftId] = option.optionId
                selectedLeft = nil
            }
        } label: {
            Text(option.optionText)
                .font(.ekoBody)
                .padding(.ekoSpacingMD)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    isMatched ? Color.ekoSuccess.opacity(0.1) :
                    Color(.systemGray6)
                )
                .foregroundColor(isMatched ? .secondary : .primary)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isMatched ? Color.ekoSuccess : Color.clear,
                            lineWidth: 2
                        )
                )
        }
        .disabled(selectedLeft == nil || isMatched)
        .opacity(selectedLeft == nil ? 0.5 : 1.0)
    }

    private func matchedPairView(left: PromptOption, right: PromptOption) -> some View {
        HStack(spacing: .ekoSpacingSM) {
            Text(left.optionText)
                .font(.ekoCaption)
                .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "arrow.right")
                .foregroundStyle(Color.ekoSuccess)

            Text(right.optionText)
                .font(.ekoCaption)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                matches.removeValue(forKey: left.optionId)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color.secondary)
            }
        }
        .padding(.ekoSpacingSM)
        .background(Color.ekoSuccess.opacity(0.1))
        .cornerRadius(8)
    }

    private func initializeItems() {
        // Split options into left and right based on metadata
        leftItems = prompt.options.filter { option in
            // Left items don't have matchTarget metadata
            option.metadata?.matchTarget == nil
        }

        rightItems = prompt.options.filter { option in
            // Right items have matchTarget metadata
            option.metadata?.matchTarget != nil
        }

        // If no metadata, split evenly
        if leftItems.isEmpty && rightItems.isEmpty {
            let midpoint = prompt.options.count / 2
            leftItems = Array(prompt.options.prefix(midpoint))
            rightItems = Array(prompt.options.suffix(prompt.options.count - midpoint))
        }
    }
}
