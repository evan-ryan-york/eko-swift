# WebRTC Setup Guide for Lyra Voice Mode

**Created:** October 12, 2025
**Updated:** October 19, 2025 (GA API Migration Complete)
**Status:** ✅ Working with GA API
**Issue:** stasel/WebRTC Swift Package has SPM dependency resolution failures

---

## Problem

The `stasel/WebRTC` Swift Package Manager dependency has known issues with:
- Clang dependency scanner failures
- Missing header files (RTCMacros.h)
- Package resolution errors

This prevents automatic installation via SPM in Xcode.

---

## Current Status

✅ **Phase 3 Implementation COMPLETE & WORKING:**
- RealtimeVoiceService fully implemented with GA API
- Ephemeral key connection flow complete and tested
- RTCPeerConnectionDelegate implemented
- RTCDataChannelDelegate with correct GA event names
- Timeout handling added
- Conditional compilation (#if canImport(WebRTC))
- **OpenAI GA API migration complete (Oct 19, 2025)**
- **Successfully connects and streams voice**

⚠️ **WebRTC Package Installation:**
- Package reference exists in project
- But fails to resolve/build
- Requires manual XCFramework installation

---

## Solution Options

### Option 1: Remove WebRTC Package & Use Manual XCFramework (Recommended)

**Step 1: Remove SPM Package Reference**

1. Open Xcode
2. Select project root in Project Navigator
3. Select "Eko" target
4. Go to "Frameworks, Libraries, and Embedded Content"
5. Remove "WebRTC" if present
6. Go to "Swift Packages" tab in project settings
7. Remove "github.com/stasel/WebRTC" package

**Step 2: Download Google WebRTC XCFramework**

```bash
# Download latest WebRTC build from Google
curl -O https://github.com/stasel/WebRTC/releases/download/141.0.0/WebRTC.xcframework.zip

# Unzip
unzip WebRTC.xcframework.zip

# Move to project
mv WebRTC.xcframework /Users/ryanyork/Software/Eko/Eko/Frameworks/
```

**Step 3: Add XCFramework to Xcode**

1. In Xcode, select project root
2. Select "Eko" target
3. Go to "General" tab
4. Under "Frameworks, Libraries, and Embedded Content", click "+"
5. Click "Add Other..." → "Add Files..."
6. Navigate to `Eko/Frameworks/WebRTC.xcframework`
7. Select "Embed & Sign"

**Step 4: Verify Build**

```bash
xcodebuild -sdk iphonesimulator -scheme Eko clean build
```

---

### Option 2: Use Alternative WebRTC Package

Try using the official Google WebRTC CocoaPods version:

```bash
# Install CocoaPods if not installed
sudo gem install cocoapods

# Create Podfile in project root
cat > Podfile <<EOF
platform :ios, '17.0'
use_frameworks!

target 'Eko' do
  pod 'GoogleWebRTC', '~> 1.1'
end
EOF

# Install pods
pod install

# From now on, open Eko.xcworkspace instead of Eko.xcodeproj
open Eko.xcworkspace
```

---

### Option 3: Build Without Voice Mode (Text Chat Only)

If voice mode isn't immediately needed, you can:

1. Remove WebRTC package reference from Xcode (see Option 1, Step 1)
2. The app will build successfully
3. Voice mode button will show error: "Voice mode requires WebRTC framework"
4. Text chat works perfectly
5. Add voice mode later when needed

---

## Current Implementation Status

The `RealtimeVoiceService.swift` is **fully implemented** with:

### ✅ Complete Features:
- Ephemeral key flow (GA API compliant)
- Direct OpenAI WebRTC connection
- SDP offer/answer negotiation
- Audio track management
- Data channel for transcription events
- Proper event handling (GA API event names):
  - `conversation.item.input_audio_transcription.completed`
  - `response.output_audio_transcript.delta` ✅ (Updated for GA)
  - `response.output_audio_transcript.done` ✅ (Updated for GA)
  - `response.done`
  - `error`
- Microphone permissions
- Audio session configuration
- Connection timeout handling
- Interrupt functionality
- Proper cleanup on session end
- Comprehensive logging for debugging

### ✅ Swift 6 Compliance:
- `@MainActor` annotation
- `@Observable` macro
- `nonisolated` delegate methods
- Proper async/await usage
- No force unwrapping

### ✅ Conditional Compilation:
```swift
#if canImport(WebRTC)
// Full implementation
#else
throw VoiceError.webRTCNotAvailable
#endif
```

This means:
- If WebRTC framework is present → Voice mode works
- If WebRTC framework is missing → Graceful error message
- App compiles either way

---

## Testing Instructions (Once WebRTC is Installed)

### Prerequisites:
1. Physical iOS device (Simulator doesn't support microphone properly)
2. OpenAI API key with Realtime API access set in Supabase secrets
3. WebRTC framework installed (via one of the options above)

### Test Flow:

**1. Build & Deploy:**
```bash
# Build for device
xcodebuild -sdk iphoneos -scheme Eko clean build

# Or use Xcode:
# Product → Destination → Your iPhone
# Product → Run
```

**2. Test Voice Session:**
- Open app on device
- Navigate to Lyra tab
- Select a child
- Tap microphone button
- **Expected:** Permission prompt (first time)
- **Expected:** Voice banner shows "Connecting..."
- **Expected:** Changes to "Voice Active" within 3 seconds
- Speak: "Hello, can you hear me?"
- **Expected:** User transcript appears
- **Expected:** AI responds with voice
- **Expected:** AI transcript appears

**3. Test Interrupt:**
- During AI response, tap interrupt button (hand icon)
- **Expected:** AI stops speaking immediately

**4. Test Session End:**
- Tap end button (X icon)
- **Expected:** Voice banner disappears
- **Expected:** Transcripts appear in text chat history

---

## Build Commands Reference

### Build for Simulator (WebRTC not required):
```bash
xcodebuild -sdk iphonesimulator -scheme Eko clean build
```

### Build for Device (WebRTC required):
```bash
xcodebuild -sdk iphoneos -scheme Eko clean build
```

### Clean Derived Data:
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/Eko-*
```

### Check Package Dependencies:
```bash
xcodebuild -resolvePackageDependencies -scheme Eko
```

---

## Troubleshooting

### Issue: "Module 'WebRTC' not found"
**Solution:** Follow Option 1 or Option 2 to manually install WebRTC framework

### Issue: "Clang dependency scanner failure"
**Solution:** This is the SPM package bug. Remove SPM reference and use manual XCFramework (Option 1)

### Issue: Voice button shows error
**Expected if WebRTC not installed.** Follow setup instructions above.

### Issue: Build succeeds but voice doesn't work
**Check:**
1. Are you testing on physical device? (Required)
2. Is microphone permission granted?
3. Is OPENAI_API_KEY set in Supabase secrets?
4. Check Xcode console for connection logs

### Issue: "Connection timeout"
**Check:**
1. Internet connection
2. OpenAI API key is valid
3. Supabase Edge Function deployed correctly
4. Check Supabase Function logs for errors

---

## File Locations

**Implementation:** `Eko/Core/Services/RealtimeVoiceService.swift` ✅
**UI Integration:** `Eko/Features/AIGuide/Views/LyraView.swift` ✅
**Voice Banner:** `Eko/Features/AIGuide/Views/VoiceBannerView.swift` ✅
**ViewModel:** `Eko/Features/AIGuide/ViewModels/LyraViewModel.swift` ✅
**Edge Function:** `supabase/functions/create-realtime-session/index.ts` ✅ (deployed)

---

## Summary

**Phase 3 Implementation:** ✅ COMPLETE
**WebRTC Installation:** ⚠️ Manual setup required (choose Option 1, 2, or 3)
**Text Chat:** ✅ Works without WebRTC
**Voice Mode:** ⏳ Ready to activate once WebRTC installed

The code is production-ready. The only remaining step is resolving the WebRTC framework installation using one of the three options above.

---

## OpenAI GA API Migration (October 19, 2025)

### Issues Discovered & Fixed:

The original implementation was using OpenAI's **beta Realtime API**. During testing, we discovered and fixed the following:

#### Edge Function Changes:
1. **Endpoint**: `/v1/realtime/sessions` → `/v1/realtime/client_secrets`
2. **Request Format**: Must wrap config in `session` object:
   ```typescript
   // Before (Beta):
   { model: 'gpt-realtime', voice: 'alloy' }

   // After (GA):
   { session: { type: 'realtime', model: 'gpt-realtime', audio: { output: { voice: 'alloy' }}}}
   ```
3. **Response Parsing**: `openaiResponse.clientSecret.value` → `openaiResponse.value`

#### iOS Changes:
1. **WebRTC SDP Endpoint**: `/v1/realtime` → `/v1/realtime/calls`
2. **HTTP Status Handling**: Accept 2xx range (OpenAI returns 201 Created, not 200)
3. **Event Names**:
   - `response.audio_transcript.delta` → `response.output_audio_transcript.delta`
   - `response.audio_transcript.done` → `response.output_audio_transcript.done`
4. **Added comprehensive logging** for debugging WebRTC connections

### Deployment:
- Edge Function deployed to Supabase ✅
- iOS implementation updated ✅
- Voice mode tested and working ✅

---

## Next Steps

### Voice Mode (Already Working):

1. ✅ **OpenAI GA API migration complete**
2. ✅ **Edge Function deployed**
3. ✅ **iOS implementation working**
4. **Ready for production use**

### Optional: Optimize WebRTC Setup

1. **Choose installation method** (Option 1 recommended)
2. **Remove SPM package reference** from Xcode
3. **Install WebRTC framework** manually (if not already done)
4. **Build & test** on physical device
5. **Deploy to TestFlight** or App Store

### To Use Text Chat Only:

1. **Remove SPM package reference** from Xcode
2. **Build & deploy** - text chat works perfectly
3. **Add voice later** when convenient

---

**Last Updated:** October 19, 2025
**Author:** Claude Code
**Status:** ✅ Voice mode working with GA API
