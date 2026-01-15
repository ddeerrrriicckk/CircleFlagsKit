# 📘 API Reference

## `Docs/API_REFERENCE.md`

# CircleFlagsKit – API Reference

This document lists all **public APIs** of CircleFlagsKit 1.0.x.

---

## Table of Contents

- CircleFlag (SwiftUI View)
- CircleFlagStyle
- CircleFlagImage
- CircleFlagCacheConfig
- CircleFlagPreloader
- Accessibility
- Key Normalization Utilities
- PlatformImage + SwiftUI Image Convenience

---

## CircleFlag

SwiftUI view that renders a circular flag image from a country / region code.

```swift
public struct CircleFlag: View
````

### Initializer

```swift
public init(
    code: String?,
    size: CGFloat = 46,
    showsFallback: Bool = true,
    style: CircleFlagStyle = .default,
    accessibilityNaming: CircleFlagAccessibilityNaming = SystemCircleFlagAccessibilityNaming(),
    accessibilityLocale: Locale = .current
)
```

### Parameters

| Name                  | Description                                                                                         |
| --------------------- | --------------------------------------------------------------------------------------------------- |
| `code`                | Country / region code. Supports tolerant input (see Key Normalization). May be `nil`.               |
| `size`                | Diameter of the circular flag (points).                                                             |
| `showsFallback`       | Whether to show placeholder if image loading returns `nil` (usually only when `xx.png` is missing). |
| `style`               | Visual style (background, border, placeholder).                                                     |
| `accessibilityNaming` | Accessibility naming provider.                                                                      |
| `accessibilityLocale` | Locale used for accessibility localization.                                                         |

---

## CircleFlagStyle

Defines the visual appearance of `CircleFlag`.

```swift
public struct CircleFlagStyle
```

### Properties

```swift
public var background: Background
public var border: Border?
public var placeholder: Placeholder
```

### Background

```swift
public enum Background {
    case none
    case color(Color)
    case material(Material)

    public static var defaultBackground: Background
}
```

### Border

```swift
public struct Border {
    public var width: CGFloat
    public var color: Color

    public init(width: CGFloat = 1, color: Color = .white.opacity(0.20))
}
```

### Placeholder

```swift
public enum Placeholder {
    case globe        // 🌐
    case monogram     // "US"
    case color(Color)
    case none
}
```

### Default Style

```swift
public static var `default`: CircleFlagStyle
```

> Note: `default` is a computed property (not a shared instance) to satisfy Swift 6 concurrency rules.

---

## CircleFlagImage

Low-level image loading and caching API.

```swift
public enum CircleFlagImage
```

### Load Image

```swift
@MainActor
public static func image(for code: String) async -> PlatformImage?
```

```swift
@MainActor
public static func uiImage(for code: String) async -> PlatformImage?
```

#### Contract

1. If `<code>.png` exists → return it
2. Else → return `xx.png`
3. Only returns `nil` if `xx.png` is missing (configuration error)

### Cache Configuration

```swift
public static func configureCache(_ config: CircleFlagCacheConfig) async
public static func clearCache() async
```

### Key Helpers

```swift
public static func normalizedKey(from raw: String) -> String
public static func resolvedKey(for code: String) -> String
```

---

## CircleFlagCacheConfig

Cache configuration for in-memory PNG `Data`.

```swift
public struct CircleFlagCacheConfig: Sendable {
    public var countLimit: Int
    public var totalCostLimit: Int

    public static let `default`: CircleFlagCacheConfig
}
```

---

## CircleFlagPreloader

Preloads flag data into cache.

```swift
public enum CircleFlagPreloader
```

### Preload

```swift
public static func preload(
    _ codes: [String],
    maxConcurrency: Int = 10
) async
```

```swift
public static func preload(
    _ codes: Set<String>,
    maxConcurrency: Int = 10
) async
```

* Preloads **PNG Data**, not decoded images
* Decode happens on first display
* Best used for lists or bulk UI

---

## Accessibility

### Protocol

```swift
public protocol CircleFlagAccessibilityNaming {
    func localizedRegionName(forResolvedCode code: String, locale: Locale) -> String?
}
```

### Default Implementation

```swift
public struct SystemCircleFlagAccessibilityNaming: CircleFlagAccessibilityNaming
```

* Uses `Locale.localizedString(forRegionCode:)`
* Includes a small alias table for common non-standard inputs (currently `uk -> GB`)
* Example output: `"Flag of United States"`

---

## Key Normalization Utilities

### normalizedKey(from:)

```swift
public static func normalizedKey(from raw: String) -> String
```

Rules:

1. Trim whitespace, lowercase
2. Remove `.png`
3. Split on `_` / `-`, take last segment
4. Keep only `[a-z]`
5. Must be exactly 2 characters, otherwise returns `""`

### resolvedKey(for:)

```swift
public static func resolvedKey(for code: String) -> String
```

* Empty normalized key → `"xx"`
* Otherwise → normalized key

---

## PlatformImage + SwiftUI Image Convenience

```swift
public typealias PlatformImage = UIImage // iOS
public typealias PlatformImage = NSImage // macOS
```

```swift
public extension Image {
    init(platformImage: PlatformImage)
}
```
