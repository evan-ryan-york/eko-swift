import SwiftUI
import EkoKit

// MARK: - Chat Input Bar
struct ChatInputBar: View {
    @Binding var text: String
    let isLoading: Bool
    let onSend: () -> Void
    let onVoiceTap: () -> Void

    var body: some View {
        HStack(spacing: .ekoSpacingSM) {
            // Text field
            TextField("Ask Lyra anything...", text: $text, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...5)
                .disabled(isLoading)
                .onSubmit {
                    if !text.isEmpty && !isLoading {
                        onSend()
                    }
                }

            // Voice button
            Button(action: onVoiceTap) {
                Image(systemName: "mic.fill")
                    .foregroundStyle(Color.ekoPrimary)
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .disabled(isLoading)

            // Send button
            Button(action: onSend) {
                if isLoading {
                    ProgressView()
                        .frame(width: 24, height: 24)
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundStyle(Color.ekoPrimary)
                        .font(.title2)
                }
            }
            .frame(width: 44, height: 44)
            .disabled(text.isEmpty || isLoading)
            .opacity(text.isEmpty && !isLoading ? 0.5 : 1.0)
        }
        .padding(.ekoSpacingSM)
        .background(Color.ekoSecondaryBackground)
    }
}

// MARK: - Preview
#Preview("Empty State") {
    ChatInputBar(
        text: .constant(""),
        isLoading: false,
        onSend: {},
        onVoiceTap: {}
    )
}

#Preview("With Text") {
    ChatInputBar(
        text: .constant("How can I help my child with homework?"),
        isLoading: false,
        onSend: {},
        onVoiceTap: {}
    )
}

#Preview("Loading") {
    ChatInputBar(
        text: .constant(""),
        isLoading: true,
        onSend: {},
        onVoiceTap: {}
    )
}
