//
//  CircleFlagsKitSnapshotTests.swift
//  CircleFlagsKit
//

import XCTest
import SwiftUI
import SnapshotTesting
@testable import CircleFlagsKit

@MainActor
final class CircleFlagsKitSnapshotTests: XCTestCase {

    // MARK: - Record mode
    // To generate baseline snapshots locally: change to `.all` and run once;
    // after committing snapshots, switch back to `.never`
    private let recordMode: SnapshotTestingConfiguration.Record = .never

    // MARK: - Platform suffix (prevents iOS/macOS snapshot collisions)

    private var platformSuffix: String {
        #if os(iOS)
        return "ios"
        #elseif os(macOS)
        return "macos"
        #else
        return "other"
        #endif
    }

    // MARK: - Matrix

    override func setUp() async throws {
        await CircleFlagImage.clearCache()
        try await super.setUp()
    }

    override func tearDown() async throws {
        await CircleFlagImage.clearCache()
        try await super.tearDown()
    }

    func testSnapshotMatrix() {
        withSnapshotTesting(record: recordMode) {
            // Sizes you care about
            let sizes: [CGFloat] = [32, 46, 64]

            // Variants: (name, code, style, colorScheme)
            let variants: [(String, String?, CircleFlagStyle, ColorScheme?)] = [
                ("default_us_light", "us", .default, .light),
                ("default_gb_dark", "gb", .default, .dark),

                ("missing_globe_light", "__missing__", CircleFlagStyle(placeholder: .globe), .light),
                ("missing_monogram_light", "__missing__", CircleFlagStyle(placeholder: .monogram), .light),

                ("nil_monogram_light", nil, CircleFlagStyle(placeholder: .monogram), .light),

                ("border_material_monogram_dark",
                 "__missing__",
                 CircleFlagStyle(
                    background: .material(.ultraThin),
                    border: .init(width: 2, color: .white.opacity(0.6)),
                    placeholder: .monogram
                 ),
                 .dark),

                ("no_bg_border_globe_light",
                 "__missing__",
                 CircleFlagStyle(
                    background: .none,
                    border: .init(width: 1, color: .primary.opacity(0.25)),
                    placeholder: .globe
                 ),
                 .light),

                ("color_bg_color_placeholder_light",
                 "__missing__",
                 CircleFlagStyle(
                    background: .color(.blue.opacity(0.15)),
                    border: .init(width: 1, color: .blue.opacity(0.35)),
                    placeholder: .color(.blue.opacity(0.25))
                 ),
                 .light)
            ]

            for size in sizes {
                for (name, code, style, scheme) in variants {
                    let view = makeView(code: code, size: size, style: style, scheme: scheme)
                    assertSnapshotView(view, named: "\(name)_\(Int(size))_\(platformSuffix)")
                }
            }
        }
    }
    
    func testSnapshot_AccessibilityAndInternationalization() {
        withSnapshotTesting(record: recordMode) {

            let style = CircleFlagStyle(
                background: .material(.ultraThin),
                border: .init(width: 1, color: .primary.opacity(0.3)),
                placeholder: .monogram
            )

            let baseView = CircleFlag(
                code: "us",
                size: 64,
                style: style,
                accessibilityLocale: Locale(identifier: "en_US")
            )
            .padding(10)

            // Dynamic Type (extra-extra-extra large)
            assertSnapshotView(
                baseView
                    .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge),
                named: "a11y_dynamic_type_xxxl_\(platformSuffix)"
            )

            // RTL layout
            assertSnapshotView(
                baseView
                    .environment(\.layoutDirection, .rightToLeft),
                named: "rtl_layout_\(platformSuffix)"
            )

            // Different locale (Arabic)
            assertSnapshotView(
                baseView
                    .environment(\.locale, Locale(identifier: "ar")),
                named: "locale_ar_\(platformSuffix)"
            )
        }
    }

    // MARK: - Builders

    private func makeView(code: String?, size: CGFloat, style: CircleFlagStyle, scheme: ColorScheme?) -> some View {
        var v = AnyView(
            CircleFlag(
                code: code,
                size: size,
                style: style,
                accessibilityNaming: SystemCircleFlagAccessibilityNaming(),
                accessibilityLocale: Locale(identifier: "en_US")
            )
            .padding(10)
        )
        if let scheme {
            v = AnyView(v.preferredColorScheme(scheme))
        }
        return v
    }

    // MARK: - Snapshot helper
    // No file/testName/line passed → avoids filePath warnings

    private func assertSnapshotView(_ view: some View, named name: String) {
        #if canImport(UIKit)
        let vc = UIHostingController(rootView: view)
        vc.view.frame = CGRect(x: 0, y: 0, width: 160, height: 160)

        assertSnapshot(
            of: vc,
            as: .image(on: .iPhone13),
            named: name
        )

        #elseif canImport(AppKit)
        let hosting = NSHostingView(rootView: view)
        hosting.frame = CGRect(x: 0, y: 0, width: 160, height: 160)

        assertSnapshot(
            of: hosting,
            as: .image,
            named: name
        )
        #endif
    }
}
