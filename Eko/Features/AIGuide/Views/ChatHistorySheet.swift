import SwiftUI
import EkoCore
import EkoKit

// MARK: - Chat History Sheet
struct ChatHistorySheet: View {
    let childId: UUID
    @Environment(\.dismiss) private var dismiss
    @State private var conversations: [Conversation] = []
    @State private var isLoading = true
    @State private var error: Error?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    VStack(spacing: .ekoSpacingSM) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading history...")
                            .font(.ekoCaption)
                            .foregroundStyle(Color.ekoSecondaryLabel)
                    }
                } else if conversations.isEmpty {
                    emptyStateView
                } else {
                    conversationList
                }
            }
            .navigationTitle("Conversation History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadHistory()
            }
            .refreshable {
                await loadHistory()
            }
        }
    }

    // MARK: - Conversation List
    private var conversationList: some View {
        List(conversations) { conversation in
            NavigationLink {
                ConversationDetailView(conversation: conversation)
            } label: {
                VStack(alignment: .leading, spacing: .ekoSpacingXS) {
                    Text(conversation.title ?? "Untitled Conversation")
                        .font(.ekoHeadline)
                        .foregroundStyle(Color.ekoLabel)

                    Text(conversation.updatedAt, style: .relative)
                        .font(.ekoCaption)
                        .foregroundStyle(Color.ekoSecondaryLabel)
                }
                .padding(.vertical, .ekoSpacingXS)
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: .ekoSpacingLG) {
            Image(systemName: "clock")
                .font(.system(size: 64))
                .foregroundStyle(Color.ekoSecondaryLabel.opacity(0.5))

            VStack(spacing: .ekoSpacingXS) {
                Text("No History Yet")
                    .font(.ekoTitle2)
                    .foregroundStyle(Color.ekoLabel)

                Text("Your completed conversations will appear here")
                    .font(.ekoBody)
                    .foregroundStyle(Color.ekoSecondaryLabel)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }

    // MARK: - Data Loading
    private func loadHistory() async {
        isLoading = true
        error = nil

        // TODO: Implement actual API call to fetch completed conversations
        // For now, using placeholder
        do {
            // Simulated delay
            try await Task.sleep(for: .seconds(0.5))

            // TODO: Replace with actual API call
            // conversations = try await SupabaseService.shared.getCompletedConversations(childId: childId)
            conversations = []
        } catch {
            self.error = error
        }

        isLoading = false
    }
}

// MARK: - Conversation Detail View
struct ConversationDetailView: View {
    let conversation: Conversation
    @State private var messages: [Message] = []
    @State private var isLoading = true

    var body: some View {
        ScrollView {
            LazyVStack(spacing: .ekoSpacingMD) {
                if isLoading {
                    VStack(spacing: .ekoSpacingSM) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading messages...")
                            .font(.ekoCaption)
                            .foregroundStyle(Color.ekoSecondaryLabel)
                    }
                    .padding(.ekoSpacingXL)
                } else if messages.isEmpty {
                    Text("No messages found")
                        .foregroundStyle(Color.ekoSecondaryLabel)
                        .padding()
                } else {
                    ForEach(messages) { message in
                        MessageBubbleView(message: message)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(conversation.title ?? "Conversation")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadMessages()
        }
    }

    private func loadMessages() async {
        isLoading = true

        do {
            messages = try await SupabaseService.shared.getMessages(
                conversationId: conversation.id
            )
        } catch {
            print("Error loading messages: \(error)")
        }

        isLoading = false
    }
}

// MARK: - Preview
#Preview("History with Items") {
    ChatHistorySheet(childId: UUID())
}

#Preview("Empty History") {
    ChatHistorySheet(childId: UUID())
}
