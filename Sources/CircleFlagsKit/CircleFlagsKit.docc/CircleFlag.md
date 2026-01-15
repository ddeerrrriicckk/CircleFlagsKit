# ``CircleFlag``

A SwiftUI view that renders a circular flag image.

## Overview

`CircleFlag` resolves a country or region code into a PNG image bundled in the
package resources and renders it clipped to a circle.

Invalid, missing, or unknown codes automatically fall back to `xx.png`
when available.

The view is designed to be:

- Lightweight
- Deterministic
- Safe under Swift 6 concurrency rules

## Usage

```swift
CircleFlag(code: "us", size: 60)
````

The input `code` is tolerant and may include:

* Uppercase values (`"US"`)
* Locale-style identifiers (`"en_US"`, `"zh-Hant-HK"`)
* Whitespace
* File-like values (`"us.png"`)
* Values with non-letter separators (`"u s"`)

## Initializer

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

## Parameters

* **code**
  A country or region code. May be `nil`.
  The value is normalized internally using
  `CircleFlagImage/normalizedKey(from:)` and resolved via
  `CircleFlagImage/resolvedKey(for:)`.

* **size**
  Diameter of the circular flag in points.

* **showsFallback**
  Whether a placeholder should be shown if image loading returns `nil`
  (normally only possible when `xx.png` is missing).

* **style**
  Visual style configuration such as background, border, and placeholder.

* **accessibilityNaming**
  Provider for accessibility region names.

* **accessibilityLocale**
  Locale used for accessibility localization.

## Styling

`CircleFlag` uses `CircleFlagStyle` to determine:

* Background (none, color, or material)
* Optional border
* Placeholder (globe, monogram, color, or none)

## Accessibility

By default, `CircleFlag` exposes an accessibility label such as:

> “Flag of United States”

This is derived from the resolved country code and the `accessibilityLocale`.
