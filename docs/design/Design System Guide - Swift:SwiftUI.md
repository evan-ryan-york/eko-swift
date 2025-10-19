# Design System Guide - Swift/SwiftUI

Complete guide for using the EkoKit design system in Swift/SwiftUI applications.

## Table of Contents

- [Introduction](#introduction)
- [Getting Started](#getting-started)
- [Colors](#colors)
- [Typography](#typography)
- [Spacing](#spacing)
- [Shadows](#shadows)
- [Components](#components)
- [Best Practices](#best-practices)

## Introduction

EkoKit is a custom design system built for the Eko iOS app. It provides:
- Consistent design tokens for colors, typography, spacing, and shadows
- Reusable UI components
- SwiftUI-native implementation
- Built-in support for light/dark mode and accessibility

## Getting Started

### Import EkoKit

```swift
import SwiftUI
import EkoKit
```

### Basic Usage

All design tokens are accessible as extensions on standard SwiftUI types:
- Colors: `Color.eko*`
- Typography: `Font.eko*` or `.eko*Style()` modifiers
- Spacing: `CGFloat.ekoSpacing*`
- Shadows: `EkoShadow.*`

## Colors

### Brand Colors

```swift
Color.ekoPrimary         // Purple (primary brand color)
Color.ekoSecondary       // Light Blue (secondary brand color)
Color.ekoAccent          // Orange (accent color)
```

**Example:**
```swift
Button("Sign In") {
    // action
}
.background(Color.ekoPrimary)
```

### Semantic Colors

```swift
Color.ekoSuccess         // Green (success states)
Color.ekoWarning         // Yellow (warning states)
Color.ekoError           // Red (error states)
Color.ekoInfo            // Blue (informational states)
```

**Example:**
```swift
Text("Success!")
    .foregroundColor(.ekoSuccess)
```

### Neutral Colors

```swift
// Backgrounds
Color.ekoBackground              // Primary background
Color.ekoSecondaryBackground     // Secondary background
Color.ekoTertiaryBackground      // Tertiary background
Color.ekoSurface                 // Surface/card background

// Text
Color.ekoLabel                   // Primary text
Color.ekoSecondaryLabel          // Secondary text
Color.ekoTertiaryLabel           // Tertiary text

// Other
Color.ekoSeparator               // Dividers and borders
```

**Example:**
```swift
VStack {
    Text("Title")
        .foregroundColor(.ekoLabel)
    Text("Subtitle")
        .foregroundColor(.ekoSecondaryLabel)
}
.background(Color.ekoSurface)
```

### Adaptive Colors

All neutral colors automatically adapt to light/dark mode using system colors.

## Typography

### Font Styles

#### Display & Titles
```swift
Font.ekoDisplay          // 34pt, bold, rounded (largest)
Font.ekoTitle1           // 28pt, bold, rounded
Font.ekoTitle2           // 22pt, bold, rounded
Font.ekoTitle3           // 20pt, semibold, rounded
```

#### Body & Headline
```swift
Font.ekoHeadline         // 17pt, semibold, rounded
Font.ekoBody             // 17pt, regular, default
Font.ekoBodyEmphasized   // 17pt, semibold, default
```

#### Smaller Styles
```swift
Font.ekoSubheadline      // 15pt, regular, default
Font.ekoCallout          // 16pt, regular, default
Font.ekoFootnote         // 13pt, regular, default
Font.ekoCaption          // 12pt, regular, default
Font.ekoCaption2         // 11pt, regular, default
```

### Using Typography

**Option 1: Direct Font**
```swift
Text("Welcome!")
    .font(.ekoTitle1)
    .foregroundColor(.ekoLabel)
```

**Option 2: Style Modifiers** (includes color)
```swift
Text("Welcome!")
    .ekoTitle1Style()

Text("Description")
    .ekoBodyStyle()

Text("Subtitle")
    .ekoSubheadlineStyle()
```

### Available Style Modifiers

```swift
.ekoDisplayStyle()       // Display font + primary label color
.ekoTitle1Style()        // Title 1 font + primary label color
.ekoTitle2Style()        // Title 2 font + primary label color
.ekoTitle3Style()        // Title 3 font + primary label color
.ekoBodyStyle()          // Body font + primary label color
.ekoSubheadlineStyle()   // Subheadline font + secondary label color
```

## Spacing

### Spacing Scale

```swift
CGFloat.ekoSpacingXXS    // 4pt  - minimal spacing
CGFloat.ekoSpacingXS     // 8pt  - extra small
CGFloat.ekoSpacingSM     // 12pt - small
CGFloat.ekoSpacingMD     // 16pt - medium (default)
CGFloat.ekoSpacingLG     // 24pt - large
CGFloat.ekoSpacingXL     // 32pt - extra large
CGFloat.ekoSpacingXXL    // 48pt - double extra large
CGFloat.ekoSpacingXXXL   // 64pt - triple extra large
```

**Example:**
```swift
VStack(spacing: .ekoSpacingMD) {
    Text("Item 1")
    Text("Item 2")
}
.padding(.ekoSpacingLG)
```

### Corner Radius Scale

```swift
CGFloat.ekoRadiusXS      // 4pt
CGFloat.ekoRadiusSM      // 8pt
CGFloat.ekoRadiusMD      // 12pt (default)
CGFloat.ekoRadiusLG      // 16pt
CGFloat.ekoRadiusXL      // 24pt
CGFloat.ekoRadiusFull    // 999pt (pill shape)
```

**Example:**
```swift
Rectangle()
    .fill(Color.ekoPrimary)
    .cornerRadius(.ekoRadiusMD)
```

### Spacing Modifiers

```swift
// Standard padding (16pt on specified edges)
.ekoPadding()              // All edges
.ekoPadding(.horizontal)   // Left & right
.ekoPadding(.vertical)     // Top & bottom

// Specific padding
.ekoPaddingHorizontal()    // Same as .ekoPadding(.horizontal)
.ekoPaddingVertical()      // Same as .ekoPadding(.vertical)

// Corner radius
.ekoCornerRadius()         // 12pt radius (default)
.ekoCornerRadius(.ekoRadiusLG)  // Custom radius
```

**Example:**
```swift
Text("Hello")
    .ekoPadding()
    .background(Color.ekoPrimary)
    .ekoCornerRadius()
```

## Shadows

### Shadow Styles

```swift
EkoShadow.small          // Light shadow (radius: 4, y: 2, opacity: 0.08)
EkoShadow.medium         // Medium shadow (radius: 8, y: 4, opacity: 0.12)
EkoShadow.large          // Large shadow (radius: 16, y: 8, opacity: 0.16)
```

### Using Shadows

```swift
// Default medium shadow
Rectangle()
    .ekoShadow()

// Specific shadow
Rectangle()
    .ekoShadow(EkoShadow.large)
```

**Example:**
```swift
VStack {
    Text("Card Content")
}
.ekoPadding()
.background(Color.ekoSurface)
.ekoCornerRadius()
.ekoShadow(EkoShadow.medium)
```

## Components

### Available Components

Located in `EkoKit/Sources/EkoKit/Components/`:

#### Buttons
- `PrimaryButton` - Main call-to-action button
- `SecondaryButton` - Secondary action button

#### Forms
- `FormTextField` - Styled text input field

#### Other
- `TypingIndicatorView` - Animated typing indicator

### Using Components

```swift
import EkoKit

PrimaryButton(title: "Sign In") {
    // Handle action
}

SecondaryButton(title: "Cancel") {
    // Handle action
}

FormTextField(
    text: $username,
    placeholder: "Username"
)
```

## Best Practices

### 1. Always Use Design Tokens

❌ **Don't:**
```swift
Text("Hello")
    .font(.system(size: 17))
    .foregroundColor(Color.blue)
    .padding(16)
```

✅ **Do:**
```swift
Text("Hello")
    .font(.ekoBody)
    .foregroundColor(.ekoPrimary)
    .padding(.ekoSpacingMD)
```

### 2. Use Style Modifiers for Common Patterns

❌ **Don't:**
```swift
Text("Title")
    .font(.ekoTitle1)
    .foregroundColor(.ekoLabel)
```

✅ **Do:**
```swift
Text("Title")
    .ekoTitle1Style()
```

### 3. Prefer Semantic Colors Over Brand Colors

❌ **Don't:**
```swift
Text("Error occurred")
    .foregroundColor(.red)
```

✅ **Do:**
```swift
Text("Error occurred")
    .foregroundColor(.ekoError)
```

### 4. Use Consistent Spacing

❌ **Don't:**
```swift
VStack(spacing: 15) {  // Random value
    // content
}
```

✅ **Do:**
```swift
VStack(spacing: .ekoSpacingMD) {
    // content
}
```

### 5. Leverage Existing Components

❌ **Don't:**
```swift
Button("Submit") {
    // action
}
.padding()
.background(Color.ekoPrimary)
.foregroundColor(.white)
.cornerRadius(8)
```

✅ **Do:**
```swift
PrimaryButton(title: "Submit") {
    // action
}
```

### 6. Support Both Light and Dark Mode

✅ **Do:**
- Use neutral colors from the design system (`.ekoLabel`, `.ekoBackground`, etc.)
- Test your UI in both light and dark mode
- Avoid hardcoded color values

### 7. Maintain Visual Hierarchy

```swift
VStack(alignment: .leading, spacing: .ekoSpacingMD) {
    Text("Main Heading")
        .ekoTitle1Style()

    Text("Subheading")
        .ekoTitle3Style()

    Text("Body content goes here...")
        .ekoBodyStyle()

    Text("Additional info")
        .ekoSubheadlineStyle()
}
```

### 8. Create Reusable Components

When you find yourself repeating UI patterns, create a new component in EkoKit:

```swift
// Add to EkoKit/Sources/EkoKit/Components/
public struct CustomCard: View {
    let title: String
    let content: String

    public init(title: String, content: String) {
        self.title = title
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: .ekoSpacingMD) {
            Text(title)
                .ekoTitle2Style()
            Text(content)
                .ekoBodyStyle()
        }
        .ekoPadding()
        .background(Color.ekoSurface)
        .ekoCornerRadius()
        .ekoShadow()
    }
}
```

## Migration Checklist

When updating existing code to use EkoKit:

- [ ] Replace hardcoded colors with EkoKit colors
- [ ] Replace hardcoded fonts with EkoKit typography
- [ ] Replace hardcoded spacing with EkoKit spacing tokens
- [ ] Replace custom shadows with EkoKit shadows
- [ ] Use existing EkoKit components where applicable
- [ ] Test in both light and dark mode
- [ ] Verify accessibility with Dynamic Type

## Quick Reference

### Most Common Tokens

```swift
// Colors
.ekoPrimary, .ekoLabel, .ekoSecondaryLabel, .ekoBackground, .ekoSurface

// Typography
.ekoTitle1Style(), .ekoBodyStyle(), .ekoSubheadlineStyle()

// Spacing
.ekoSpacingMD, .ekoSpacingLG, .ekoRadiusMD

// Modifiers
.ekoPadding(), .ekoCornerRadius(), .ekoShadow()
```

## Additional Resources

- [Component Template](./Swift%20Design%20System%20Component%20Template.md)
- [Migration Guide](./Swift%20Design%20System%20Migration%20Guide%20-%20AI%20Agent%20Instructions.md)
- Source Code: `EkoKit/Sources/EkoKit/`
