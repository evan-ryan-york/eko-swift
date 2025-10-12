import SwiftUI
import EkoCore
import EkoKit

// MARK: - Message Bubble View
struct MessageBubbleView: View {
    let message: Message
    @State private var showingSources = false

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 50)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: .ekoSpacingXS) {
                // Message content
                Text(message.content)
                    .font(.ekoBody)
                    .foregroundStyle(message.role == .user ? .white : Color.ekoLabel)
                    .padding(.ekoSpacingMD)
                    .background(
                        RoundedRectangle(cornerRadius: .ekoRadiusMD)
                            .fill(message.role == .user ? Color.ekoPrimary : Color.ekoSurface)
                    )

                // Sources button
                if let sources = message.sources, !sources.isEmpty {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showingSources.toggle()
                        }
                    } label: {
                        Label(
                            "\(sources.count) source\(sources.count == 1 ? "" : "s")",
                            systemImage: "book.fill"
                        )
                        .font(.ekoCaption)
                        .foregroundStyle(Color.ekoSecondaryLabel)
                    }
                }

                // Expanded sources
                if showingSources, let sources = message.sources {
                    VStack(alignment: .leading, spacing: .ekoSpacingXS) {
                        ForEach(sources) { source in
                            CitationView(citation: source)
                        }
                    }
                    .transition(.opacity)
                }

                // Timestamp
                Text(message.timestamp, style: .time)
                    .font(.ekoCaption)
                    .foregroundStyle(Color.ekoTertiaryLabel)
            }
            .frame(maxWidth: 300, alignment: message.role == .user ? .trailing : .leading)

            if message.role != .user {
                Spacer(minLength: 50)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showingSources)
    }
}

// MARK: - Citation View
struct CitationView: View {
    let citation: Citation

    var body: some View {
        VStack(alignment: .leading, spacing: .ekoSpacingXXS) {
            if let url = citation.url {
                Link(destination: url) {
                    HStack {
                        Image(systemName: "link")
                            .font(.ekoCaption)
                        Text(citation.title)
                            .font(.ekoCaption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(Color.ekoPrimary)
                }
            } else {
                HStack {
                    Image(systemName: "doc.text")
                        .font(.ekoCaption)
                    Text(citation.title)
                        .font(.ekoCaption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(Color.ekoSecondaryLabel)
            }

            Text(citation.excerpt)
                .font(.ekoCaption)
                .foregroundStyle(Color.ekoTertiaryLabel)
                .lineLimit(2)
        }
        .padding(.ekoSpacingSM)
        .background(
            RoundedRectangle(cornerRadius: .ekoRadiusSM)
                .fill(Color.ekoSecondaryBackground)
        )
    }
}

// MARK: - Preview
#Preview("User Message") {
    MessageBubbleView(
        message: Message(
            id: UUID(),
            role: .user,
            content: "How can I help my child with bedtime resistance?",
            timestamp: Date()
        )
    )
    .padding()
}

#Preview("Assistant Message") {
    MessageBubbleView(
        message: Message(
            id: UUID(),
            role: .assistant,
            content: "I understand bedtime can be challenging. For a sensitive child like yours, try creating a predictable routine that gives them a sense of control. Offer two choices: 'Would you like to brush teeth first or put on pajamas first?'",
            timestamp: Date()
        )
    )
    .padding()
}

#Preview("Message with Sources") {
    MessageBubbleView(
        message: Message(
            id: UUID(),
            role: .assistant,
            content: "Research shows that consistent bedtime routines help children feel secure.",
            timestamp: Date(),
            sources: [
                Citation(
                    id: UUID(),
                    title: "The Science of Sleep",
                    url: URL(string: "https://example.com"),
                    excerpt: "Consistent routines signal to the brain that it's time to wind down..."
                ),
                Citation(
                    id: UUID(),
                    title: "Parenting Guide",
                    url: nil,
                    excerpt: "Children thrive with predictable patterns..."
                )
            ]
        )
    )
    .padding()
}
