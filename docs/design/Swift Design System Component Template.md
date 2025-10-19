# Swift Design System Component Template

This template provides a standardized structure for creating new components in the Eko design system. All components should follow this pattern to ensure consistency, maintainability, and proper documentation.

---

## File Structure

```
DesignSystem/Components/Eko[ComponentName]/
├── Eko[ComponentName].swift           # Main component implementation
├── Eko[ComponentName]Style.swift      # Style configuration (if complex)
├── Eko[ComponentName]Preview.swift    # SwiftUI previews
└── Eko[ComponentName]Examples.swift   # Usage examples (optional)
```

---

## Component Template

### File: `Eko[ComponentName].swift`

```swift
//
//  Eko[ComponentName].swift
//  Eko Design System
//
//  Purpose: [Brief description of what this component does]
//  Material Design 3: [Which MD3 component this maps to, if applicable]
//

import SwiftUI

// MARK: - Component Configuration

/// The visual variant of the [ComponentName].
///
/// - primary: [Description of primary variant]
/// - secondary: [Description of secondary variant]
/// - tertiary: [Description of tertiary variant]
enum Eko[ComponentName]Variant {
    case primary
    case secondary
    case tertiary

    // Add more variants as needed
}

/// The size variant of the [ComponentName].
///
/// - small: [Description and use case]
/// - medium: [Description and use case - usually default]
/// - large: [Description and use case]
enum Eko[ComponentName]Size {
    case small
    case medium
    case large

    var height: CGFloat {
        switch self {
        case .small: return 32
        case .medium: return 44
        case .large: return 56
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .small: return Spacing.chipPaddingHorizontal
        case .medium: return Spacing.buttonPaddingHorizontal
        case .large: return 32
        }
    }

    // Add other size-specific properties
}

// MARK: - Main Component

/// A custom [ComponentName] component for the Eko design system.
///
/// ## Features:
/// - Material Design 3 compliant
/// - Multiple variants (primary, secondary, tertiary)
/// - Size options (small, medium, large)
/// - Full accessibility support (VoiceOver, Dynamic Type)
/// - Theme-aware colors
///
/// ## Usage Examples:
/// ```swift
/// // Basic usage
/// Eko[ComponentName]()
///
/// // With variant
/// Eko[ComponentName](variant: .secondary)
///
/// // Full configuration
/// Eko[ComponentName](
///     variant: .primary,
///     size: .large
/// )
/// ```
///
/// ## Best Practices:
/// - [When to use this component]
/// - [When NOT to use this component]
/// - [Common patterns]
///
/// ## Accessibility:
/// - Supports VoiceOver with descriptive labels
/// - Respects Dynamic Type sizing
/// - Minimum touch target: 44pt (iOS guideline)
/// - Color contrast meets WCAG AA standards
///
struct Eko[ComponentName]: View {
    // MARK: - Properties

    /// The visual style variant
    let variant: Eko[ComponentName]Variant

    /// The size variant
    let size: Eko[ComponentName]Size

    /// Optional action when tapped (if interactive)
    let action: (() -> Void)?

    /// Whether the component is disabled
    let isDisabled: Bool

    /// Accessibility label override
    let accessibilityLabel: String?

    // MARK: - Initialization

    /// Creates a new [ComponentName] with the specified configuration.
    ///
    /// - Parameters:
    ///   - variant: The visual style variant (default: `.primary`)
    ///   - size: The size variant (default: `.medium`)
    ///   - action: Optional action when tapped
    ///   - isDisabled: Whether the component is disabled (default: `false`)
    ///   - accessibilityLabel: Custom accessibility label (optional)
    init(
        variant: Eko[ComponentName]Variant = .primary,
        size: Eko[ComponentName]Size = .medium,
        action: (() -> Void)? = nil,
        isDisabled: Bool = false,
        accessibilityLabel: String? = nil
    ) {
        self.variant = variant
        self.size = size
        self.action = action
        self.isDisabled = isDisabled
        self.accessibilityLabel = accessibilityLabel
    }

    // MARK: - Body

    var body: some View {
        // If interactive (has action)
        if let action = action {
            Button(action: action) {
                content
            }
            .disabled(isDisabled)
            .accessibility(label: Text(accessibilityLabelText))
        } else {
            content
                .accessibility(label: Text(accessibilityLabelText))
        }
    }

    // MARK: - Private Views

    private var content: some View {
        // Implement your component UI here
        Text("[ComponentName] Content")
            .typography(typographyStyle, color: foregroundColor)
            .padding(.horizontal, size.horizontalPadding)
            .frame(height: size.height)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .opacity(isDisabled ? 0.5 : 1.0)
    }

    // MARK: - Computed Properties

    private var backgroundColor: Color {
        switch variant {
        case .primary:
            return AppColors.primary
        case .secondary:
            return AppColors.secondary
        case .tertiary:
            return AppColors.tertiary
        }
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary:
            return AppColors.onPrimary
        case .secondary:
            return AppColors.onSecondary
        case .tertiary:
            return AppColors.onTertiary
        }
    }

    private var borderColor: Color {
        // Add border logic if needed
        return Color.clear
    }

    private var borderWidth: CGFloat {
        // Add border width logic if needed
        return 0
    }

    private var cornerRadius: CGFloat {
        // Use semantic border radius
        return BorderRadius.button // or component-specific radius
    }

    private var typographyStyle: Typography.TextStyle {
        switch size {
        case .small:
            return Typography.labelSmall
        case .medium:
            return Typography.labelMedium
        case .large:
            return Typography.labelLarge
        }
    }

    private var accessibilityLabelText: String {
        accessibilityLabel ?? "[Component Name]"
    }
}

// MARK: - View Modifiers (Optional)

extension View {
    /// Applies [ComponentName] styling to any view.
    ///
    /// Use this modifier to style custom content with [ComponentName] appearance.
    ///
    /// - Parameters:
    ///   - variant: The visual variant
    ///   - size: The size variant
    func eko[ComponentName]Style(
        variant: Eko[ComponentName]Variant = .primary,
        size: Eko[ComponentName]Size = .medium
    ) -> some View {
        self
            .padding(.horizontal, size.horizontalPadding)
            .frame(height: size.height)
            // Add other styling
    }
}

// MARK: - Previews

#Preview("All Variants") {
    VStack(spacing: Spacing.buttonGap) {
        Eko[ComponentName](variant: .primary)
        Eko[ComponentName](variant: .secondary)
        Eko[ComponentName](variant: .tertiary)
    }
    .padding(Spacing.screenPaddingHorizontal)
}

#Preview("All Sizes") {
    VStack(spacing: Spacing.buttonGap) {
        Eko[ComponentName](size: .small)
        Eko[ComponentName](size: .medium)
        Eko[ComponentName](size: .large)
    }
    .padding(Spacing.screenPaddingHorizontal)
}

#Preview("Interactive States") {
    VStack(spacing: Spacing.buttonGap) {
        Eko[ComponentName](action: {})
        Eko[ComponentName](action: {}, isDisabled: true)
    }
    .padding(Spacing.screenPaddingHorizontal)
}

#Preview("Dark Mode") {
    VStack(spacing: Spacing.buttonGap) {
        Eko[ComponentName](variant: .primary)
        Eko[ComponentName](variant: .secondary)
    }
    .padding(Spacing.screenPaddingHorizontal)
    .preferredColorScheme(.dark)
}
```

---

## Component Checklist

When creating a new component, ensure you complete:

### 1. Planning
- [ ] Identify the component purpose and use cases
- [ ] Review Material Design 3 guidelines for equivalent component
- [ ] Determine required variants and sizes
- [ ] Identify all props/parameters needed
- [ ] Plan accessibility requirements

### 2. Implementation
- [ ] Create component file in `DesignSystem/Components/Eko[Name]/`
- [ ] Define variant enums with documentation
- [ ] Define size enums with documentation
- [ ] Implement main component struct with full documentation
- [ ] Use semantic design tokens (never hardcode values)
- [ ] Implement all variants
- [ ] Implement all sizes
- [ ] Add disabled state support
- [ ] Add accessibility labels and hints

### 3. Styling
- [ ] Use `AppColors` for all colors (never hex codes)
- [ ] Use `Spacing` for all spacing/padding
- [ ] Use `BorderRadius` for corner radius
- [ ] Use `Typography` for text styles
- [ ] Ensure minimum 44pt touch targets for interactive elements
- [ ] Support dynamic type sizing

### 4. Accessibility
- [ ] Add meaningful accessibility labels
- [ ] Add accessibility hints where needed
- [ ] Test with VoiceOver enabled
- [ ] Verify color contrast meets WCAG AA (4.5:1 for body text)
- [ ] Test with largest dynamic type size
- [ ] Test with accessibility bold text enabled

### 5. Documentation
- [ ] Add comprehensive header documentation
- [ ] Document all parameters with descriptions
- [ ] Add usage examples (minimum 3)
- [ ] Document best practices
- [ ] Document when NOT to use the component
- [ ] Add accessibility notes

### 6. Previews
- [ ] Create "All Variants" preview
- [ ] Create "All Sizes" preview
- [ ] Create "Interactive States" preview (if applicable)
- [ ] Create "Dark Mode" preview
- [ ] Create "Complex Usage" preview with real-world example

### 7. Testing
- [ ] Visual regression check against Figma designs
- [ ] Test on iPhone SE (smallest screen)
- [ ] Test on iPhone 14 Pro Max (largest screen)
- [ ] Test on iPad (if applicable)
- [ ] Test all interactive states (pressed, disabled, etc.)
- [ ] Test with VoiceOver
- [ ] Test with dynamic type at largest size

### 8. Integration
- [ ] Export component from `DesignSystem/Components/index.swift`
- [ ] Update component library documentation
- [ ] Add to design system showcase (if exists)
- [ ] Create usage examples in real screens

---

## Example: Complete Component Implementation

Here's a real example following the template - `EkoBadge.swift`:

```swift
//
//  EkoBadge.swift
//  Eko Design System
//
//  Purpose: Display notification counts or status indicators
//  Material Design 3: Maps to Badge component
//

import SwiftUI

// MARK: - Component Configuration

enum EkoBadgeVariant {
    case primary
    case secondary
    case success
    case error
    case neutral
}

enum EkoBadgeSize {
    case small
    case medium
    case large

    var dimension: CGFloat {
        switch self {
        case .small: return 16
        case .medium: return 20
        case .large: return 24
        }
    }

    var fontSize: CGFloat {
        switch self {
        case .small: return Typography.Size.xs
        case .medium: return Typography.Size.sm
        case .large: return Typography.Size.md
        }
    }
}

// MARK: - Main Component

/// A custom Badge component for the Eko design system.
///
/// ## Features:
/// - Color variants (primary, secondary, success, error, neutral)
/// - Size options (small, medium, large)
/// - Smart number formatting (99+)
/// - Dot mode for simple indicators
/// - Visibility control
///
/// ## Usage Examples:
/// ```swift
/// // Basic notification badge
/// EkoBadge(content: "3")
///
/// // Notification dot
/// EkoBadge(isDot: true)
///
/// // Large number with auto-formatting
/// EkoBadge(content: "150", maxCount: 99) // Shows "99+"
///
/// // Error indicator
/// EkoBadge(content: "!", variant: .error)
/// ```
///
/// ## Best Practices:
/// - Use dot badges for binary notifications
/// - Use number badges for countable items
/// - Keep text content short (1-3 characters)
/// - Choose colors based on urgency
///
/// ## Accessibility:
/// - Badge content announced by screen readers
/// - Use with accessible labels on parent elements
///
struct EkoBadge: View {
    // MARK: - Properties

    let content: String?
    let variant: EkoBadgeVariant
    let size: EkoBadgeSize
    let isDot: Bool
    let maxCount: Int
    let isVisible: Bool

    // MARK: - Initialization

    init(
        content: String? = nil,
        variant: EkoBadgeVariant = .primary,
        size: EkoBadgeSize = .medium,
        isDot: Bool = false,
        maxCount: Int = 99,
        isVisible: Bool = true
    ) {
        self.content = content
        self.variant = variant
        self.size = size
        self.isDot = isDot
        self.maxCount = maxCount
        self.isVisible = isVisible
    }

    // MARK: - Body

    var body: some View {
        Group {
            if isVisible {
                if isDot {
                    dotBadge
                } else {
                    contentBadge
                }
            }
        }
    }

    // MARK: - Private Views

    private var dotBadge: some View {
        Circle()
            .fill(backgroundColor)
            .frame(width: 8, height: 8)
            .accessibilityLabel("Notification indicator")
    }

    private var contentBadge: some View {
        Text(formattedContent)
            .font(.custom(Typography.Family.medium, size: size.fontSize))
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 6)
            .frame(minWidth: size.dimension, minHeight: size.dimension)
            .background(backgroundColor)
            .clipShape(Capsule())
            .accessibilityLabel("\(formattedContent) notifications")
    }

    // MARK: - Computed Properties

    private var backgroundColor: Color {
        switch variant {
        case .primary:
            return AppColors.primary
        case .secondary:
            return AppColors.secondary
        case .success:
            return Palette.Teal.shade500
        case .error:
            return AppColors.error
        case .neutral:
            return AppColors.surfaceVariant
        }
    }

    private var foregroundColor: Color {
        switch variant {
        case .neutral:
            return AppColors.onSurfaceVariant
        default:
            return Color.white
        }
    }

    private var formattedContent: String {
        guard let content = content else { return "" }

        // Try to parse as number for smart formatting
        if let number = Int(content), number > maxCount {
            return "\(maxCount)+"
        }

        return content
    }
}

// MARK: - Previews

#Preview("All Variants") {
    HStack(spacing: Spacing.buttonGap) {
        EkoBadge(content: "3", variant: .primary)
        EkoBadge(content: "5", variant: .secondary)
        EkoBadge(content: "✓", variant: .success)
        EkoBadge(content: "!", variant: .error)
        EkoBadge(content: "2", variant: .neutral)
    }
    .padding(Spacing.screenPaddingHorizontal)
}

#Preview("All Sizes") {
    HStack(spacing: Spacing.buttonGap) {
        EkoBadge(content: "3", size: .small)
        EkoBadge(content: "3", size: .medium)
        EkoBadge(content: "3", size: .large)
    }
    .padding(Spacing.screenPaddingHorizontal)
}

#Preview("Dot Badges") {
    HStack(spacing: Spacing.buttonGap) {
        EkoBadge(isDot: true, variant: .primary)
        EkoBadge(isDot: true, variant: .error)
    }
    .padding(Spacing.screenPaddingHorizontal)
}

#Preview("Number Formatting") {
    HStack(spacing: Spacing.buttonGap) {
        EkoBadge(content: "9")
        EkoBadge(content: "99")
        EkoBadge(content: "100") // Shows "99+"
        EkoBadge(content: "1000") // Shows "99+"
    }
    .padding(Spacing.screenPaddingHorizontal)
}
```

---

## Anti-Patterns to Avoid

### ❌ DON'T: Hardcode Values
```swift
// Bad
.padding(.horizontal, 16)
.background(Color(hex: "#78519F"))
.cornerRadius(12)

// Good
.padding(.horizontal, Spacing.buttonPaddingHorizontal)
.background(AppColors.primary)
.cornerRadius(BorderRadius.button)
```

### ❌ DON'T: Use Generic Variant Names
```swift
// Bad
enum ButtonType {
    case type1
    case type2
}

// Good
enum EkoButtonVariant {
    case primary   // Main call-to-action
    case secondary // Alternative action
    case subtle    // Low-emphasis action
}
```

### ❌ DON'T: Skip Accessibility
```swift
// Bad
Button(action: {}) {
    Image(systemName: "trash")
}

// Good
Button(action: {}) {
    Image(systemName: "trash")
}
.accessibilityLabel("Delete conversation")
.accessibilityHint("This action cannot be undone")
```

### ❌ DON'T: Ignore Dynamic Type
```swift
// Bad
Text("Hello")
    .font(.system(size: 16)) // Fixed size

// Good
EkoText("Hello", variant: Typography.bodyMedium) // Scales with system
```

### ❌ DON'T: Create Components Without Previews
```swift
// Bad
struct MyComponent: View {
    var body: some View {
        Text("No preview")
    }
}

// Good
struct MyComponent: View {
    var body: some View {
        Text("Has previews")
    }
}

#Preview("Default") {
    MyComponent()
}

#Preview("All States") {
    VStack {
        MyComponent()
        // ... other states
    }
}
```

---

## Common Component Patterns

### Pattern 1: Builder Pattern for Complex Configuration
```swift
struct EkoCard: View {
    private let title: String
    private let description: String?
    private let icon: String?
    private let action: (() -> Void)?

    init(title: String) {
        self.title = title
        self.description = nil
        self.icon = nil
        self.action = nil
    }

    func description(_ text: String) -> Self {
        var copy = self
        copy.description = text
        return copy
    }

    func icon(_ name: String) -> Self {
        var copy = self
        copy.icon = name
        return copy
    }

    func onTap(_ action: @escaping () -> Void) -> Self {
        var copy = self
        copy.action = action
        return copy
    }
}

// Usage:
EkoCard(title: "Practice")
    .description("Daily conversation scenarios")
    .icon("star.fill")
    .onTap { /* action */ }
```

### Pattern 2: Composition with ViewBuilder
```swift
struct EkoSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.textGap) {
            EkoText(title, variant: Typography.headlineSmall)
            content
        }
    }
}

// Usage:
EkoSection(title: "Features") {
    FeatureCard(title: "Practice")
    FeatureCard(title: "Simulate")
}
```

### Pattern 3: Style Configuration Struct
```swift
struct EkoButtonStyle {
    let backgroundColor: Color
    let foregroundColor: Color
    let borderColor: Color
    let borderWidth: CGFloat

    static let primary = EkoButtonStyle(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        borderColor: .clear,
        borderWidth: 0
    )

    static let outlined = EkoButtonStyle(
        backgroundColor: .clear,
        foregroundColor: AppColors.primary,
        borderColor: AppColors.primary,
        borderWidth: 2
    )
}
```

---

## Resources

- [Material Design 3 Components](https://m3.material.io/components)
- [SwiftUI Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/components/all-components)
- [WCAG 2.1 Color Contrast Guidelines](https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html)
- [iOS Accessibility Programming Guide](https://developer.apple.com/accessibility/ios/)

---

**Template Version**: 1.0
**Last Updated**: January 2025
