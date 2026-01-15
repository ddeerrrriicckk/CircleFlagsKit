//
//  CircleFlagPreloader.swift
//  CircleFlagsKit
//

import Foundation

public enum CircleFlagPreloader {

    /// Preload flag data into cache (best-effort).
    /// This will NOT force decode to UIImage/NSImage; decode happens when displayed.
    public static func preload(_ codes: [String], maxConcurrency: Int = 10) async {
        await preload(Set(codes), maxConcurrency: maxConcurrency)
    }

    public static func preload(_ codes: Set<String>, maxConcurrency: Int = 10) async {
        let keys = codes.map { CircleFlagImage.resolvedKey(for: $0) }
        await CircleFlagImage._preloadResolvedKeys(keys, maxConcurrency: maxConcurrency)
    }
}
