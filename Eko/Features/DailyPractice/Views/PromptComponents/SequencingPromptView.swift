// SequencingPromptView.swift
// Drag-to-reorder sequence prompt

import SwiftUI
import EkoKit
import EkoCore

struct SequencingPromptView: View {
    let prompt: DailyPracticePrompt
    @Binding var orderedOptions: [String]
    let isOptionDisabled: (String) -> Bool

    @State private var availableOptions: [PromptOption] = []

    var body: some View {
        VStack(alignment: .leading, spacing: .ekoSpacingMD) {
            // Prompt text
            Text(prompt.promptText)
                .font(.ekoHeadline)

            // Instructions
            Text("Tap to add items in the correct order")
                .font(.ekoCaption)
                .foregroundColor(.secondary)

            // Ordered sequence (what user has arranged)
            if !orderedOptions.isEmpty {
                VStack(spacing: .ekoSpacingSM) {
                    Text("Your sequence:")
                        .font(.ekoCaption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(Array(orderedOptions.enumerated()), id: \.offset) { index, optionId in
                        if let option = prompt.options.first(where: { $0.optionId == optionId }) {
                            orderedItemView(option: option, position: index + 1)
                        }
                    }
                }
                .padding(.vertical, .ekoSpacingSM)
            }

            // Available options (not yet ordered)
            if !availableOptions.isEmpty {
                VStack(spacing: .ekoSpacingSM) {
                    Text("Available steps:")
                        .font(.ekoCaption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(availableOptions) { option in
                        availableOptionButton(option: option)
                    }
                }
            }
        }
        .onAppear {
            initializeAvailableOptions()
        }
    }

    private func orderedItemView(option: PromptOption, position: Int) -> some View {
        HStack(spacing: .ekoSpacingMD) {
            // Position number
            Text("\(position)")
                .font(.ekoHeadline)
                .foregroundStyle(Color.ekoPrimary)
                .frame(width: 32, height: 32)
                .background(Color.ekoPrimary.opacity(0.1))
                .clipShape(Circle())

            // Option text
            Text(option.optionText)
                .font(.ekoBody)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Remove button
            Button {
                removeFromSequence(option.optionId)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color.secondary)
            }
        }
        .padding(.ekoSpacingMD)
        .background(Color.ekoPrimary.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.ekoPrimary, lineWidth: 2)
        )
    }

    private func availableOptionButton(option: PromptOption) -> some View {
        Button {
            addToSequence(option.optionId)
        } label: {
            HStack {
                Text(option.optionText)
                    .font(.ekoBody)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)

                Spacer()

                Image(systemName: "plus.circle")
                    .foregroundStyle(Color.ekoPrimary)
            }
            .padding(.ekoSpacingMD)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    private func initializeAvailableOptions() {
        if orderedOptions.isEmpty {
            availableOptions = prompt.options
        } else {
            availableOptions = prompt.options.filter { option in
                !orderedOptions.contains(option.optionId)
            }
        }
    }

    private func addToSequence(_ optionId: String) {
        orderedOptions.append(optionId)
        availableOptions.removeAll { $0.optionId == optionId }
    }

    private func removeFromSequence(_ optionId: String) {
        orderedOptions.removeAll { $0 == optionId }
        if let option = prompt.options.first(where: { $0.optionId == optionId }) {
            availableOptions.append(option)
        }
    }
}
