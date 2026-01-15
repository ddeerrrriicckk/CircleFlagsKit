# CircleFlagsKit – FAQ

> This document collects common questions and design rationales for CircleFlagsKit.
> Its goal is to reduce duplicate issues and help you understand the library’s behavior and constraints more quickly.

---

## Table of Contents

* Q1: Why not use `UIImage(named:)` / Asset Catalog?
* Q2: Why does the fallback use `xx.png`?
* Q3: Why does input like `"en_US"` work?
* Q4: Why cache `Data` instead of `UIImage` / `NSImage`?
* Q5: Does preload consume a lot of memory?
* Q6: What should I do if Snapshot Tests fail on CI?
* Q7: Are watchOS / tvOS supported?
* Q8: Is this library suitable for production use?

---

## Q1: Why not use `UIImage(named:)` / Asset Catalog?

**A:**

* SwiftPM `Resources` are **not** Asset Catalogs.
* `UIImage(named:)` behaves unreliably in SwiftPM bundles / `Bundle.module`,
  especially in terms of resource lookup and caching behavior.
* This library uses a more controlled loading path:

```swift
Bundle.module.url(forResource:) + UIImage(contentsOfFile:)
```

This is the most stable and testable approach:

* Resource resolution is fully managed by SwiftPM.
* Image decoding is performed by explicit, controllable code paths.

---

## Q2: Why does the fallback use `xx.png`?

**A:**

* The library defines `xx.png` as the unified fallback for “unknown / missing codes”.
* Choosing a **file-level fallback** has several advantages:

  * No dependency on external country-code tables
  * Deterministic and predictable behavior
  * Easy to test and validate in CI

As long as `xx.png` exists, `CircleFlagImage.image(for:)` should never return `nil`.

> ⚠️ If `xx.png` is missing, it is considered a configuration error.
> Only in such extreme cases may the API return `nil`.

---

## Q3: Why does input like `"en_US"` work?

**A:**

`normalizedKey(from:)` supports tolerant input and applies the following steps:

1. Remove `.png`
2. Split by `_` or `-`
3. Take the last segment (locale-like input)
4. Keep only `[a-z]`
5. Must be exactly 2 characters, otherwise return `""`

Examples:

| Input       | Result |
| ----------- | ------ |
| `en_US`     | `us`   |
| `../us.png` | `us`   |
| `usa`       | `""`   |

---

## Q4: Why cache `Data` instead of `UIImage` / `NSImage`?

**A: This is an intentional design decision:**

* `Data` is `Sendable` and can be safely cached and passed across concurrency domains.
* `UIImage` / `NSImage` are **not** `Sendable`, which introduces risks and restrictions
  under Swift 6’s concurrency model.
* Image decoding and access in UIKit/AppKit can also have edge cases when used off the main thread.

Therefore, the library adopts the following strategy:

* **Actor / background**: cache PNG `Data`
* **MainActor**: decode into `UIImage` / `NSImage` on demand

This design is more robust under Swift 6 concurrency semantics.

---

## Q5: Does preload consume a lot of memory?

**A:**

* `preload` only caches raw `Data`, not decoded image objects.
* Cache size is constrained by `CircleFlagCacheConfig.totalCostLimit`.
* `NSCache` is used, so the system can automatically evict entries under memory pressure.
* You can clear the cache at any time:

```swift
await CircleFlagImage.clearCache()
```

---

## Q6: What should I do if Snapshot Tests fail on CI?

**A:**

* CI must always enforce `record = .never` to prevent accidental baseline updates.
* If the UI change is **expected**, the correct workflow is:

1. Locally change `recordMode` to `.all`
2. Run tests to generate new snapshots
3. Commit the updated `__Snapshots__`
4. Change `recordMode` back to `.never`

It’s recommended that CI uploads `.failed` / `.diff` snapshots as artifacts
to make comparison and debugging easier.

---

## Q7: Are watchOS / tvOS supported?

**A:**

Not officially at the moment, but the codebase is designed to be extensible.

Supporting watchOS / tvOS may require:

* Extending `PlatformImage` with additional conditional compilation
* Verifying SwiftPM Resources behavior on those platforms
* Adjusting decoding and rendering logic

PRs are welcome 👍

---

## Q8: Is this library suitable for production use?

**A:**

Yes — production readiness is a core goal:

* Swift 6 concurrency safety (`Sendable` + actor isolation)
* Deterministic behavior (clear fallback contract)
* Fully testable (including Snapshot Tests)
* Resource validation scripts can be integrated into CI to prevent
  “missing or misnamed assets discovered only after release”
