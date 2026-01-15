//
//  CircleFlagStyle.swift
//  CircleFlagsKit
//

import SwiftUI

public struct CircleFlagStyle {
    public var background: Background
    public var border: Border?
    public var placeholder: Placeholder

    public init(
        background: Background = .defaultBackground,
        border: Border? = nil,
        placeholder: Placeholder = .globe
    ) {
        self.background = background
        self.border = border
        self.placeholder = placeholder
    }

    public struct Border {
        public var width: CGFloat
        public var color: Color

        public init(width: CGFloat = 1, color: Color = .white.opacity(0.20)) {
            self.width = width
            self.color = color
        }
    }

    public enum Background {
        case none
        case color(Color)
        case material(Material)

        public static var defaultBackground: Background {
            .color(Color.white.opacity(0.10))
        }
    }

    public enum Placeholder {
        case globe
        case monogram
        case color(Color)
        case none
    }

    /// computed：避免“共享可变状态”并发警告
    public static var `default`: CircleFlagStyle { CircleFlagStyle() }
}
