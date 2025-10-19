import Foundation
import EkoCore

// MARK: - Lyra ViewModel
@MainActor
@Observable
final class LyraViewModel {
    // MARK: - Text Chat State
    var messages: [Message] = []
    var isLoading = false
    var isInitialLoading = false
    var error: Error?

    // MARK: - Voice State
    var isVoiceMode = false
    private let voiceService = RealtimeVoiceService()

    // Track active voice messages for real-time updates
    private var activeUserVoiceMessageId: UUID?
    private var activeAIVoiceMessageId: UUID?

    // Map OpenAI item IDs to message UUIDs for updating transcripts
    private var voiceItemIdToMessageId: [String: UUID] = [:]

    // Track voice session start to know which messages to save
    private var voiceSessionStartMessageCount: Int = 0

    var voiceStatus: RealtimeVoiceService.Status {
        voiceService.status
    }

    // MARK: - Conversation State
    var conversationId: UUID?
    let childId: UUID

    // MARK: - Services
    private let supabase = SupabaseService.shared
    private let moderation = ModerationService.shared

    // MARK: - Initialization
    init(childId: UUID) {
        self.childId = childId
        setupVoiceCallbacks()
    }

    private func setupVoiceCallbacks() {
        // Called when user stops speaking (before transcript arrives)
        voiceService.onUserAudioCommitted = { [weak self] itemId in
            guard let self else { return }
            Task { @MainActor in
                self.handleUserAudioCommitted(itemId: itemId)
            }
        }

        // Called when user's transcript is ready (update placeholder)
        voiceService.onUserTranscriptCompleted = { [weak self] itemId, transcript in
            guard let self else { return }
            Task { @MainActor in
                self.handleUserTranscriptCompleted(itemId: itemId, transcript: transcript)
            }
        }

        voiceService.onAITranscriptDelta = { [weak self] delta in
            guard let self else { return }
            Task { @MainActor in
                self.handleAITranscriptDelta(delta)
            }
        }

        voiceService.onAITranscriptDone = { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                self.handleAITranscriptDone()
            }
        }
    }

    // MARK: - Voice Transcript Handlers
    private func handleUserAudioCommitted(itemId: String) {
        // Create placeholder message when user stops speaking (before transcript arrives)
        let userMessage = Message(
            id: UUID(),
            conversationId: conversationId,
            role: .user,
            content: "...", // Placeholder until transcript arrives
            timestamp: Date()
        )
        messages.append(userMessage)
        voiceItemIdToMessageId[itemId] = userMessage.id
        activeUserVoiceMessageId = userMessage.id
    }

    private func handleUserTranscriptCompleted(itemId: String, transcript: String) {
        // Update placeholder message with actual transcript
        guard let messageId = voiceItemIdToMessageId[itemId],
              let index = messages.firstIndex(where: { $0.id == messageId }) else {
            print("⚠️ [ViewModel] Could not find message for item \(itemId)")
            return
        }

        messages[index].content = transcript
        voiceItemIdToMessageId.removeValue(forKey: itemId)
    }

    private func handleAITranscriptDelta(_ delta: String) {
        // Stream AI response - create or update message
        if let messageId = activeAIVoiceMessageId,
           let index = messages.firstIndex(where: { $0.id == messageId }) {
            // Update existing message
            messages[index].content += delta
        } else {
            // Create new AI message
            let aiMessage = Message(
                id: UUID(),
                conversationId: conversationId,
                role: .assistant,
                content: delta,
                timestamp: Date()
            )
            messages.append(aiMessage)
            activeAIVoiceMessageId = aiMessage.id
        }
    }

    private func handleAITranscriptDone() {
        // AI finished speaking - mark message as complete
        print("✅ [ViewModel] AI transcript complete")
        // Reset active message ID
        activeAIVoiceMessageId = nil
    }

    // MARK: - Conversation Management
    func loadActiveConversation() async {
        isInitialLoading = true
        defer { isInitialLoading = false }

        do {
            if let conversation = try await supabase.getActiveConversation(childId: childId) {
                conversationId = conversation.id
                messages = try await supabase.getMessages(conversationId: conversation.id)
            }
        } catch {
            self.error = error
            print("Error loading active conversation: \(error)")
        }
    }

    // MARK: - Text Chat
    func sendMessage(_ text: String) async throws {
        // Check for crisis content
        if moderation.checkForCrisis(text) {
            let crisisMessage = Message(
                id: UUID(),
                role: .system,
                content: moderation.getCrisisMessage(withResources: true),
                timestamp: Date()
            )
            messages.append(crisisMessage)

            // TODO: Log crisis event to backend if needed
            return
        }

        // Add user message to UI immediately
        let userMessage = Message(
            id: UUID(),
            conversationId: conversationId,
            role: .user,
            content: text,
            timestamp: Date()
        )
        messages.append(userMessage)

        // Create conversation if needed
        if conversationId == nil {
            let conversation = try await supabase.createConversation(childId: childId)
            conversationId = conversation.id
        }

        guard let conversationId else {
            throw NetworkError.unknown(NSError(domain: "No conversation ID", code: -1))
        }

        isLoading = true

        // Create placeholder for assistant response
        var assistantMessage = Message(
            id: UUID(),
            conversationId: conversationId,
            role: .assistant,
            content: "",
            timestamp: Date()
        )
        messages.append(assistantMessage)

        do {
            // Stream AI response
            let stream = try await supabase.sendMessage(
                conversationId: conversationId,
                message: text,
                childId: childId
            )

            var chunkCount = 0
            for try await chunk in stream {
                assistantMessage.content += chunk
                chunkCount += 1

                // Update UI every 5 chunks or if chunk contains newline (throttle updates)
                if chunkCount % 5 == 0 || chunk.contains("\n") {
                    if let index = messages.firstIndex(where: { $0.id == assistantMessage.id }) {
                        messages[index] = assistantMessage
                    }
                }
            }

            // Final update to ensure all content is displayed
            if let index = messages.firstIndex(where: { $0.id == assistantMessage.id }) {
                messages[index] = assistantMessage
            }

            isLoading = false
        } catch {
            isLoading = false
            self.error = error

            // Remove the empty assistant message on error
            messages.removeAll { $0.id == assistantMessage.id }
            throw error
        }
    }

    // MARK: - Voice Mode
    func startVoiceMode() async {
        do {
            isVoiceMode = true

            // Track starting message count to know which messages to save later
            voiceSessionStartMessageCount = messages.count

            // Create conversation if needed
            if conversationId == nil {
                let conversation = try await supabase.createConversation(childId: childId)
                conversationId = conversation.id
            }

            guard let conversationId else {
                throw NetworkError.unknown(NSError(domain: "No conversation ID", code: -1))
            }

            try await voiceService.startSession(
                conversationId: conversationId,
                childId: childId,
                previousMessages: messages
            )
        } catch {
            self.error = error
            isVoiceMode = false
            print("Error starting voice mode: \(error)")
        }
    }

    func endVoiceMode() async {
        voiceService.endSession()
        isVoiceMode = false

        // Save new voice messages to database
        let newMessages = Array(messages.suffix(from: voiceSessionStartMessageCount))
        if !newMessages.isEmpty {
            do {
                try await supabase.saveVoiceMessages(newMessages)
                print("✅ [ViewModel] Saved \(newMessages.count) voice messages to database")
            } catch {
                print("❌ [ViewModel] Failed to save voice messages: \(error)")
                self.error = error
            }
        }

        // Reset active voice message IDs
        activeUserVoiceMessageId = nil
        activeAIVoiceMessageId = nil
        voiceItemIdToMessageId.removeAll()
        voiceSessionStartMessageCount = 0

        print("🔚 [ViewModel] Voice mode ended")
    }

    // MARK: - Conversation Completion
    func completeConversation() async throws {
        guard let conversationId else { return }

        let result = try await supabase.completeConversation(conversationId: conversationId)

        // Reset state
        self.conversationId = nil
        self.messages = []

        print("Conversation completed with title: \(result.title)")
    }
}
