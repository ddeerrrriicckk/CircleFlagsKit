//
//  PlatformImage.swift
//  CircleFlagsKit
//

import SwiftUI

#if canImport(UIKit)
@preconcurrency import UIKit
public typealias PlatformImage = UIImage
#elseif canImport(AppKit)
@preconcurrency import AppKit
public typealias PlatformImage = NSImage
#endif

public extension Image {
    init(platformImage: PlatformImage) {
        #if canImport(UIKit)
        self.init(uiImage: platformImage)
        #elseif canImport(AppKit)
        self.init(nsImage: platformImage)
        #endif
    }
}
