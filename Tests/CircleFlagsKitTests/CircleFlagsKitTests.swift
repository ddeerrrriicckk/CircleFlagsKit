//
//  CircleFlagsKitTests.swift
//  CircleFlagsKitTests
//

import XCTest
@testable import CircleFlagsKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

final class CircleFlagsKitTests: XCTestCase {

    // MARK: - Configuration

    private let knownExistingCodes: [String] = ["us", "gb", "ca"]
    private let fallbackCode = "xx"

    // MARK: - Provided resource codes (without ".png")
    private let allProvidedCodes: [String] = [
        "ac","at","bj","ca","cq","do","fk","gl","hn","is","kr","lv","mo","nc","pe","qa","si","sy","to","uz","yt",
        "ad","au","bl","cc","cr","dz","fm","gm","hr","it","kw","ly","mp","ne","pf","re","sj","sz","tr","va","yu",
        "ae","aw","bm","cd","cu","ea","fo","gn","ht","je","ky","ma","mq","nf","pg","ro","sk","ta","tt","vc","za",
        "af","ax","bn","cf","cv","ec","fr","gp","hu","jm","kz","mc","mr","ng","ph","rs","sl","tc","tv","ve","zm",
        "ag","az","bo","cg","cw","ee","fx","gq","ic","jo","la","md","ms","ni","pk","ru","sm","td","tw","vg","zw",
        "ai","ba","bq","ch","cx","eg","ga","gr","id","jp","lb","me","mt","nl","pl","rw","sn","tf","tz","vi",
        "al","bb","br","ci","cy","eh","gb","gs","ie","ke","lc","mf","mu","no","pm","sa","so","tg","ua","vn",
        "am","bd","bs","ck","cz","er","gd","gt","il","kg","li","mg","mv","np","pn","sb","sr","th","ug","vu",
        "an","be","bt","cl","de","es","ge","gu","im","kh","lk","mh","mw","nr","pr","sc","ss","tj","uk","wf",
        "ao","bf","bv","cm","dg","et","gf","gw","in","ki","lr","mk","mx","nu","ps","sd","st","tk","um","ws",
        "aq","bg","bw","cn","dj","eu","gg","gy","io","km","ls","ml","my","nz","pt","se","su","tl","un","xk",
        "ar","bh","by","co","dk","fi","gh","hk","iq","kn","lt","mm","mz","om","pw","sg","sv","tm","us","xx",
        "as","bi","bz","cp","dm","fj","gi","hm","ir","kp","lu","mn","na","pa","py","sh","sx","tn","uy","ye"
    ]

    // MARK: - Thread-safe counter

    final class Counter: @unchecked Sendable {
        private let lock = NSLock()
        private var counts: [String: Int] = [:]

        func inc(_ key: String) {
            lock.lock()
            counts[key, default: 0] += 1
            lock.unlock()
        }

        func get(_ key: String) -> Int {
            lock.lock()
            let v = counts[key, default: 0]
            lock.unlock()
            return v
        }
    }

    // MARK: - PNG data factory

    private enum TestColor { case red, green }

    private func makeTestPNGData(_ color: TestColor) -> Data {
        #if canImport(UIKit)
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8))
        let image = renderer.image { ctx in
            switch color {
            case .red: UIColor.red.setFill()
            case .green: UIColor.green.setFill()
            }
            ctx.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }
        guard let data = image.pngData() else {
            XCTFail("Failed to create PNG data")
            return Data()
        }
        return data
        #elseif canImport(AppKit)
        let img = NSImage(size: NSSize(width: 8, height: 8))
        img.lockFocus()
        switch color {
        case .red: NSColor.red.setFill()
        case .green: NSColor.green.setFill()
        }
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: 8, height: 8)).fill()
        img.unlockFocus()

        guard
            let tiff = img.tiffRepresentation,
            let rep = NSBitmapImageRep(data: tiff),
            let data = rep.representation(using: .png, properties: [:])
        else {
            XCTFail("Failed to create PNG data")
            return Data()
        }
        return data
        #endif
    }

    override func setUp() async throws {
        await CircleFlagImage._resetForTesting()   // Clear loader + clear cache + restore default config
        try await super.setUp()
    }

    override func tearDown() async throws {
        await CircleFlagImage._resetForTesting()
        try await super.tearDown()
    }

    // MARK: - Bundle wiring

    func testModuleBundleIsAccessible() {
        XCTAssertFalse(Bundle.module.bundlePath.isEmpty, "Bundle.module should be accessible and have a valid path.")
    }

    func testFallbackResourceXXIsPackagedInModule() {
        let url = CircleFlagImage.resourceURL(forNormalizedKey: fallbackCode)
        XCTAssertNotNil(url, "Fallback asset 'xx.png' must exist in Bundle.module resources.")
    }

    func testKnownResourceIsPackagedInModule() {
        let key = knownExistingCodes[0].lowercased()
        let url = CircleFlagImage.resourceURL(forNormalizedKey: key)
        XCTAssertNotNil(url, "Expected '\(key).png' to be present in Bundle.module resources.")
    }

    // MARK: - Pure functions (comprehensive)

    func testNormalizedKey_Comprehensive() {
        // 1) Sanity: provided codes should be strictly 2 letters a-z
        for code in allProvidedCodes {
            XCTAssertEqual(code.count, 2, "Provided code '\(code)' is not 2 letters.")
            XCTAssertTrue(code.allSatisfy({ $0 >= "a" && $0 <= "z" }), "Provided code '\(code)' contains non a-z.")
        }

        // 2) For every provided code, validate common input variants normalize to that code
        for code in allProvidedCodes {
            XCTAssertEqual(CircleFlagImage.normalizedKey(from: code), code, "Exact code normalize: \(code)")
            XCTAssertEqual(CircleFlagImage.normalizedKey(from: code.uppercased()), code, "Uppercase normalize: \(code)")
            XCTAssertEqual(CircleFlagImage.normalizedKey(from: "  \(code)  "), code, "Trim normalize: \(code)")
            XCTAssertEqual(CircleFlagImage.normalizedKey(from: "\n\t\(code)\t\n"), code, "Trim tabs/newlines: \(code)")
            XCTAssertEqual(CircleFlagImage.normalizedKey(from: "\(code).png"), code, "Strip .png: \(code)")
            XCTAssertEqual(CircleFlagImage.normalizedKey(from: "  \(code).png  "), code, "Strip .png + trim: \(code)")
            XCTAssertEqual(CircleFlagImage.normalizedKey(from: "en_\(code)"), code, "Locale en_XX => region: \(code)")
            XCTAssertEqual(CircleFlagImage.normalizedKey(from: "en-\(code)"), code, "Locale en-XX => region: \(code)")
        }

        // 3) Messy-but-recoverable inputs (matches CURRENT algorithm contract)
        XCTAssertEqual(CircleFlagImage.normalizedKey(from: "u s"), "us")
        XCTAssertEqual(CircleFlagImage.normalizedKey(from: " US "), "us")
        XCTAssertEqual(CircleFlagImage.normalizedKey(from: " us.png "), "us")

        // 'en_' / 'en-' -> 'en' (letters-only + 2-letter rule)
        XCTAssertEqual(CircleFlagImage.normalizedKey(from: "en_"), "en")
        XCTAssertEqual(CircleFlagImage.normalizedKey(from: "en-"), "en")

        // Multi-part locale: last segment -> "hk"
        XCTAssertEqual(CircleFlagImage.normalizedKey(from: "zh-Hant-HK"), "hk")

        // Leading separators: last segment -> "us"
        XCTAssertEqual(CircleFlagImage.normalizedKey(from: "_us"), "us")
        XCTAssertEqual(CircleFlagImage.normalizedKey(from: "-us"), "us")

        // Path-ish strings: letters-only can recover 2-letter key (current behavior)
        XCTAssertEqual(CircleFlagImage.normalizedKey(from: "../us"), "us")
        XCTAssertEqual(CircleFlagImage.normalizedKey(from: "us/.."), "us")
        XCTAssertEqual(CircleFlagImage.normalizedKey(from: #"us\.."#), "us")

        // 4) Truly invalid inputs should normalize to ""
        let invalidInputs: [String] = [
            "", "   ", "\n\t",
            "u", "usa", "abcd",
            "1", "12", "u1", "1u", "u_", "_u",
            "🇺🇸", "🇬🇧",
            "us.jpeg", "us.jpg", "us.webp", "us.gif", // only .png stripping
            "en_USA", "en_US_POSIX"                   // last chunk not 2 letters
        ]

        for raw in invalidInputs {
            XCTAssertEqual(CircleFlagImage.normalizedKey(from: raw), "", "Invalid input => empty: '\(raw)'")
        }
    }

    func testResolvedKey_ForAllProvidedCodes() {
        for code in allProvidedCodes {
            XCTAssertEqual(CircleFlagImage.resolvedKey(for: code), code)
            XCTAssertEqual(CircleFlagImage.resolvedKey(for: code.uppercased()), code)
            XCTAssertEqual(CircleFlagImage.resolvedKey(for: "en_\(code)"), code)
            XCTAssertEqual(CircleFlagImage.resolvedKey(for: "\(code).png"), code)
        }

        XCTAssertEqual(CircleFlagImage.resolvedKey(for: ""), "xx")
        XCTAssertEqual(CircleFlagImage.resolvedKey(for: "   "), "xx")
        XCTAssertEqual(CircleFlagImage.resolvedKey(for: "usa"), "xx")

        // Current algorithm may recover "us" from path-ish input.
        XCTAssertEqual(CircleFlagImage.resolvedKey(for: "../us"), "us")
    }

    // MARK: - Cache config API

    func testConfigureCache_DoesNotCrashAndLoads() async {
        let cfg = CircleFlagCacheConfig(countLimit: 10, totalCostLimit: 1024 * 1024)
        await CircleFlagImage.configureCache(cfg)

        let xxData = makeTestPNGData(.green)
        await CircleFlagImage._installTestLoader { key in
            (key == "xx") ? xxData : nil
        }

        let out = await CircleFlagImage.image(for: "__missing__")
        XCTAssertNotNil(out)
    }

    func testClearCache_DoesNotCrash() async {
        await CircleFlagImage.clearCache()
        // No assertion needed; just ensure API exists and does not crash.
        XCTAssertTrue(true)
    }

    // MARK: - Preload API

    func testPreload_WarmsCache_DataIsReused() async {
        let counter = Counter()
        let usData = makeTestPNGData(.red)
        let xxData = makeTestPNGData(.green)

        await CircleFlagImage._installTestLoader { key in
            counter.inc(key)
            if key == "us" { return usData }
            if key == "xx" { return xxData }
            return nil
        }

        // These all resolve to "us"
        await CircleFlagPreloader.preload(["us", "US", "  us  ", "en_US"], maxConcurrency: 4)

        // Preload should have triggered exactly one load for "us" (in-flight + cache).
        XCTAssertEqual(counter.get("us"), 1)

        // Subsequent image loads should be cache hits.
        _ = await CircleFlagImage.image(for: "us")
        XCTAssertEqual(counter.get("us"), 1)
    }

    // MARK: - Deterministic contract via injected loader (Data)

    func testExistingKeyReturnsThatKeyImage() async {
        let usData = makeTestPNGData(.red)
        let xxData = makeTestPNGData(.green)

        await CircleFlagImage._installTestLoader { key in
            if key == "us" { return usData }
            if key == "xx" { return xxData }
            return nil
        }

        let out = await CircleFlagImage.image(for: "us")
        XCTAssertNotNil(out, "Expected image for 'us'")

        let sig = await pixelSignature(out)
        XCTAssertEqual(sig, .red, "Expected 'us' image (red), not fallback (green)")
    }

    func testMissingKeyReturnsFallbackXX() async {
        let xxData = makeTestPNGData(.green)

        await CircleFlagImage._installTestLoader { key in
            if key == "xx" { return xxData }
            return nil
        }

        let out = await CircleFlagImage.image(for: "__missing__")
        XCTAssertNotNil(out)

        let sig = await pixelSignature(out)
        XCTAssertEqual(sig, .green, "Expected fallback (green)")
    }

    func testEmptyOrWhitespaceReturnsFallbackXX() async {
        let xxData = makeTestPNGData(.green)

        await CircleFlagImage._installTestLoader { key in
            if key == "xx" { return xxData }
            return nil
        }

        let a = await CircleFlagImage.image(for: "")
        XCTAssertNotNil(a)
        let sigA = await pixelSignature(a)
        XCTAssertEqual(sigA, .green)

        let b = await CircleFlagImage.image(for: "   ")
        XCTAssertNotNil(b)
        let sigB = await pixelSignature(b)
        XCTAssertEqual(sigB, .green)

        let c = await CircleFlagImage.image(for: "\n\t")
        XCTAssertNotNil(c)
        let sigC = await pixelSignature(c)
        XCTAssertEqual(sigC, .green)
    }

    func testHardFailureReturnsNilWhenEvenFallbackMissing() async {
        await CircleFlagImage._installTestLoader { _ in nil }
        let out = await CircleFlagImage.image(for: "us")
        XCTAssertNil(out, "Expected nil when both requested key and fallback are missing.")
    }

    // MARK: - Cache behavior

    func testCacheHitAvoidsSecondLoad() async {
        let counter = Counter()
        let usData = makeTestPNGData(.red)
        let xxData = makeTestPNGData(.green)

        await CircleFlagImage._installTestLoader { key in
            counter.inc(key)
            if key == "us" { return usData }
            if key == "xx" { return xxData }
            return nil
        }

        let first = await CircleFlagImage.image(for: "us")
        XCTAssertNotNil(first)
        let sig1 = await pixelSignature(first)
        XCTAssertEqual(sig1, .red)

        let second = await CircleFlagImage.image(for: "us")
        XCTAssertNotNil(second)
        let sig2 = await pixelSignature(second)
        XCTAssertEqual(sig2, .red)

        XCTAssertEqual(counter.get("us"), 1, "Expected loader called once due to caching (data cache).")
        XCTAssertEqual(counter.get("xx"), 0, "Fallback should not be touched when 'us' exists.")
    }

    func testFallbackIsAlsoCached() async {
        let counter = Counter()
        let xxData = makeTestPNGData(.green)

        await CircleFlagImage._installTestLoader { key in
            counter.inc(key)
            if key == "xx" { return xxData }
            return nil
        }

        let a = await CircleFlagImage.image(for: "__missing_a__")
        XCTAssertNotNil(a)
        let sigA = await pixelSignature(a)
        XCTAssertEqual(sigA, .green)

        let b = await CircleFlagImage.image(for: "__missing_b__")
        XCTAssertNotNil(b)
        let sigB = await pixelSignature(b)
        XCTAssertEqual(sigB, .green)

        XCTAssertEqual(counter.get("xx"), 1, "Expected fallback loaded once due to caching.")
    }

    // MARK: - In-flight de-dup

    func testInFlightDedupLoadsOnlyOnceUnderConcurrency() async {
        let counter = Counter()
        let usData = makeTestPNGData(.red)
        let xxData = makeTestPNGData(.green)

        await CircleFlagImage._installTestLoader { key in
            counter.inc(key)
            // Slow down to force overlap between concurrent callers.
            Thread.sleep(forTimeInterval: 0.05)
            if key == "us" { return usData }
            if key == "xx" { return xxData }
            return nil
        }

        // Fire concurrent requests (all normalize to "us")
        async let a = CircleFlagImage.image(for: "us")
        async let b = CircleFlagImage.image(for: "US")
        async let c = CircleFlagImage.image(for: "  us  ")

        let tasks = (0..<20).map { _ in
            Task { await CircleFlagImage.image(for: "us") }
        }

        _ = await a
        _ = await b
        _ = await c

        for t in tasks {
            _ = await t.value
        }

        XCTAssertEqual(counter.get("us"), 1, "Expected in-flight de-dup to load 'us' only once.")
    }

    // MARK: - Accessibility naming

    func testAccessibilityNaming_LocalizedNameIsAvailableForUS_InEnglishLocale() {
        let naming = SystemCircleFlagAccessibilityNaming()
        let locale = Locale(identifier: "en_US")

        let result = naming.localizedRegionName(forResolvedCode: "us", locale: locale)
        XCTAssertNotNil(result)
        // Not asserting exact string (depends on platform localization tables),
        // only that something exists for a standard ISO region code.
    }

    // MARK: - Helpers: identify returned image by reading 1x1 pixel signature

    private enum PixelSig: Equatable { case red, green, other }

    private func pixelSignature(_ image: PlatformImage?) async -> PixelSig {
        await MainActor.run {
            guard let image else { return .other }

            #if canImport(UIKit)
            guard let cg = image.cgImage else { return .other }
            return Self.cgTopLeftPixelSignature(cg)

            #elseif canImport(AppKit)
            guard let tiff = image.tiffRepresentation,
                  let rep = NSBitmapImageRep(data: tiff),
                  let cg = rep.cgImage
            else { return .other }
            return Self.cgTopLeftPixelSignature(cg)
            #endif
        }
    }

    private static func cgTopLeftPixelSignature(_ cg: CGImage) -> PixelSig {
        var pixel: [UInt8] = [0, 0, 0, 0] // RGBA

        guard let ctx = CGContext(
            data: &pixel,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return .other }

        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: 1, height: 1))

        let r = pixel[0]
        let g = pixel[1]

        if r > 200 && g < 80 { return .red }
        if g > 200 && r < 80 { return .green }
        return .other
    }
}
