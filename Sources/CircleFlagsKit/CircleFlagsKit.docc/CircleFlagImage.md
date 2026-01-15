# ``CircleFlagImage``

Low-level image loading and caching utilities.

## Overview

`CircleFlagImage` handles:

- Resource lookup in SwiftPM bundles
- PNG data loading
- Cache management
- Deterministic fallback behavior

It is primarily used internally by ``CircleFlag``.

## Load Image

```swift
@MainActor
public static func image(for code: String) async -> PlatformImage?
````

```swift
@MainActor
public static func uiImage(for code: String) async -> PlatformImage?
```

`uiImage(for:)` is a convenience alias that currently calls `image(for:)`
and returns `PlatformImage` (UIImage on iOS, NSImage on macOS).

### Contract

1. If `<code>.png` exists → return that image
2. Otherwise → return `xx.png`
3. Only returns `nil` if `xx.png` is missing (configuration error)

## Cache Configuration

```swift
public static func configureCache(_ config: CircleFlagCacheConfig) async
public static func clearCache() async
```

The cache stores PNG `Data` inside an actor-isolated `NSCache`
and decodes images on the main actor.

## Key Normalization

* `CircleFlagImage/normalizedKey(from:)`
* `CircleFlagImage/resolvedKey(for:)`

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
