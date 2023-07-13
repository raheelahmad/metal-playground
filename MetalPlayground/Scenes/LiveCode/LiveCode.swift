//
//  LiveCode.swift
//  MetalPlayground
//
//  Created by Raheel Ahmad on 1/9/21.
//  Copyright © 2021 Raheel Ahmad. All rights reserved.
//

import MetalKit
import SwiftUI
import Accelerate
import AVFoundation


extension MTLDevice {
    func makeBuffer(_ values: [Float]) -> MTLBuffer? {
        makeBuffer(bytes: values, length: MemoryLayout<Float>.size * values.count)
    }
}

public extension MTLRenderCommandEncoder {
    func setFragmentBytes<T>(_ value: T, index: Int) {
        var copy = value
        setFragmentBytes(&copy, length: MemoryLayout<T>.size, index: index)
    }

    func setFragmentBytes<T>(_ value: T, index: Int32) {
        var copy = value
        setFragmentBytes(&copy, length: MemoryLayout<T>.size, index: Int(index))
    }
}

extension Color {
    var components: SIMD4<Float> {

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        #if canImport(UIKit)
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        #elseif canImport(AppKit)
        NSColor(self).usingColorSpace(.deviceRGB)!.getRed(&r, green: &g, blue: &b, alpha: &a)
        #endif

        return .init(Float(r), Float(g), Float(b), Float(a))
    }
}

final class LiveCodeScene: Playground {
    let name = "Live Code"
    var fileName: String {
        "LiveCode/LiveCode"
    }

    let vertexFuncName = "liveCodeVertexShader"
    let fragmentFuncName = "liveCodeFragmentShader"

    init() {}

    func tearDown() { }

    private var device: MTLDevice?
    private var pixelFormat: MTLPixelFormat?

    func setUniforms(device: MTLDevice, encoder: MTLRenderCommandEncoder) { }
}
