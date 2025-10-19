import SwiftUI
import EkoKit

// MARK: - Voice Banner View
// Simplified banner - transcripts now appear in main chat
struct VoiceBannerView: View {
    let status: RealtimeVoiceService.Status
    let onEnd: () -> Void

    var body: some View {
        HStack(spacing: .ekoSpacingMD) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(statusText)
                .font(.ekoCaption)
                .foregroundStyle(Color.ekoSecondaryLabel)

            Spacer()

            // Stop Voice Mode button
            Button(action: onEnd) {
                Text("Stop Voice Mode")
                    .font(.ekoFootnote)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, .ekoSpacingMD)
                    .padding(.vertical, .ekoSpacingSM)
                    .background(Color.ekoError)
                    .cornerRadius(.ekoRadiusMD)
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
        onEnd: {}
    )
}

#Preview("Connected") {
    VoiceBannerView(
        status: .connected,
        onEnd: {}
    )
}

#Preview("Error State") {
    VoiceBannerView(
        status: .error(VoiceError.connectionFailed),
        onEnd: {}
    )
}
