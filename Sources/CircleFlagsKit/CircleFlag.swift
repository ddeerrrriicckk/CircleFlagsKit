//
//  CircleFlag.swift
//  CircleFlagsKit
//

import SwiftUI

public struct CircleFlag: View {
    public let code: String?
    public var size: CGFloat
    public var showsFallback: Bool
    public var style: CircleFlagStyle
    public var accessibilityNaming: CircleFlagAccessibilityNaming
    public var accessibilityLocale: Locale

    @State private var image: PlatformImage?

    /// - Parameters:
    ///   - code: ISO-ish country/region code (e.g. "us", "gb").
    ///           Also accepts "en_US", "en-US", "US", "us.png", "u s" etc.
    ///           Nil/empty/invalid resolves to fallback "xx".
    ///   - size: The diameter of the circular flag.
    ///   - showsFallback: If loader returns nil (only when even xx.png is missing), show placeholder.
    ///   - style: Visual style (background/border/placeholder).
    ///   - accessibilityNaming: A11y naming provider (default uses system Locale mapping).
    ///   - accessibilityLocale: Locale for localization (default `.current`).
    public init(
        code: String?,
        size: CGFloat = 46,
        showsFallback: Bool = true,
        style: CircleFlagStyle = .default,
        accessibilityNaming: CircleFlagAccessibilityNaming = SystemCircleFlagAccessibilityNaming(),
        accessibilityLocale: Locale = .current
    ) {
        self.code = code
        self.size = size
        self.showsFallback = showsFallback
        self.style = style
        self.accessibilityNaming = accessibilityNaming
        self.accessibilityLocale = accessibilityLocale
    }

    private var resolvedKey: String {
        CircleFlagImage.resolvedKey(for: code ?? "")
    }

    public var body: some View {
        ZStack {
            backgroundView

            if let img = image {
                Image(platformImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if showsFallback {
                placeholderView
            }
        }
        .frame(width: size, height: size)
        .overlay(borderOverlay)
        .task(id: resolvedKey) {
            image = nil
            image = await CircleFlagImage.image(for: resolvedKey)
        }
        .accessibilityLabel(Text(accessibilityText(forResolvedKey: resolvedKey)))
    }

    // MARK: - Style building blocks

    @ViewBuilder
    private var backgroundView: some View {
        switch style.background {
        case .none:
            Circle().fill(Color.clear)
        case .color(let color):
            Circle().fill(color)
        case .material(let material):
            Circle().fill(material)
        }
    }

    @ViewBuilder
    private var placeholderView: some View {
        switch style.placeholder {
        case .globe:
            Text("🌐")
                .font(.system(size: size * 0.45))
        case .monogram:
            Text(resolvedKey.uppercased())
                .font(.system(size: size * 0.28, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary.opacity(0.7))
        case .color(let color):
            Circle().fill(color)
        case .none:
            EmptyView()
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        if let border = style.border {
            Circle()
                .stroke(border.color, lineWidth: border.width)
        } else {
            EmptyView()
        }
    }

    // MARK: - Accessibility

    private func accessibilityText(forResolvedKey key: String) -> String {
        if let name = accessibilityNaming.localizedRegionName(forResolvedCode: key, locale: accessibilityLocale) {
            return "Flag of \(name)"
        }
        return key.isEmpty ? "Flag" : "Flag \(key.uppercased())"
    }
}
