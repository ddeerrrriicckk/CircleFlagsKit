//
//  CircleFlagImage.swift
//  CircleFlagsKit
//

import Foundation

#if canImport(UIKit)
@preconcurrency import UIKit
#elseif canImport(AppKit)
@preconcurrency import AppKit
#endif

// MARK: - Cache config

public struct CircleFlagCacheConfig: Sendable {
    public var countLimit: Int
    public var totalCostLimit: Int

    /// Default: 300 items, 12MB total data (tunable).
    public static let `default` = CircleFlagCacheConfig(
        countLimit: 300,
        totalCostLimit: 12 * 1024 * 1024
    )

    public init(countLimit: Int, totalCostLimit: Int) {
        self.countLimit = countLimit
        self.totalCostLimit = totalCostLimit
    }
}

// MARK: - Concurrency-safe data cache (actor isolated)

actor CircleFlagDataCache {
    static let shared = CircleFlagDataCache()

    private var config: CircleFlagCacheConfig = .default

    private let cache: NSCache<NSString, NSData> = {
        NSCache<NSString, NSData>()
    }()

    // In-flight de-dup: avoid loading the same key concurrently.
    private var inFlight: [String: Task<Data?, Never>] = [:]

    // Test hook (actor isolated, concurrency-safe)
    private var testLoader: (@Sendable (_ key: String) -> Data?)? = nil

    init() {
        // init 是 nonisolated，上来就直接配置 NSCache（允许）
        cache.countLimit = CircleFlagCacheConfig.default.countLimit
        cache.totalCostLimit = CircleFlagCacheConfig.default.totalCostLimit
        config = .default
    }

    func configure(_ newConfig: CircleFlagCacheConfig) {
        config = newConfig
        cache.countLimit = newConfig.countLimit
        cache.totalCostLimit = newConfig.totalCostLimit
    }

    func data(
        forKey key: String,
        realLoader: @Sendable @escaping () -> Data?
    ) async -> Data? {

        // Cache hit
        if let cached = cache.object(forKey: key as NSString) {
            return cached as Data
        }

        // In-flight hit
        if let task = inFlight[key] {
            return await task.value
        }

        let injected = testLoader

        let task = Task<Data?, Never> {
            if let injected { return injected(key) }
            return realLoader()
        }

        inFlight[key] = task
        let result = await task.value
        inFlight[key] = nil

        if let result {
            cache.setObject(result as NSData, forKey: key as NSString, cost: result.count)
        }

        return result
    }

    func clear() {
        cache.removeAllObjects()
        inFlight.removeAll()
    }

    // MARK: - Test hooks

    func _setTestLoader(_ loader: (@Sendable (_ key: String) -> Data?)?) {
        testLoader = loader
    }
}

// MARK: - Loader API

public enum CircleFlagImage {

    // MARK: Contract / configuration

    static let fallbackCode = "xx"

    /// Try bundle root first; then "Resources" as a safety net.
    static let candidateSubdirectories: [String?] = [nil, "Resources"]

    // MARK: Cache config API

    /// Configure internal cache limits (count + total bytes).
    public static func configureCache(_ config: CircleFlagCacheConfig) async {
        await CircleFlagDataCache.shared.configure(config)
    }

    /// Clear in-memory cache (useful for memory pressure or tests).
    public static func clearCache() async {
        await CircleFlagDataCache.shared.clear()
    }

    // MARK: Public helpers

    /// Normalize raw input into a resource key (best-effort), then resolve to ISO2-ish:
    ///
    /// Accepts:
    /// - "us", "US", " us "
    /// - "en_US", "en-US"  -> "us" (takes last component)
    /// - "us.png"          -> "us"
    /// - "u s"             -> "us" (letters-only filter)
    ///
    /// Returns:
    /// - exactly 2 letters [a-z] if derivable; otherwise empty string (caller may fallback).

    public static func normalizedKey(from raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmed.isEmpty { return "" }

        // Strip ".png" suffix if user passes "us.png"
        let noExt: String = {
            if trimmed.hasSuffix(".png") {
                return String(trimmed.dropLast(4))
            }
            return trimmed
        }()

        // If locale-like: "en_us" / "en-us" -> take the last component as region.
        let regionCandidate: String = {
            if noExt.contains("_") {
                return noExt.split(separator: "_").last.map(String.init) ?? noExt
            }
            if noExt.contains("-") {
                return noExt.split(separator: "-").last.map(String.init) ?? noExt
            }
            return noExt
        }()

        // Keep only letters a-z
        let lettersOnly = regionCandidate.filter { $0 >= "a" && $0 <= "z" }

        // Enforce 2 letters; otherwise invalid.
        guard lettersOnly.count == 2 else { return "" }
        return lettersOnly
    }

    /// Resolve input to a deterministic key.
    /// Invalid / empty resolves to fallbackCode ("xx").
    public static func resolvedKey(for code: String) -> String {
        let key = normalizedKey(from: code)
        return key.isEmpty ? fallbackCode : key
    }

    // MARK: Public API

    /// Main API (cross-platform):
    /// - If `<code>.png` exists → return it
    /// - Else → return `xx.png` (fallback) if exists
    /// - Only returns nil if neither exists (misconfiguration)
    ///
    /// Note: decoding to PlatformImage is performed on MainActor for UI safety.
    @MainActor
    public static func image(for code: String) async -> PlatformImage? {
        let key = resolvedKey(for: code)

        if key != fallbackCode, let img = await loadWithCache(for: key) {
            return img
        }

        if let fallback = await loadWithCache(for: fallbackCode) {
            return fallback
        }

        return nil
    }

    @MainActor
    public static func uiImage(for code: String) async -> PlatformImage? {
        await image(for: code)
    }

    // MARK: Preload (internal)

    /// Internal helper used by `CircleFlagPreloader`.
    static func _preloadResolvedKeys(_ keys: [String], maxConcurrency: Int) async {
        let limit = max(1, min(maxConcurrency, 24))
        await withTaskGroup(of: Void.self) { group in
            var iterator = keys.makeIterator()

            // Start initial batch
            for _ in 0..<limit {
                guard let next = iterator.next() else { break }
                group.addTask { await _preloadSingleResolvedKey(next) }
            }

            while await group.next() != nil {
                guard let next = iterator.next() else { continue }
                group.addTask { await _preloadSingleResolvedKey(next) }
            }
        }
    }

    private static func _preloadSingleResolvedKey(_ key: String) async {
        // Best-effort: only load Data into cache (decode later).
        _ = await CircleFlagDataCache.shared.data(forKey: key) {
            loadPNGDataFromBundle(named: key)
        }
    }

    // MARK: - Internal helpers

    @MainActor
    private static func loadWithCache(for key: String) async -> PlatformImage? {
        // 1) Ask actor cache for Data (Sendable across actor boundary)
        let data = await CircleFlagDataCache.shared.data(forKey: key) {
            loadPNGDataFromBundle(named: key)
        }

        // 2) Decode image on MainActor
        guard let data else { return nil }
        return decodeImage(from: data)
    }

    private static func loadPNGDataFromBundle(named name: String) -> Data? {
        for subdir in candidateSubdirectories {
            guard let url = Bundle.module.url(forResource: name, withExtension: "png", subdirectory: subdir) else {
                continue
            }
            return try? Data(contentsOf: url, options: [.mappedIfSafe])
        }
        return nil
    }

    @MainActor
    private static func decodeImage(from data: Data) -> PlatformImage? {
        #if canImport(UIKit)
        return UIImage(data: data)
        #elseif canImport(AppKit)
        return NSImage(data: data)
        #else
        return nil
        #endif
    }

    // MARK: - Test helper (internal; accessible via @testable)

    static func resourceURL(forNormalizedKey key: String) -> URL? {
        for subdir in candidateSubdirectories {
            if let url = Bundle.module.url(forResource: key, withExtension: "png", subdirectory: subdir) {
                return url
            }
        }
        return nil
    }

    // MARK: - Test injection (internal; accessible via @testable)

    static func _installTestLoader(_ loader: (@Sendable (_ key: String) -> Data?)?) async {
        await CircleFlagDataCache.shared._setTestLoader(loader)
    }

    static func _resetForTesting() async {
        await CircleFlagDataCache.shared._setTestLoader(nil)
        await CircleFlagDataCache.shared.clear()
        await CircleFlagDataCache.shared.configure(.default)
    }
}
