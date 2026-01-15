# ``CircleFlagsKit``

A Swift package for rendering **circular country and region flags** in SwiftUI,
using SwiftPM resources and Swift 6 concurrency.

## Overview

CircleFlagsKit provides a production-ready solution for displaying circular
flag images from two-letter country or region codes such as `us` or `gb`.

The package is designed around:

- SwiftUI-first API
- Swift 6 concurrency model
- Deterministic fallback behavior
- SwiftPM Resources (PNG files)

It includes both a high-level SwiftUI view and a low-level image loading
pipeline with caching, preloading, and accessibility support.

## Topics

### Essentials
- ``CircleFlag``

### Styling
- ``CircleFlagStyle``

### Image Loading & Caching
- ``CircleFlagImage``
- ``CircleFlagCacheConfig``
- ``CircleFlagPreloader``

### Accessibility
- ``CircleFlagAccessibilityNaming``
- ``SystemCircleFlagAccessibilityNaming``

### Utilities
- ``CircleFlagImage/normalizedKey(from:)``
- ``CircleFlagImage/resolvedKey(for:)``

### Platform
- ``PlatformImage``
- ``SwiftUI/Image/init(platformImage:)``
