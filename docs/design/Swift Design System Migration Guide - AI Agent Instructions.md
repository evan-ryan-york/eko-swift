# Eko Design System Guide - Swift/SwiftUI

This guide provides instructions on implementing the Eko design system in Swift/SwiftUI. It maintains design parity with the React Native implementation while following SwiftUI best practices.

## Architecture Overview

The Eko Swift design system follows these principles:
- **Single Source of Truth**: All design tokens centralized in `DesignTokens.swift`
- **Semantic Naming**: Component-specific tokens over generic values
- **Material Design 3**: Aligned with MD3 color roles and typography scale
- **Reusable Components**: Modular, themeable components in the `Components/` directory
- **Type Safety**: Swift enums and structs for compile-time validation

---

## Design Tokens

### Location
`DesignSystem/Tokens/DesignTokens.swift`

### Color System

#### Palette Structure
```swift
// DesignTokens.swift
enum Palette {
    enum Teal {
        static let shade50 = Color(hex: "#F5F8F8")
        static let shade100 = Color(hex: "#E6EFEE")
        static let shade200 = Color(hex: "#C3DCDA")
        static let shade300 = Color(hex: "#81B1AD")
        static let shade400 = Color(hex: "#65958F")
        static let shade500 = Color(hex: "#4D7F7E")
        static let shade600 = Color(hex: "#3E6766")
        static let shade700 = Color(hex: "#2F4E4D")
        static let shade800 = Color(hex: "#243D3C")
        static let shade900 = Color(hex: "#1A2D2C")
        static let shade950 = Color(hex: "#0F1817")
    }

    enum Purple {
        static let shade50 = Color(hex: "#F8F5FB")
        static let shade100 = Color(hex: "#EEE6F5")
        static let shade200 = Color(hex: "#DDD0EB")
        static let shade300 = Color(hex: "#C3AEDB")
        static let shade400 = Color(hex: "#A888C5")
        static let shade500 = Color(hex: "#8D65B8")
        static let shade600 = Color(hex: "#78519F")
        static let shade700 = Color(hex: "#5E3D7D")
        static let shade800 = Color(hex: "#4C3163")
        static let shade900 = Color(hex: "#3A254B")
        static let shade950 = Color(hex: "#1E132A")
    }

    enum Pink {
        static let shade50 = Color(hex: "#FEF4F8")
        static let shade300 = Color(hex: "#F5A4C8")
        static let shade500 = Color(hex: "#E9568D")
        static let shade700 = Color(hex: "#A23860")
    }

    enum Gray {
        static let shade50 = Color(hex: "#F9FAFA")
        static let shade100 = Color(hex: "#F3F4F5")
        static let shade200 = Color(hex: "#E5E7E9")
        static let shade300 = Color(hex: "#D1D5D8")
        static let shade400 = Color(hex: "#A8AEB3")
        static let shade500 = Color(hex: "#868E94")
        static let shade600 = Color(hex: "#6B737A")
        static let shade700 = Color(hex: "#545B61")
        static let shade800 = Color(hex: "#3D4347")
        static let shade900 = Color(hex: "#2A2F32")
        static let shade950 = Color(hex: "#101010")
    }

    enum Red {
        static let shade50 = Color(hex: "#FEF2F2")
        static let shade500 = Color(hex: "#EF4444")
        static let shade700 = Color(hex: "#B91C1C")
    }
}

// Semantic Colors (MD3 Color Roles)
enum AppColors {
    // Primary
    static let primary = Palette.Purple.shade700           // #78519F
    static let onPrimary = Color.white
    static let primaryContainer = Palette.Purple.shade100
    static let onPrimaryContainer = Palette.Purple.shade900

    // Secondary
    static let secondary = Palette.Teal.shade300           // #81B1AD
    static let onSecondary = Color.white
    static let secondaryContainer = Palette.Teal.shade100
    static let onSecondaryContainer = Palette.Teal.shade900

    // Tertiary (Accent)
    static let tertiary = Palette.Pink.shade500
    static let onTertiary = Color.white
    static let tertiaryContainer = Palette.Pink.shade50
    static let onTertiaryContainer = Palette.Pink.shade700

    // Error
    static let error = Palette.Red.shade500
    static let onError = Color.white
    static let errorContainer = Palette.Red.shade50
    static let onErrorContainer = Palette.Red.shade700

    // Background & Surface
    static let background = Color.white
    static let onBackground = Palette.Gray.shade950
    static let surface = Color.white
    static let onSurface = Palette.Gray.shade950
    static let surfaceVariant = Palette.Gray.shade50
    static let onSurfaceVariant = Palette.Gray.shade700

    // Outline
    static let outline = Palette.Gray.shade300
    static let outlineVariant = Palette.Gray.shade200

    // Inverse
    static let inverseSurface = Palette.Gray.shade900
    static let inverseOnSurface = Palette.Gray.shade100
    static let inversePrimary = Palette.Purple.shade300

    // Special
    static let shadow = Color.black.opacity(0.1)
    static let scrim = Color.black.opacity(0.4)
}
```

#### Color Extension Helper
```swift
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (no alpha)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
```

---

### Typography

#### Font Configuration
```swift
// DesignTokens.swift
enum Typography {
    // Font Family
    enum Family {
        static let regular = "Urbanist-Regular"
        static let medium = "Urbanist-Medium"
        static let semiBold = "Urbanist-SemiBold"
        static let bold = "Urbanist-Bold"
        static let extraBold = "Urbanist-ExtraBold"
    }

    // Font Sizes
    enum Size {
        static let xs: CGFloat = 10
        static let sm: CGFloat = 12
        static let md: CGFloat = 14
        static let lg: CGFloat = 16
        static let xl: CGFloat = 18
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
        static let display: CGFloat = 40
    }

    // Material Design 3 Typography Scale
    struct TextStyle {
        let font: String
        let size: CGFloat
        let lineHeight: CGFloat
        let letterSpacing: CGFloat

        var swiftUIFont: Font {
            return Font.custom(font, size: size)
        }
    }

    // Display
    static let displayLarge = TextStyle(
        font: Family.bold,
        size: 40,
        lineHeight: 45,
        letterSpacing: 0
    )
    static let displayMedium = TextStyle(
        font: Family.bold,
        size: 28,
        lineHeight: 31,
        letterSpacing: 0
    )
    static let displaySmall = TextStyle(
        font: Family.bold,
        size: 24,
        lineHeight: 27,
        letterSpacing: 0
    )

    // Headline
    static let headlineLarge = TextStyle(
        font: Family.semiBold,
        size: 24,
        lineHeight: 30,
        letterSpacing: 0
    )
    static let headlineMedium = TextStyle(
        font: Family.semiBold,
        size: 20,
        lineHeight: 25,
        letterSpacing: 0
    )
    static let headlineSmall = TextStyle(
        font: Family.semiBold,
        size: 18,
        lineHeight: 23,
        letterSpacing: 0
    )

    // Body
    static let bodyLarge = TextStyle(
        font: Family.regular,
        size: 18,
        lineHeight: 27,
        letterSpacing: 0
    )
    static let bodyMedium = TextStyle(
        font: Family.regular,
        size: 16,
        lineHeight: 24,
        letterSpacing: 0
    )
    static let bodySmall = TextStyle(
        font: Family.regular,
        size: 14,
        lineHeight: 21,
        letterSpacing: 0
    )

    // Label
    static let labelLarge = TextStyle(
        font: Family.medium,
        size: 16,
        lineHeight: 23,
        letterSpacing: 0
    )
    static let labelMedium = TextStyle(
        font: Family.medium,
        size: 14,
        lineHeight: 20,
        letterSpacing: 0
    )
    static let labelSmall = TextStyle(
        font: Family.medium,
        size: 12,
        lineHeight: 17,
        letterSpacing: 0
    )
}
```

#### Typography View Modifier
```swift
extension View {
    func typography(_ style: Typography.TextStyle, color: Color = AppColors.onSurface) -> some View {
        self
            .font(style.swiftUIFont)
            .lineSpacing(style.lineHeight - style.size)
            .foregroundColor(color)
    }
}

// Usage:
Text("Hero Title")
    .typography(Typography.displayLarge)

Text("Section Title")
    .typography(Typography.headlineMedium, color: AppColors.primary)
```

---

### Spacing

#### Semantic Spacing Tokens
```swift
// DesignTokens.swift
enum Spacing {
    // Base scale (4px grid)
    private enum Base {
        static let zero: CGFloat = 0
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
        static let huge: CGFloat = 40
        static let massive: CGFloat = 48
    }

    // Screen Layout
    static let screenPaddingHorizontal: CGFloat = Base.lg      // 16px
    static let screenPaddingVertical: CGFloat = Base.xxl       // 24px
    static let sectionGap: CGFloat = Base.xxxl                 // 32px

    // Component Spacing
    static let buttonPaddingVertical: CGFloat = Base.md        // 12px
    static let buttonPaddingHorizontal: CGFloat = Base.xxl     // 24px
    static let buttonGap: CGFloat = Base.md                    // 12px

    static let cardPadding: CGFloat = Base.lg                  // 16px
    static let cardGap: CGFloat = Base.lg                      // 16px

    static let inputPaddingVertical: CGFloat = Base.md         // 12px
    static let inputPaddingHorizontal: CGFloat = Base.lg       // 16px

    static let chipPaddingVertical: CGFloat = Base.sm          // 8px
    static let chipPaddingHorizontal: CGFloat = Base.md        // 12px

    // Content Spacing
    static let textGapTight: CGFloat = Base.xs                 // 4px
    static let textGap: CGFloat = Base.sm                      // 8px
    static let textGapLoose: CGFloat = Base.md                 // 12px
    static let iconTextGap: CGFloat = Base.sm                  // 8px
    static let listItemGap: CGFloat = Base.md                  // 12px
    static let listItemPadding: CGFloat = Base.lg              // 16px

    // Touch Targets
    static let minTouchTarget: CGFloat = 44                    // iOS guideline
}
```

---

### Border Radius

```swift
enum BorderRadius {
    // Scale values
    static let none: CGFloat = 0
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let full: CGFloat = 9999

    // Component-specific (semantic)
    static let button: CGFloat = 24
    static let card: CGFloat = 16
    static let input: CGFloat = 12
    static let chip: CGFloat = 20
    static let dialog: CGFloat = 24
    static let avatar: CGFloat = 9999
}
```

---

## Components

### Typography Component

**Location:** `DesignSystem/Components/EkoText.swift`

```swift
import SwiftUI

struct EkoText: View {
    let text: String
    let variant: Typography.TextStyle
    let color: Color

    init(
        _ text: String,
        variant: Typography.TextStyle = Typography.bodyMedium,
        color: Color = AppColors.onSurface
    ) {
        self.text = text
        self.variant = variant
        self.color = color
    }

    var body: some View {
        Text(text)
            .typography(variant, color: color)
    }
}

// Usage Examples:
struct TypographyExamples: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.textGap) {
            // Display
            EkoText("Hero Title", variant: Typography.displayLarge)

            // Headline
            EkoText("Section Title", variant: Typography.headlineMedium)

            // Body
            EkoText("This is body text. It's the default style for paragraphs.",
                   variant: Typography.bodyMedium)

            // Colored text
            EkoText("A Heading with Brand Color",
                   variant: Typography.headlineSmall,
                   color: AppColors.primary)

            // Custom color
            EkoText("Custom Colored Label",
                   variant: Typography.labelMedium,
                   color: Palette.Purple.shade500)
        }
        .padding(Spacing.screenPaddingHorizontal)
    }
}
```

---

### Button Component

**Location:** `DesignSystem/Components/EkoButton.swift`

```swift
import SwiftUI

enum EkoButtonVariant {
    case primary
    case secondary
    case subtle
}

enum EkoButtonSize {
    case small
    case medium
    case large

    var verticalPadding: CGFloat {
        switch self {
        case .small: return 8
        case .medium: return Spacing.buttonPaddingVertical
        case .large: return 16
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .small: return 16
        case .medium: return Spacing.buttonPaddingHorizontal
        case .large: return 32
        }
    }

    var fontSize: CGFloat {
        switch self {
        case .small: return Typography.Size.md
        case .medium: return Typography.Size.lg
        case .large: return Typography.Size.xl
        }
    }
}

struct EkoButton: View {
    let title: String
    let action: () -> Void
    var variant: EkoButtonVariant = .primary
    var size: EkoButtonSize = .medium
    var isError: Bool = false
    var isOutline: Bool = false
    var fullWidth: Bool = false
    var isDisabled: Bool = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom(Typography.Family.semiBold, size: size.fontSize))
                .foregroundColor(textColor)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .padding(.vertical, size.verticalPadding)
                .padding(.horizontal, size.horizontalPadding)
                .background(backgroundColor)
                .cornerRadius(BorderRadius.button)
                .overlay(
                    RoundedRectangle(cornerRadius: BorderRadius.button)
                        .stroke(borderColor, lineWidth: isOutline ? 2 : 0)
                )
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
    }

    private var backgroundColor: Color {
        if isOutline {
            return Color.clear
        }

        if isError {
            return AppColors.error
        }

        switch variant {
        case .primary:
            return AppColors.primary
        case .secondary:
            return AppColors.secondary
        case .subtle:
            return AppColors.surfaceVariant
        }
    }

    private var textColor: Color {
        if isOutline {
            return isError ? AppColors.error : variantColor
        }

        switch variant {
        case .primary, .secondary:
            return Color.white
        case .subtle:
            return AppColors.onSurface
        }
    }

    private var variantColor: Color {
        switch variant {
        case .primary:
            return AppColors.primary
        case .secondary:
            return AppColors.secondary
        case .subtle:
            return AppColors.onSurfaceVariant
        }
    }

    private var borderColor: Color {
        if isError {
            return AppColors.error
        }
        return variantColor
    }
}

// Usage Examples:
struct ButtonExamples: View {
    var body: some View {
        VStack(spacing: Spacing.buttonGap) {
            // Primary Button
            EkoButton(title: "Start Practice", action: {})

            // Secondary Button
            EkoButton(title: "Continue",
                     action: {},
                     variant: .secondary,
                     fullWidth: true)

            // Subtle Button
            EkoButton(title: "Maybe Later",
                     action: {},
                     variant: .subtle)

            // Outlined Button
            EkoButton(title: "Read More",
                     action: {},
                     isOutline: true)

            // Error Button
            EkoButton(title: "Delete",
                     action: {},
                     isError: true)

            // Outlined Error Button
            EkoButton(title: "Cancel Deletion",
                     action: {},
                     isError: true,
                     isOutline: true)

            // Sizing
            EkoButton(title: "Go Back",
                     action: {},
                     variant: .secondary,
                     size: .large,
                     isOutline: true)

            EkoButton(title: "Confirm",
                     action: {},
                     size: .small)
        }
        .padding(Spacing.screenPaddingHorizontal)
    }
}
```

---

## Implementation Checklist

When implementing the Eko design system in Swift, follow this checklist:

### Phase 1: Setup Design Tokens
- [ ] Create `DesignSystem/Tokens/DesignTokens.swift`
- [ ] Implement `Palette` enum with all color shades (teal, purple, pink, gray, red)
- [ ] Implement `AppColors` enum with MD3 semantic colors (40+ roles)
- [ ] Implement `Typography` enum with font families, sizes, and MD3 text styles
- [ ] Implement `Spacing` enum with semantic spacing tokens
- [ ] Implement `BorderRadius` enum with scale and component-specific values
- [ ] Add `Color(hex:)` extension helper
- [ ] Add `.typography()` view modifier

### Phase 2: Load Custom Fonts
- [ ] Add Urbanist font files to project (Regular, Medium, SemiBold, Bold, ExtraBold)
- [ ] Register fonts in `Info.plist`:
```xml
<key>UIAppFonts</key>
<array>
    <string>Urbanist-Regular.ttf</string>
    <string>Urbanist-Medium.ttf</string>
    <string>Urbanist-SemiBold.ttf</string>
    <string>Urbanist-Bold.ttf</string>
    <string>Urbanist-ExtraBold.ttf</string>
</array>
```
- [ ] Verify fonts load correctly with preview

### Phase 3: Create Core Components
- [ ] Implement `EkoText` component
- [ ] Implement `EkoButton` component with all variants
- [ ] Create `DesignSystem/Components/` directory structure
- [ ] Add SwiftUI previews for each component
- [ ] Test components with all size/variant combinations

### Phase 4: Create Design Guide Documentation
- [ ] Document all design tokens with usage examples
- [ ] Document all components with API reference
- [ ] Create migration guide from UIKit (if applicable)
- [ ] Add accessibility guidelines for each component

### Phase 5: Testing & Validation
- [ ] Visual regression testing (compare to React Native designs)
- [ ] Test on iPhone SE (small screen) and iPhone 14 Pro Max (large screen)
- [ ] Verify accessibility (VoiceOver support)
- [ ] Verify dynamic type scaling
- [ ] Test dark mode appearance (if implemented)

---

## SwiftUI Best Practices for Eko

### 1. Prefer View Modifiers Over Wrapper Views
```swift
// ✅ Good: Reusable view modifier
extension View {
    func ekoCardStyle() -> some View {
        self
            .padding(Spacing.cardPadding)
            .background(AppColors.surface)
            .cornerRadius(BorderRadius.card)
            .shadow(color: AppColors.shadow, radius: 4, x: 0, y: 2)
    }
}

// Usage:
VStack {
    Text("Card content")
}
.ekoCardStyle()
```

### 2. Use Environment for Theme Access
```swift
// Create environment key for theme
private struct ThemeKey: EnvironmentKey {
    static let defaultValue = EkoTheme()
}

extension EnvironmentValues {
    var ekoTheme: EkoTheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// Usage in views:
struct MyView: View {
    @Environment(\.ekoTheme) var theme

    var body: some View {
        Text("Hello")
            .foregroundColor(theme.colors.primary)
    }
}
```

### 3. Leverage ViewBuilder for Flexible APIs
```swift
struct EkoCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .ekoCardStyle()
    }
}

// Usage:
EkoCard {
    VStack {
        EkoText("Title", variant: Typography.headlineSmall)
        EkoText("Description", variant: Typography.bodyMedium)
    }
}
```

### 4. Create Semantic Spacing with VStack/HStack
```swift
// Create custom stacks with consistent spacing
struct EkoVStack<Content: View>: View {
    let spacing: CGFloat
    let content: Content

    init(spacing: CGFloat = Spacing.textGap, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        VStack(spacing: spacing) {
            content
        }
    }
}

// Usage:
EkoVStack(spacing: Spacing.sectionGap) {
    Text("Section 1")
    Text("Section 2")
}
```

---

## Migration from React Native Concepts

| React Native Paper | Swift/SwiftUI Equivalent |
|--------------------|--------------------------|
| `<PaperProvider theme={paperTheme}>` | `@Environment(\.ekoTheme)` or app-level theme |
| `useTheme()` hook | `@Environment(\.ekoTheme)` property wrapper |
| `<Text variant="headlineMedium">` | `EkoText("...", variant: Typography.headlineMedium)` |
| `<Button mode="contained">` | `EkoButton(title: "...", variant: .primary)` |
| `StyleSheet.create({ ... })` | View modifiers (`.padding()`, `.background()`, etc.) |
| `SPACING.buttonPaddingVertical` | `Spacing.buttonPaddingVertical` |
| `COLORS.primary` | `AppColors.primary` |
| `BORDER_RADIUS.button` | `BorderRadius.button` |

---

## Example: Screen Layout

```swift
struct ExampleScreen: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.sectionGap) {
                // Hero section
                VStack(spacing: Spacing.textGap) {
                    EkoText("Welcome to Eko",
                           variant: Typography.displayMedium,
                           color: AppColors.primary)

                    EkoText("Build better communication with your child",
                           variant: Typography.bodyLarge,
                           color: AppColors.onSurfaceVariant)
                }

                // Card section
                VStack(spacing: Spacing.cardGap) {
                    featureCard(
                        title: "Daily Practice",
                        description: "Improve your skills with guided scenarios"
                    )

                    featureCard(
                        title: "AI Simulator",
                        description: "Practice conversations in a safe environment"
                    )
                }

                // CTA section
                VStack(spacing: Spacing.buttonGap) {
                    EkoButton(
                        title: "Start Practice",
                        action: {},
                        fullWidth: true
                    )

                    EkoButton(
                        title: "Maybe Later",
                        action: {},
                        variant: .subtle,
                        fullWidth: true
                    )
                }
            }
            .padding(.horizontal, Spacing.screenPaddingHorizontal)
            .padding(.vertical, Spacing.screenPaddingVertical)
        }
        .background(AppColors.background)
    }

    private func featureCard(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.textGap) {
            EkoText(title,
                   variant: Typography.headlineSmall,
                   color: AppColors.primary)

            EkoText(description,
                   variant: Typography.bodyMedium,
                   color: AppColors.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ekoCardStyle()
    }
}

// Preview
#Preview {
    ExampleScreen()
}
```

---

## Design System Architecture

```
DesignSystem/
├── Tokens/
│   └── DesignTokens.swift          # Colors, Typography, Spacing, BorderRadius
├── Components/
│   ├── EkoText.swift               # Typography component
│   ├── EkoButton.swift             # Button component
│   ├── EkoTextField.swift          # Text input (future)
│   ├── EkoBadge.swift              # Badge component (future)
│   └── ...                         # Other components
├── Modifiers/
│   ├── CardModifier.swift          # .ekoCardStyle()
│   ├── TypographyModifier.swift    # .typography()
│   └── ...                         # Other modifiers
└── Preview/
    └── DesignSystemPreview.swift   # Showcase all components
```

---

## Guidelines

### 1. **Always Use Semantic Tokens**
```swift
// ✅ Correct
.padding(.horizontal, Spacing.screenPaddingHorizontal)

// ❌ Incorrect
.padding(.horizontal, 16)
```

### 2. **Always Use AppColors for Semantic Roles**
```swift
// ✅ Correct
.foregroundColor(AppColors.primary)

// ❌ Incorrect
.foregroundColor(Color(hex: "#78519F"))
```

### 3. **Prefer EkoText Over Text**
```swift
// ✅ Correct
EkoText("Title", variant: Typography.headlineMedium)

// ❌ Incorrect
Text("Title")
    .font(.custom("Urbanist-SemiBold", size: 20))
```

### 4. **Use Consistent Border Radius**
```swift
// ✅ Correct
.cornerRadius(BorderRadius.button)

// ❌ Incorrect
.cornerRadius(24)
```

### 5. **Follow 4px Grid System**
All spacing values must be multiples of 4 (except minimum touch target of 44px).

---

## Accessibility Requirements

### 1. **Dynamic Type Support**
All text components must support Dynamic Type:
```swift
EkoText("Scales with system font size", variant: Typography.bodyMedium)
    .dynamicTypeSize(...EnvironmentValues.dynamicTypeSize)
```

### 2. **Minimum Touch Targets**
All interactive elements must meet the 44pt minimum:
```swift
EkoButton(title: "Tap Me", action: {})
    .frame(minHeight: Spacing.minTouchTarget)
```

### 3. **VoiceOver Labels**
All interactive elements must have descriptive labels:
```swift
EkoButton(title: "Delete", action: {}, isError: true)
    .accessibilityLabel("Delete conversation")
    .accessibilityHint("This action cannot be undone")
```

### 4. **Color Contrast**
All text must meet WCAG AA standards (4.5:1 for body text, 3:1 for large text).

---

## Future Enhancements

1. **Dark Mode Support**: Create `AppColorsDark` enum with dark theme colors
2. **Component Library Expansion**: Add Card, TextField, Badge, Chip, Dialog, etc.
3. **Animation Tokens**: Define standard durations and curves
4. **Elevation/Shadow System**: Create semantic shadow styles
5. **Grid/Layout System**: Define responsive breakpoints
6. **SF Symbols Integration**: Map common icons to SF Symbols

---

**Document Version**: 1.0
**Last Updated**: January 2025
**Maintained By**: Eko Design Team
