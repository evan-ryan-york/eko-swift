# Eko - Parenting Conversation App

A native iOS app built with Swift and SwiftUI that helps parents of children ages 6-16 have better conversations with their kids through AI-powered practice and guidance.

## Project Status

**Current Phase**: Initial Setup Complete
The project structure, design system, and authentication foundation are now in place.

## Next Steps

### 1. Configure Xcode Project Settings

Open `Eko.xcodeproj` in Xcode and verify/update the following settings:

**Target Settings** (select Eko target → General):
- **Minimum Deployments**: Change from iOS 26.0 to **iOS 17.0**
- **Swift Language Version**: Change to **Swift 6** (Build Settings → Swift Language Version)

### 2. Add Local Swift Packages to Xcode

The EkoCore and EkoKit packages have been created but need to be added to the Xcode project:

1. In Xcode, select the project in the navigator
2. Select the **Eko** target
3. Go to **General** → **Frameworks, Libraries, and Embedded Content**
4. Click the **+** button
5. Click **Add Other...** → **Add Package Dependency...**
6. Click **Add Local...** and navigate to:
   - `EkoCore` folder (select it and click "Add Package")
   - `EkoKit` folder (select it and click "Add Package")

### 3. Add External Dependencies via Swift Package Manager

Add the following packages to the **Eko** app target:

**File → Add Package Dependencies...**

1. **Supabase Swift SDK**
   - URL: `https://github.com/supabase/supabase-swift`
   - Version: Latest (2.x recommended)
   - Products: `Supabase`, `Auth`, `PostgREST`, `Realtime`, `Storage`

2. **LiveKit iOS SDK**
   - URL: `https://github.com/livekit/client-sdk-swift`
   - Version: Latest (2.x recommended)
   - Products: `LiveKit`

3. **RevenueCat SDK**
   - URL: `https://github.com/RevenueCat/purchases-ios`
   - Version: Latest (4.x recommended)
   - Products: `RevenueCat`

### 4. Add New Files to Xcode Target

All the Swift files have been created on disk but need to be added to the Xcode target:

1. In Xcode, right-click on the **Eko** folder in the project navigator
2. Select **Add Files to "Eko"...**
3. Navigate to the `Eko` folder and select all the new folders:
   - `Core` (with Services, Network, Extensions)
   - `Features` (with Authentication, etc.)
4. Make sure **"Add to targets: Eko"** is checked
5. Click **Add**

### 5. Configure Info.plist

The app needs microphone permissions for the conversation simulator:

1. Open `Eko/Info.plist` in Xcode
2. Add the following keys (or use the property list editor):

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Eko needs microphone access to practice conversations with the AI simulator.</string>

<key>NSSpeechRecognitionUsageDescription</key>
<string>Eko uses speech recognition to provide feedback on your conversations.</string>
```

### 6. Configure Environment Variables

Update `Eko/Core/Config.swift` with your actual API keys:

```swift
enum Supabase {
    static let url = "YOUR_ACTUAL_SUPABASE_URL"
    static let anonKey = "YOUR_ACTUAL_SUPABASE_ANON_KEY"
}
// ... etc
```

**IMPORTANT**: This file is in .gitignore to prevent committing secrets.

### 7. Set Up Supabase Backend

Start the local Supabase instance:

```bash
cd /path/to/Eko
supabase start
```

Take note of the credentials output (API URL, anon key, service_role key) and update `Config.swift`.

### 8. Build and Run

1. Select the **Eko** scheme and an iOS simulator
2. Press **Cmd+B** to build
3. Press **Cmd+R** to run
4. You should see the LoginView with the authentication UI

## Project Structure

```
Eko/
├── Eko.xcodeproj/              # Xcode project
├── Eko/                         # Main app target
│   ├── EkoApp.swift             # App entry point
│   ├── Core/                    # Shared infrastructure
│   │   ├── Services/            # SupabaseService, AudioService, LiveKitService
│   │   ├── Network/             # NetworkError definitions
│   │   ├── Extensions/          # (Empty for now)
│   │   └── Config.swift         # Environment variables (in .gitignore)
│   ├── Features/                # Feature modules
│   │   └── Authentication/      # Login/SignUp views and ViewModels
│   └── Resources/               # Assets, Info.plist
├── EkoCore/                     # Swift Package - Models & Business Logic
│   └── Sources/EkoCore/
│       ├── Models/              # User, Child models
│       └── DTOs/                # AuthDTO (request/response types)
├── EkoKit/                      # Swift Package - UI Components
│   └── Sources/EkoKit/
│       ├── Components/          # PrimaryButton, SecondaryButton, FormTextField
│       └── DesignSystem/        # Colors, Typography, Spacing, Shadows
└── supabase/                    # Backend configuration
    ├── config.toml              # Supabase config
    ├── migrations/              # SQL migrations (to be created)
    └── functions/               # Edge Functions (to be created)
```

## Technology Stack

- **Language**: Swift 6
- **UI**: SwiftUI
- **State Management**: Observation framework (@Observable)
- **Backend**: Supabase
- **Real-Time Audio**: LiveKit + OpenAI Realtime API
- **Subscriptions**: RevenueCat
- **Package Manager**: Swift Package Manager

## Development Workflow

1. **Coding**: Use Zed editor (or your preferred editor) with Claude Code
2. **Building/Running**: Use Xcode for building and running on simulator/device
3. **Backend**: Local Supabase instance running via `supabase start`

## Known Issues / TODOs

- [ ] Xcode project settings need manual adjustment (iOS version, Swift version)
- [ ] Swift Packages need to be added to Xcode project
- [ ] External dependencies (Supabase SDK, LiveKit, RevenueCat) need to be installed
- [ ] Service implementations are stubs - need actual Supabase SDK integration
- [ ] Config.swift needs real API keys
- [ ] Supabase database migrations need to be created

## Next Feature Priorities

1. Complete authentication flow end-to-end
2. Build Settings/Profile feature
3. Set up app-wide navigation
4. Audio proof of concept
5. Database schema finalization

## Notes

- This is a production app, not a prototype
- Follow modern Swift patterns: async/await, @Observable
- Keep ViewModels thin, push logic to services
- No force unwrapping in production code
- Handle all async operations with proper error states
