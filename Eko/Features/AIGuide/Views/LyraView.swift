import SwiftUI
import EkoCore
import EkoKit

// MARK: - Lyra View
struct LyraView: View {
    @State private var viewModel: LyraViewModel
    @State private var inputText = ""
    @State private var showingHistory = false

    init(childId: UUID) {
        _viewModel = State(initialValue: LyraViewModel(childId: childId))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Voice mode banner (transcripts now show in main chat)
                if viewModel.isVoiceMode {
                    VoiceBannerView(
                        status: viewModel.voiceStatus,
                        onInterrupt: { viewModel.interruptAI() },
                        onEnd: { viewModel.endVoiceMode() }
                    )
                    .transition(.move(edge: .top))
                }

                // Message list
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: .ekoSpacingMD) {
                            if viewModel.messages.isEmpty {
                                // Empty state
                                emptyStateView
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else {
                                ForEach(viewModel.messages) { message in
                                    MessageBubbleView(message: message)
                                        .id(message.id)
                                }

                                // Typing indicator
                                if viewModel.isLoading {
                                    HStack {
                                        TypingIndicatorView()
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        // Auto-scroll to latest message
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()

                // Input bar (hidden during voice mode)
                if !viewModel.isVoiceMode {
                    ChatInputBar(
                        text: $inputText,
                        isLoading: viewModel.isLoading,
                        onSend: {
                            Task {
                                let messageText = inputText
                                inputText = ""
                                do {
                                    try await viewModel.sendMessage(messageText)
                                } catch {
                                    print("Error sending message: \(error)")
                                }
                            }
                        },
                        onVoiceTap: {
                            Task {
                                await viewModel.startVoiceMode()
                            }
                        }
                    )
                }
            }
            .navigationTitle("Chat with Lyra")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingHistory = true
                        } label: {
                            Label("View History", systemImage: "clock")
                        }

                        Button {
                            Task {
                                do {
                                    try await viewModel.completeConversation()
                                } catch {
                                    print("Error completing conversation: \(error)")
                                }
                            }
                        } label: {
                            Label("Complete Conversation", systemImage: "checkmark.circle")
                        }
                        .disabled(viewModel.conversationId == nil)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingHistory) {
                ChatHistorySheet(childId: viewModel.childId)
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                }
            }
            .task {
                await viewModel.loadActiveConversation()
            }
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: .ekoSpacingLG) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.ekoPrimary.opacity(0.6))

            VStack(spacing: .ekoSpacingXS) {
                Text("Ask Lyra Anything")
                    .font(.ekoTitle2)
                    .foregroundStyle(Color.ekoLabel)

                Text("Get personalized parenting support tailored to your child")
                    .font(.ekoBody)
                    .foregroundStyle(Color.ekoSecondaryLabel)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: .ekoSpacingSM) {
                suggestionButton(
                    icon: "moon.stars.fill",
                    text: "Help with bedtime routine"
                )
                suggestionButton(
                    icon: "figure.walk",
                    text: "Managing tantrums"
                )
                suggestionButton(
                    icon: "book.fill",
                    text: "Homework struggles"
                )
            }
        }
        .padding()
    }

    private func suggestionButton(icon: String, text: String) -> some View {
        Button {
            inputText = text
        } label: {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(Color.ekoPrimary)
                Text(text)
                    .foregroundStyle(Color.ekoLabel)
                Spacer()
                Image(systemName: "arrow.right")
                    .foregroundStyle(Color.ekoTertiaryLabel)
            }
            .padding(.ekoSpacingMD)
            .background(
                RoundedRectangle(cornerRadius: .ekoRadiusMD)
                    .fill(Color.ekoSurface)
            )
        }
    }
}

// MARK: - Preview
#Preview {
    LyraView(childId: UUID())
}
