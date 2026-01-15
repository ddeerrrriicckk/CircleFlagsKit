# CircleFlagsKit

![workflow](https://github.com/ddeerrrriicckk/CircleFlagsKit/actions/workflows/ci.yml/badge.svg)
![Swift](https://img.shields.io/badge/Swift-6.2-orange)
![Platforms](https://img.shields.io/badge/platforms-iOS%2018%2B%20%7C%20macOS%2014%2B-blue)
![SwiftPM](https://img.shields.io/badge/SwiftPM-compatible-brightgreen)
![Concurrency](https://img.shields.io/badge/Swift%20Concurrency-safe-success)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

**CircleFlagsKit** is a Swift Package for loading **circular country / region flag views** using country codes
(e.g. `us`, `gb`).

It is designed specifically for **SwiftUI**, **Swift 6’s concurrency model**, and **SwiftPM Resources**, with a strong focus on **concurrency safety, maintainability, and testability**.

---

## ✨ Features

* ✅ Stable resource loading via SwiftPM `Resources` (`Bundle.module.url`)
* ✅ Swift 6 concurrency-safe cache (`actor` + `NSCache`)

  * Caches `Data` instead of image objects to avoid cross-concurrency-domain issues
* ✅ **In-flight deduplication**: concurrent requests for the same key trigger only one IO operation
* ✅ Automatic fallback to `xx.png` for missing or invalid country codes
* ✅ Ready-to-use SwiftUI view (`CircleFlag`)
* ✅ iOS / macOS universal (`UIImage` / `NSImage` auto-adaptation)
* ✅ Style system: background / border / placeholder (`CircleFlagStyle`)
* ✅ Preloading support (`CircleFlagPreloader`)
* ✅ Localized accessibility labels (based on `Locale`, with injectable customization)
* ✅ Snapshot tests (visual regression) and CI-friendly setup

---

## 📦 Installation

### Swift Package Manager

**Xcode (recommended)**

```
File → Add Packages… → Enter repository URL
```

**Package.swift**

```swift
dependencies: [
    .package(url: "https://github.com/xxx/CircleFlagsKit.git", from: "1.0.0")
]
```

---

## 🗂 Resource Convention (Very Important)

```
Sources/CircleFlagsKit/Resources/
├─ us.png
├─ gb.png
├─ ca.png
└─ xx.png   ← required fallback
```

**Rules:**

* File names must be **two lowercase letters**
* Extension must be `.png`
* **`xx.png` must exist** — all fallback logic depends on it

> ⚠️ If `xx.png` is missing, the API may return `nil` in extreme misconfiguration cases.

---

## 🚀 Quick Start

### SwiftUI

```swift
import SwiftUI
import CircleFlagsKit

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            CircleFlag(code: "us", size: 60)
            CircleFlag(code: "GB", size: 60)           // case-insensitive
            CircleFlag(code: "en_US", size: 60)        // locale-like input
            CircleFlag(code: "unknown", size: 60)      // → xx.png
            CircleFlag(code: nil, size: 60)            // → xx.png
        }
        .padding()
    }
}
```

---

## 🎨 Style System: `CircleFlagStyle`

You can globally control background, border, and placeholder appearance:

```swift
let style = CircleFlagStyle(
    background: .material(.ultraThin),
    border: .init(width: 2, color: .white.opacity(0.6)),
    placeholder: .monogram
)

CircleFlag(code: "__missing__", size: 64, style: style)
```

### Placeholder Types

* `.globe` – displays 🌐
* `.monogram` – displays something like `US`
* `.color(Color)` – solid color
* `.none` – no placeholder

---

## ⚡️ Preloading: `CircleFlagPreloader`

Ideal for country lists or large scrolling views.
Preloads **Data cache only**; decoding still happens on first display.

```swift
await CircleFlagPreloader.preload(
    ["us", "gb", "ca", "en_US"],
    maxConcurrency: 10
)
```

* Preheats **PNG Data cache**
* Image decoding happens on first render
* Never blocks the main thread

---

## 🧩 API Overview

### `CircleFlag` (SwiftUI View)

```swift
public struct CircleFlag: View {
    public init(
        code: String?,
        size: CGFloat = 46,
        showsFallback: Bool = true,
        style: CircleFlagStyle = .default,
        accessibilityNaming: CircleFlagAccessibilityNaming = SystemCircleFlagAccessibilityNaming(),
        accessibilityLocale: Locale = .current
    )
}
```

| Parameter             | Description                                                |
| --------------------- | ---------------------------------------------------------- |
| `code`                | Country / region code (nullable, tolerant input supported) |
| `size`                | Circle diameter                                            |
| `showsFallback`       | Whether to show a placeholder if loader returns `nil`      |
| `style`               | Background / border / placeholder style                    |
| `accessibilityNaming` | Accessibility naming provider (injectable, customizable)   |
| `accessibilityLocale` | Locale used for accessibility localization                 |

---

### `CircleFlagImage` (Low-level Loader)

#### `image(for:)`

```swift
@MainActor
public static func image(for code: String) async -> PlatformImage?
```

**Contract:**

1. If `<code>.png` exists → return that image
2. Otherwise → return `xx.png`
3. Only returns `nil` if `xx.png` is also missing

#### Cache Configuration

```swift
public struct CircleFlagCacheConfig: Sendable {
    public var countLimit: Int
    public var totalCostLimit: Int
}
```

```swift
await CircleFlagImage.configureCache(
    .init(countLimit: 300, totalCostLimit: 12 * 1024 * 1024)
)

await CircleFlagImage.clearCache()
```

---

## 🔤 Key Normalization Rules

#### `normalizedKey(from:)`

```swift
public static func normalizedKey(from raw: String) -> String
```

Rules:

1. Trim whitespace + lowercase
2. Remove `.png`
3. Handle `en_US` / `en-US` → take the last segment
4. Keep only `[a-z]`
5. **Must be exactly 2 characters**, otherwise returns `""`

Examples:

| Input     | Output |
| --------- | ------ |
| `" US "`  | `"us"` |
| `"en_US"` | `"us"` |
| `"usa"`   | `""`   |

#### `resolvedKey(for:)`

```swift
public static func resolvedKey(for code: String) -> String
```

* If `normalizedKey == ""` → `"xx"`
* Otherwise → normalized key

---

## ♿️ Accessibility Localization (A11y)

By default, accessibility names are derived using:

```swift
Locale.localizedString(forRegionCode:)
```

Examples:

* `us` → “Flag of United States”
* `gb` → “Flag of United Kingdom”
* Unknown or invalid codes → “Flag XX”

Specify a locale:

```swift
CircleFlag(
    code: "us",
    accessibilityLocale: .init(identifier: "en_US")
)
```

Or inject your own naming logic:

```swift
struct MyNaming: CircleFlagAccessibilityNaming {
    func localizedRegionName(
        forResolvedCode code: String,
        locale: Locale
    ) -> String? {
        ["us": "United States"]
            .first { $0.key == code }?.value
    }
}

CircleFlag(code: "us", accessibilityNaming: MyNaming())
```

---

## 🧠 Concurrency & Performance Design

* PNG `Data` is cached inside an `actor`-isolated `NSCache`
* `Data` is `Sendable`; image objects never cross concurrency domains
* Image decoding runs on `MainActor` (UIKit / AppKit safe)
* **In-flight deduplication**: concurrent requests for the same key share one task

---

## 🧪 Tests

Test coverage includes:

* `Bundle.module` accessibility
* Mandatory existence of `xx.png`
* Full `normalizedKey` behavior (against your resource list)
* Fallback logic
* Cache hit / fallback cache / in-flight deduplication
* Cache configuration / preload / accessibility naming

Run tests:

```
Product → Test
```

---

## 📸 Snapshot Tests (Visual Regression)

This project uses **SnapshotTesting**.

* **CI enforces `record = .never`**
* To generate snapshots locally:

  1. Change `recordMode` to `.all` in `CircleFlagsKitSnapshotTests.swift`
  2. Run tests once to generate `__Snapshots__`
  3. Commit `__Snapshots__`
  4. Revert `recordMode` to `.never`

---

# 📚 API Reference (Public Interfaces)

> This section is for **quick scanning**:
>
> * Users can immediately see what the library provides
> * Adds a professional, production-ready feel to the repository

---

## 🛡 Resource Validation Script

### `Scripts/validate_flags.py`

Features:

1. Ensures the Resources directory exists
2. Collects all `.png` files
3. Validates filenames (`^[a-z]{2}\.png$`, with optional allowed extras like `xx.png`)
4. Detects duplicates after case normalization (`US.png` vs `us.png`)
5. Optional: checks required codes from `Scripts/allowed_codes.txt` (`--allowlist`)
6. Optional: enforces existence of fallback `xx.png`

Example:

```bash
python3 Scripts/validate_flags.py \
  --resources Sources/CircleFlagsKit/Resources \
  --require-fallback xx \
  --strict-alpha2 \
  --allowlist Scripts/allowed_codes.txt
```

---

## 🧺 Project Structure

```text
CircleFlagsKit/
├─ Package.swift
├─ Docs/
│  └─ API_REFERENCE.md
├─ README.md
├─ Sources/
│  ├─ CircleFlagsKit.docc/
│  │   └─ ... (.md)
│  └─ CircleFlagsKit/
│     ├─ CircleFlag.swift
│     ├─ CircleFlagAccessibility.swift
│     ├─ CircleFlagImage.swift
│     ├─ CircleFlagPreloader.swift
│     ├─ CircleFlagStyle.swift
│     ├─ PlatformImage.swift
│     └─ Resources/
│        ├─ us.png
│        ├─ gb.png
│        ├─ ca.png
│        └─ ...
├─ Tests/
│  └─ CircleFlagsKitTests/
│     ├─ CircleFlagsKitSnapshotTests.swift
│     ├─ CircleFlagsKitTests.swift
│     └─ __Snapshots__/
│        └─ ...
└─ Scripts/
   ├─ update_flags.sh
   └─ validate_flags.py
```

---

## 📊 Version Matrix

| Version | Swift | iOS | macOS | Notes                  |
| ------- | ----- | --- | ----- | ---------------------- |
| 1.0.x   | 6.2   | 18+ | 14+   | Initial stable release |

---

## 🧾 License

This project is released under the [MIT license](LICENSE).