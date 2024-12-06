//
//  Scene.swift
//  MetalPlayground
//
//  Created by Raheel Ahmad on 7/26/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

import MetalKit
import SwiftUI

protocol Playground {
    typealias Built = (MTLRenderPipelineState, MTLBuffer) -> Void

    /// Filename for the Shader
    var fileName: String { get }
    var vertexFuncName: String { get }
    var fragmentFuncName: String { get }

    // For mostly fragment-based
    var liveReloads: Bool { get }
    var ready: Bool { get }

    init()

    var view: NSView? { get }
    func tick(time: Float)
    func setUniforms(device: MTLDevice, encoder: MTLRenderCommandEncoder)
    func buildPipeline(device: MTLDevice, pixelFormat: MTLPixelFormat, built: @escaping Built)
    func draw(encoder: MTLRenderCommandEncoder)
    var isPaused: Bool { get }
}

extension Playground {
    var filePath: String { #filePath }
    func tick(time: Float) {}
    var isPaused: Bool { false }
    var liveReloads: Bool { true }
    var basicVertices: [Vertex] {
        [
            Vertex(position: [-1, -1]),
            Vertex(position: [-1, 1]),
            Vertex(position: [1, 1]),

            Vertex(position: [-1, -1]),
            Vertex(position: [1, 1]),
            Vertex(position: [1, -1]),
        ]
    }

    var ready: Bool { true }

    func buildPipeline(device: MTLDevice, pixelFormat: MTLPixelFormat, built: @escaping Built) {
        let descriptor = buildBasicPipelineDescriptor(device: device, pixelFormat: pixelFormat)
        let pipeline = (try? device.makeRenderPipelineState(descriptor: descriptor))!

        let vertexBuffer = device.makeBuffer(
            bytes: basicVertices, length: MemoryLayout<Vertex>.stride * basicVertices.count,
            options: [])
        built(pipeline, vertexBuffer!)
    }

    func buildBasicPipelineDescriptor(device: MTLDevice, pixelFormat: MTLPixelFormat)
        -> MTLRenderPipelineDescriptor
    {
        let pipelineDesc = MTLRenderPipelineDescriptor()
        let library = device.makeDefaultLibrary()
        pipelineDesc.vertexFunction = library?.makeFunction(name: vertexFuncName)
        pipelineDesc.fragmentFunction = library?.makeFunction(name: fragmentFuncName)
        pipelineDesc.colorAttachments[0].pixelFormat = pixelFormat
        return pipelineDesc
    }

    /// In most scenes where fragment shaders do the rendering themselves, basicVertices can be used for full screen Clip space coordinates.
    /// Hence this default implementation
    func draw(encoder: MTLRenderCommandEncoder) {
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: basicVertices.count)
    }

    func setUniforms(device: MTLDevice, encoder: MTLRenderCommandEncoder) {}

    var view: NSView? {
        nil
    }
}

enum PlaygroundGroup: String, CaseIterable, Identifiable {
    case bookOfShaders = "Book of Shaders"
    case artOfCode = "The Art of Code"
    case explorations = "Explorations"

    var id: String { rawValue }
    var scenes: [SceneKind] {
        switch self {
        case .bookOfShaders:
            return [
                .bookOfShaders07Shapes,
                .bookOfShaders05Shaping,
                .leftRightTiler,
                .futuristicUI,
                .domainDisortion,
                .bookOfShaders06Colors,
            ]
        case .artOfCode:
            return [
                .smiley, .starfield, .simplest3D, .polarScene,
            ]
        case .explorations:
            return [
                .audioVisualizer, .happyJumping, .girihPattern, .jumpingBalls,
                .cellularNoise
            ]
        }
    }
}

enum SceneKind: Int, CaseIterable, Identifiable {
    case jumpingBalls
    case leftRightTiler
    case futuristicUI
    case domainDisortion
    case bookOfShaders05Shaping
    case bookOfShaders06Colors
    case bookOfShaders07Shapes

    case happyJumping
    case smiley
    case girihPattern
    case starfield
    case simplest3D
    case polarScene
    case audioVisualizer
    case cellularNoise

    var id: Int {
        rawValue
    }

    var name: String {
        switch self {
        case .jumpingBalls:
            return "Jumping Balls"
        case .audioVisualizer:
            return "Audio Visualizer"
        case .bookOfShaders05Shaping:
            return "Book Of Shaders - 05 - Shaping"
        case .bookOfShaders07Shapes:
            return "Book Of Shaders - 07 - Shapes"
        case .leftRightTiler:
            return "Book of Shaders - Left/Right Tiler"
        case .smiley:
            return "Smiley"
        case .girihPattern:
            return "Girih"
        case .happyJumping:
            return "Happy Jumping"
        case .starfield:
            return "Starfield"
        case .simplest3D:
            return "Simplest 3D"
        case .domainDisortion:
            return "Domain Distortion"
        case .polarScene:
            return "Polar"
        case .futuristicUI:
            return "Futuristic UI"
        case .cellularNoise:
            return "Cellular Noise"
        case .bookOfShaders06Colors:
            return "Colors Mixing"
        }
    }

    var scene: Playground {
        switch self {
        case .audioVisualizer: return AudioVizScene()
        case .jumpingBalls: return JumpingBalls()
        case .leftRightTiler: return BoSLeftRightTiler()
        case .bookOfShaders05Shaping: return BoSShaping()
        case .bookOfShaders06Colors: return BoSColors06()
        case .bookOfShaders07Shapes: return BoSShapes07()
        case .futuristicUI: return FuturisticUI()
        case .happyJumping: return HappyJumping()
        case .girihPattern: return Girih()
        case .starfield: return StarField()
        case .smiley: return Smiley()
        case .simplest3D: return Simplest3D()
        case .polarScene: return PolarScene()
        case .domainDisortion: return DomainDistortion()
        case .cellularNoise: return CellularNoise()
        }
    }
}

extension MDLVertexDescriptor {
    var vertexAttributes: [MDLVertexAttribute] {
        attributes as! [MDLVertexAttribute]
    }

    var bufferLayouts: [MDLVertexBufferLayout] {
        layouts as! [MDLVertexBufferLayout]
    }

    static var `default`: MDLVertexDescriptor = {
        let vd = MDLVertexDescriptor()
        // position
        vd.vertexAttributes[0].name = MDLVertexAttributePosition
        vd.vertexAttributes[0].format = .float3
        vd.vertexAttributes[0].offset = 0
        vd.vertexAttributes[0].bufferIndex = 0
        var nextOffset = MemoryLayout<float3>.size

        // normal
        //        vd.vertexAttributes[1].name = MDLVertexAttributeNormal
        //        vd.vertexAttributes[1].format = .float3
        //        vd.vertexAttributes[1].offset = nextOffset
        //        vd.vertexAttributes[1].bufferIndex = 0
        //        nextOffset += MemoryLayout<Float>.size * 3
        vd.bufferLayouts[0].stride = nextOffset

        return vd
    }()
}

class HappyJumping: Playground {
    var fileName: String {
        "Explorations/HappyJumping"
    }
    var vertexFuncName: String { "happy_jumping_vertex" }
    var fragmentFuncName: String { "happy_jumping_fragment" }
    required init() {}
}

class Simplest3D: Playground {
    var fileName: String {
        "Explorations/Simplest3D"
    }
    var vertexFuncName: String { "simplest_3d_vertex" }
    var fragmentFuncName: String { "simplest_3d_fragment" }
    required init() {}
}

class Smiley: Playground {

    var fileName: String {
        "Explorations/ShaderToySmiley"
    }
    var vertexFuncName: String { "shaderToySmileyVertex" }
    var fragmentFuncName: String { "shaderToySmiley" }
    required init() {}
}

class CellularNoise: Playground {
    var fileName: String {
        "Explorations/CellularNoise"
    }

    var vertexFuncName: String { "cellularVertexShader" }
    var fragmentFuncName: String { "tileFragmentShader2" }
    required init() {}
}

class FuturisticUI: Playground {
    var fileName: String {
        "Explorations/07FuturisticUI"
    }

    var vertexFuncName: String { "futuristic_UI_vertex" }
    var fragmentFuncName: String { "futuristic_UI_fragment" }
    required init() {}
}

class BoSLeftRightTiler: Playground {
    var fileName: String {
        "BookShaders/08LeftRightTiler"
    }
    var vertexFuncName: String { "leftright_vertex" }
    var fragmentFuncName: String { "leftright_fragment" }
    required init() {}
}

class BoSColors06: Playground {
    var fileName: String {
        "BookShaders/06Colors"
    }
    var vertexFuncName: String { "bos_colors_vertex" }
    var fragmentFuncName: String { "bos_colors_fragment" }
    required init() {}

    enum SketchKind: Int, CaseIterable, Identifiable {
        case bezierCurve
        case flowingCurves

        var id: Int { rawValue }

        var name: String {
            switch self {
            case .bezierCurve:
                return "Bezier Curve"
            case .flowingCurves:
                return "Flowing Curves"
            }
        }
    }

    class Config: ObservableObject {
        @Published var kind: SketchKind = .bezierCurve
    }

    struct Uniforms {
        let kind: Float
    }

    fileprivate var config: Config = .init()
    var fragmentUniforms: Uniforms {
        .init(kind: Float(config.kind.rawValue))
    }

    func setUniforms(device: MTLDevice, encoder: MTLRenderCommandEncoder) {
        var uniforms = fragmentUniforms
        let length = MemoryLayout.stride(ofValue: uniforms)
        encoder.setFragmentBytes(&uniforms, length: length, index: 1)
    }

    struct ConfigView: View {
        @EnvironmentObject private var config: Config
        @State fileprivate var kind = SketchKind.bezierCurve

        var body: some View {
            VStack(alignment: .leading, spacing: 19) {
                Picker(selection: $config.kind, label: Text("Kind")) {
                    ForEach(SketchKind.allCases) {
                        Text($0.name).tag($0)
                    }
                }
            }
        }
    }

    var view: NSView? {
        NSHostingView(
            rootView: ConfigView().environmentObject(config)
        )
    }
}

class BoSShaping: Playground {
    var fileName: String {
        "BookShaders/Shaping"
    }
    var vertexFuncName: String { "bos_shaping_vertex" }
    var fragmentFuncName: String { "bos_shaping_fragment" }
    required init() {}

    enum SketchKind: Int, CaseIterable, Identifiable {
        case bezierCurve
        case flowingCurves

        var id: Int { rawValue }

        var name: String {
            switch self {
            case .bezierCurve:
                return "Bezier Curve"
            case .flowingCurves:
                return "Flowing Curves"
            }
        }
    }

    class Config: ObservableObject {
        @Published var kind: SketchKind = .bezierCurve
    }

    struct Uniforms {
        let kind: Float
    }

    fileprivate var config: Config = .init()
    var fragmentUniforms: Uniforms {
        .init(kind: Float(config.kind.rawValue))
    }

    func setUniforms(device: MTLDevice, encoder: MTLRenderCommandEncoder) {
        var uniforms = fragmentUniforms
        let length = MemoryLayout.stride(ofValue: uniforms)
        encoder.setFragmentBytes(&uniforms, length: length, index: 1)
    }

    struct ConfigView: View {
        @EnvironmentObject private var config: Config
        @State fileprivate var kind = SketchKind.bezierCurve

        var body: some View {
            VStack(alignment: .leading, spacing: 19) {
                Picker(selection: $config.kind, label: Text("Kind")) {
                    ForEach(SketchKind.allCases) {
                        Text($0.name).tag($0)
                    }
                }
            }
        }
    }

    var view: NSView? {
        NSHostingView(
            rootView: ConfigView().environmentObject(config)
        )
    }
}

class PolarScene: Playground {
    var fileName: String {

        "Explorations/PolarExperiments"
    }
    var vertexFuncName: String { "polar_experiments_vertex" }
    var fragmentFuncName: String { "polar_experiments_fragment" }
    required init() {}
}

class DomainDistortion: Playground {
    var fileName: String {
        "Explorations/ShaderToyDistortions"
    }

    var vertexFuncName: String { "domain_distortion_vertex" }
    var fragmentFuncName: String { "domain_distortion_fragment" }
    required init() {}
}

class BookOfShaders05: Playground {
    var fileName: String {
        "Explorations/05Algorithmic"
    }

    var vertexFuncName: String { "smoothing_vertex" }
    var fragmentFuncName: String { "smoothing_fragment" }
    required init() {}
}

class BookOfShaders06: Playground {
    var fileName: String {
        "06Colors"
    }

    var vertexFuncName: String { "color_vertex" }
    var fragmentFuncName: String { "color_fragment" }
    required init() {}
}
