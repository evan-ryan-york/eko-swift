# Google OAuth Setup Guide

This guide walks you through setting up Google OAuth authentication for Eko.

## Part 1: Configure URL Scheme in Xcode

The URL scheme allows the app to receive the OAuth callback from Supabase.

### Steps:

1. Open `Eko.xcodeproj` in Xcode
2. Select the **Eko** target
3. Go to the **Info** tab
4. Scroll down to **URL Types** section
5. Click the **+** button to add a new URL Type
6. Configure:
   - **Identifier**: `com.estuarystudios.eko`
   - **URL Schemes**: `com.estuarystudios.eko`
   - **Role**: Editor

**What this does**: Registers `com.estuarystudios.eko://` as a deep link that opens your app.

---

## Part 2: Configure Google Cloud Console

You need to create OAuth credentials in Google Cloud Console.

### Steps:

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the **Google+ API**:
   - Go to **APIs & Services** → **Library**
   - Search for "Google+ API"
   - Click **Enable**

4. Create OAuth credentials:
   - Go to **APIs & Services** → **Credentials**
   - Click **Create Credentials** → **OAuth client ID**
   - If prompted, configure the OAuth consent screen first:
     - User Type: **External**
     - App name: **Eko**
     - User support email: Your email
     - Developer contact: Your email
     - Save and Continue through the scopes and test users

5. Create iOS OAuth Client ID:
   - Application type: **iOS**
   - Name: **Eko iOS**
   - Bundle ID: `com.estuarystudios.Eko` (must match your Xcode bundle ID)
   - Click **Create**

6. **Save the Client ID** - You'll need this for Supabase

---

## Part 3: Configure Supabase

Now you need to enable Google authentication in your Supabase project.

### Steps:

1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project: **fqecsmwycvltpnqawtod**
3. Go to **Authentication** → **Providers**
4. Find **Google** and click to expand
5. Enable Google provider:
   - Toggle **Enable Sign in with Google** to ON
   - **Client ID**: Paste the iOS Client ID from Google Cloud Console
   - **Client Secret**: Leave empty for iOS (not needed)
   - Click **Save**

6. Configure Redirect URLs:
   - Go to **Authentication** → **URL Configuration**
   - Add the following **Redirect URLs**:
     - `com.estuarystudios.eko://oauth/callback`
     - `https://fqecsmwycvltpnqawtod.supabase.co/auth/v1/callback` (for web testing)
   - Click **Save**

---

## Part 4: Test the OAuth Flow

### Expected behavior:

1. User taps "Continue with Google" button
2. Safari opens with Google sign-in page
3. User signs in with Google
4. Google redirects to Supabase
5. Supabase redirects back to your app via `com.estuarystudios.eko://oauth/callback`
6. App handles the callback and signs in the user

### Testing steps:

1. Run the app in Xcode (Cmd+R)
2. Tap "Continue with Google"
3. Sign in with your Google account
4. Grant permissions when asked
5. You should be redirected back to the app and signed in

### Troubleshooting:

**Issue**: "Invalid OAuth client" error
- **Solution**: Make sure the Bundle ID in Xcode matches exactly what you entered in Google Cloud Console

**Issue**: "Redirect URI mismatch" error
- **Solution**: Verify the redirect URL is added in both Supabase URL Configuration and matches `Config.Supabase.redirectURL`

**Issue**: App doesn't open after Google sign-in
- **Solution**: Check that the URL scheme is properly configured in Xcode's Info tab

**Issue**: OAuth callback fails silently
- **Solution**: Check the Xcode console for errors. Make sure `onOpenURL` handler is in place in `EkoApp.swift`

---

## Security Notes

- The Client Secret is NOT needed for iOS native apps (only for server-side flows)
- Never commit your Google OAuth credentials to version control
- The anon key in `Config.swift` is safe to include in the app (it's designed to be public)
- Your service role key should NEVER be in the iOS app - it's for server-side use only

---

## What We Built

The authentication flow now includes:

✅ **Google OAuth sign-in** - Primary authentication method
✅ **Email/password sign-in** - Fallback option
✅ **Deep link handling** - OAuth callback from Supabase
✅ **Session management** - Automatic session restoration
✅ **Error handling** - User-friendly error messages

The UI has been updated with:
- Prominent "Continue with Google" button
- Visual divider between OAuth and email/password
- Error message display
- Loading states for all authentication actions

---

## Next Steps

After OAuth is working:

1. Test the authentication flow end-to-end
2. Add email confirmation flow (if needed)
3. Implement profile setup after first sign-in
4. Add other OAuth providers (Apple Sign In is required for App Store)
5. Set up user database tables in Supabase
