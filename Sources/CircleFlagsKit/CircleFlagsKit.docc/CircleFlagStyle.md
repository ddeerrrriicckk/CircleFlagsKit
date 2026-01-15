# ``CircleFlagStyle``

Defines the visual appearance of ``CircleFlag``.

## Overview

`CircleFlagStyle` allows you to customize the background, border,
and placeholder behavior of a flag view without changing its logic.

The style is value-based and safe to use across Swift concurrency domains.

## Properties

```swift
public var background: Background
public var border: Border?
public var placeholder: Placeholder
````

## Background

```swift
public enum Background {
    case none
    case color(Color)
    case material(Material)

    public static var defaultBackground: Background
}
```

Controls the background behind the circular flag.

## Border

```swift
public struct Border {
    public var width: CGFloat
    public var color: Color

    public init(width: CGFloat = 1, color: Color = .white.opacity(0.20))
}
```

Optional circular border drawn around the flag.

## Placeholder

```swift
public enum Placeholder {
    case globe
    case monogram
    case color(Color)
    case none
}
```

Used when no image is available.

* **globe**: Displays 🌐
* **monogram**: Displays the resolved country code (e.g. `US`)
* **color**: Displays a solid color
* **none**: Displays nothing

## Default Style

```swift
public static var `default`: CircleFlagStyle
```

The default style uses a subtle background and a globe placeholder.

> Note: `default` is a computed property to avoid shared mutable state
> under Swift 6 concurrency.