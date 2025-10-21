// TextInputPromptView.swift
// Free-text input prompt for reflection or dialogue completion

import SwiftUI
import EkoKit
import EkoCore

struct TextInputPromptView: View {
    let prompt: DailyPracticePrompt
    @Binding var textInput: String
    @FocusState private var isFocused: Bool

    private var placeholder: String {
        if prompt.type == .reflection {
            return "Share your thoughts..."
        } else if prompt.type == .dialogueCompletion {
            return "What would you say?"
        } else {
            return "Type your answer..."
        }
    }

    private var inputType: String {
        prompt.config?.inputType ?? "multiline"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .ekoSpacingMD) {
            // Prompt text
            Text(prompt.promptText)
                .font(.ekoHeadline)

            // Instructions
            if let config = prompt.config, let wordBank = config.wordBank, !wordBank.isEmpty {
                VStack(alignment: .leading, spacing: .ekoSpacingSM) {
                    Text("Word bank:")
                        .font(.ekoCaption)
                        .foregroundColor(.secondary)

                    FlowLayout(spacing: 8) {
                        ForEach(wordBank, id: \.self) { word in
                            Text(word)
                                .font(.ekoCaption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(.systemGray5))
                                .cornerRadius(16)
                        }
                    }
                }
                .padding(.bottom, .ekoSpacingSM)
            }

            // Text input field
            if inputType == "multiline" {
                TextEditor(text: $textInput)
                    .font(.ekoBody)
                    .frame(minHeight: 120)
                    .padding(.ekoSpacingSM)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isFocused ? Color.ekoPrimary : Color.clear, lineWidth: 2)
                    )
                    .focused($isFocused)
                    .overlay(alignment: .topLeading) {
                        if textInput.isEmpty {
                            Text(placeholder)
                                .font(.ekoBody)
                                .foregroundColor(.secondary)
                                .padding(.ekoSpacingSM)
                                .padding(.top, 8)
                                .allowsHitTesting(false)
                        }
                    }
            } else {
                TextField(placeholder, text: $textInput)
                    .font(.ekoBody)
                    .padding(.ekoSpacingMD)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isFocused ? Color.ekoPrimary : Color.clear, lineWidth: 2)
                    )
                    .focused($isFocused)
            }

            // Character count (optional)
            if !textInput.isEmpty {
                Text("\(textInput.count) characters")
                    .font(.ekoCaption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}

// Helper view for word bank flow layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX,
                                     y: bounds.minY + result.frames[index].minY),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                frames.append(CGRect(x: x, y: y, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}
