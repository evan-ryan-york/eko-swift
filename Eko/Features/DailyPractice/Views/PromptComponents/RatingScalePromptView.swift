// RatingScalePromptView.swift
// Rating scale prompt with slider or discrete buttons

import SwiftUI
import EkoKit
import EkoCore

struct RatingScalePromptView: View {
    let prompt: DailyPracticePrompt
    @Binding var selectedOption: String?

    private var scaleRange: [Int] {
        prompt.config?.scaleRange ?? [1, 5]
    }

    private var scaleType: String {
        prompt.config?.scaleType ?? "discrete"
    }

    private var minValue: Int { scaleRange.first ?? 1 }
    private var maxValue: Int { scaleRange.last ?? 5 }

    @State private var sliderValue: Double = 3.0

    var body: some View {
        VStack(alignment: .leading, spacing: .ekoSpacingLG) {
            // Prompt text
            Text(prompt.promptText)
                .font(.ekoHeadline)

            if scaleType == "slider" {
                sliderView
            } else {
                discreteButtonsView
            }
        }
        .onAppear {
            sliderValue = Double((minValue + maxValue) / 2)
        }
    }

    // MARK: - Slider Version

    private var sliderView: some View {
        VStack(spacing: .ekoSpacingMD) {
            // Current value display
            Text("\(Int(sliderValue))")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(Color.ekoPrimary)

            // Slider
            Slider(value: $sliderValue, in: Double(minValue)...Double(maxValue), step: 1.0)
                .tint(.ekoPrimary)
                .onChange(of: sliderValue) { _, newValue in
                    // Find the option that matches this value
                    let valueString = String(Int(newValue))
                    if let option = prompt.options.first(where: { $0.metadata?.version == valueString }) {
                        selectedOption = option.optionId
                    } else if let option = prompt.options.first(where: { $0.optionText.contains(valueString) }) {
                        selectedOption = option.optionId
                    }
                }

            // Labels
            HStack {
                if let minOption = prompt.options.first {
                    Text(minOption.optionText)
                        .font(.ekoCaption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if let maxOption = prompt.options.last {
                    Text(maxOption.optionText)
                        .font(.ekoCaption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.ekoSpacingMD)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Discrete Buttons Version

    private var discreteButtonsView: some View {
        VStack(spacing: .ekoSpacingMD) {
            // Rating buttons
            HStack(spacing: .ekoSpacingSM) {
                ForEach(prompt.options) { option in
                    ratingButton(option: option)
                }
            }

            // Selected option label
            if let selectedId = selectedOption,
               let option = prompt.options.first(where: { $0.optionId == selectedId }) {
                Text(option.optionText)
                    .font(.ekoBody)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private func ratingButton(option: PromptOption) -> some View {
        let isSelected = selectedOption == option.optionId
        let buttonNumber = (prompt.options.firstIndex(where: { $0.id == option.id }) ?? 0) + 1

        return Button {
            selectedOption = option.optionId
        } label: {
            Text("\(buttonNumber)")
                .font(.ekoHeadline)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(isSelected ? Color.ekoPrimary : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.ekoPrimary : Color.clear, lineWidth: 2)
                )
        }
    }
}
