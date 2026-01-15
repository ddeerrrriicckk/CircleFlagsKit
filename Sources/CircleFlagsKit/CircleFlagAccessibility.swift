//
//  CircleFlagAccessibility.swift
//  CircleFlagsKit
//

import Foundation

public protocol CircleFlagAccessibilityNaming {
    /// - Returns: localized country/region name for ISO region code, or nil if unknown.
    func localizedRegionName(forResolvedCode code: String, locale: Locale) -> String?
}

public struct SystemCircleFlagAccessibilityNaming: CircleFlagAccessibilityNaming {
    public init() {}

    // Some common non-standard aliases in flag sets.
    private let aliasToISO: [String: String] = [
        "uk": "GB"
    ]

    public func localizedRegionName(forResolvedCode code: String, locale: Locale) -> String? {
        let upper = code.uppercased()

        if let mapped = aliasToISO[code] {
            return locale.localizedString(forRegionCode: mapped)
        }

        // Locale API expects ISO region codes (US, GB, CA, ...)
        return locale.localizedString(forRegionCode: upper)
    }
}
