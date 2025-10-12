import SwiftUI

// MARK: - Typing Indicator View
public struct TypingIndicatorView: View {
    @State private var animationAmount = 0.0

    public init() {}

    public var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.secondary.opacity(0.6))
                    .frame(width: 8, height: 8)
                    .scaleEffect(animationAmount == Double(index) ? 1.2 : 0.8)
                    .animation(
                        .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                        value: animationAmount
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.tertiarySystemBackground))
        )
        .onAppear {
            animationAmount = 1.0
        }
    }
}

// MARK: - Preview
#Preview {
    VStack {
        TypingIndicatorView()
        Text("Lyra is typing...")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
}
