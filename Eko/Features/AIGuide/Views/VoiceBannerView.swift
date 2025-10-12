import SwiftUI
import EkoKit

// MARK: - Voice Banner View
struct VoiceBannerView: View {
    let status: RealtimeVoiceService.Status
    let userTranscript: String
    let aiTranscript: String
    let onInterrupt: () -> Void
    let onEnd: () -> Void

    var body: some View {
        VStack(spacing: .ekoSpacingSM) {
            // Status indicator
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)

                Text(statusText)
                    .font(.ekoCaption)
                    .foregroundStyle(Color.ekoSecondaryLabel)

                Spacer()

                // Controls
                Button(action: onInterrupt) {
                    Image(systemName: "hand.raised.fill")
                        .foregroundStyle(Color.ekoSecondaryLabel)
                }
                .disabled(!isConnected)
                .opacity(isConnected ? 1.0 : 0.5)

                Button(action: onEnd) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.ekoError)
                }
            }

            // Live transcripts
            if !userTranscript.isEmpty || !aiTranscript.isEmpty {
                VStack(alignment: .leading, spacing: .ekoSpacingXS) {
                    if !userTranscript.isEmpty {
                        HStack(alignment: .top) {
                            Text("You:")
                                .font(.ekoCaption)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.ekoSecondaryLabel)
                            Text(userTranscript)
                                .font(.ekoCaption)
                                .foregroundStyle(Color.ekoLabel)
                        }
                    }

                    if !aiTranscript.isEmpty {
                        HStack(alignment: .top) {
                            Text("Lyra:")
                                .font(.ekoCaption)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.ekoSecondaryLabel)
                            Text(aiTranscript)
                                .font(.ekoCaption)
                                .foregroundStyle(Color.ekoTertiaryLabel)
                        }
                    }
                }
            }
        }
        .padding(.ekoSpacingMD)
        .background(Color.ekoSurface)
        .overlay(
            Rectangle()
                .fill(statusColor)
                .frame(height: 2),
            alignment: .bottom
        )
    }

    private var statusColor: Color {
        switch status {
        case .disconnected:
            return .gray
        case .connecting:
            return .orange
        case .connected:
            return .green
        case .error:
            return .red
        }
    }

    private var statusText: String {
        switch status {
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Voice Active - Speak Naturally"
        case .error(let error):
            return "Error: \(error.localizedDescription)"
        }
    }

    private var isConnected: Bool {
        if case .connected = status {
            return true
        }
        return false
    }
}

// MARK: - Preview
#Preview("Connecting") {
    VoiceBannerView(
        status: .connecting,
        userTranscript: "",
        aiTranscript: "",
        onInterrupt: {},
        onEnd: {}
    )
}

#Preview("Connected") {
    VoiceBannerView(
        status: .connected,
        userTranscript: "",
        aiTranscript: "",
        onInterrupt: {},
        onEnd: {}
    )
}

#Preview("With Transcripts") {
    VoiceBannerView(
        status: .connected,
        userTranscript: "My child won't listen when I ask them to clean up",
        aiTranscript: "I hear you. This is a common challenge. Let's talk about how to frame requests in a way that your child is more likely to respond to...",
        onInterrupt: {},
        onEnd: {}
    )
}

#Preview("Error State") {
    VoiceBannerView(
        status: .error(VoiceError.connectionFailed),
        userTranscript: "",
        aiTranscript: "",
        onInterrupt: {},
        onEnd: {}
    )
}
