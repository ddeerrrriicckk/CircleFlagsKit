# Accessibility

Accessibility support for CircleFlagsKit.

## Overview

CircleFlagsKit provides localized accessibility labels for flags
to ensure compatibility with VoiceOver and other assistive technologies.

`CircleFlag` sets an accessibility label derived from the resolved region code.

## Naming Protocol

```swift
public protocol CircleFlagAccessibilityNaming {
    /// - Returns: localized country/region name for ISO region code, or nil if unknown.
    func localizedRegionName(forResolvedCode code: String, locale: Locale) -> String?
}
````

Implement this protocol to provide custom country or region name mappings.

## Default Implementation

```swift
public struct SystemCircleFlagAccessibilityNaming
```

### Behavior

1. Uppercases the resolved code and asks the system for a localized region name using:
   `Locale.localizedString(forRegionCode:)`
2. Applies a small alias table for common non-standard inputs (currently `uk -> GB`)
3. If no name is available, `CircleFlag` falls back to displaying the uppercased code

### Example

```swift
CircleFlag(
    code: "us",
    accessibilityLocale: Locale(identifier: "en_US")
)
```

Resulting accessibility label:

> “Flag of United States”
