# ``CircleFlagPreloader``

Preloads flag image data into cache.

## Overview

`CircleFlagPreloader` is intended for list or grid UIs where multiple flags
will appear shortly.

It performs best-effort preloading of PNG data into the cache.

## Preload

```swift
public static func preload(
    _ codes: [String],
    maxConcurrency: Int = 10
) async
````

```swift
public static func preload(
    _ codes: Set<String>,
    maxConcurrency: Int = 10
) async
```

### Behavior

* Normalizes all input codes using `CircleFlagImage.resolvedKey(for:)`
* Preloads PNG `Data` into cache
* Respects cache limits
* Does not decode images (decode happens on first display)

### Usage

```swift
await CircleFlagPreloader.preload(["us", "gb", "ca", "en_US"])
```
