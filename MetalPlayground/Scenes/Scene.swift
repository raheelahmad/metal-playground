//
//  Scene.swift
//  MetalPlayground
//
//  Created by Raheel Ahmad on 7/26/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

import MetalKit
import SwiftUI

protocol Scene {
    typealias Built = (MTLRenderPipelineState, MTLBuffer) -> ()
    var name: String { get }
    var vertexFuncName: String { get }
    var fragmentFuncName: String { get }

    init()

    var view: NSView? { get }
    func tick(time: Float)
    func setUniforms(device: MTLDevice, encoder: MTLRenderCommandEncoder)
    func buildPipeline(device: MTLDevice, pixelFormat: MTLPixelFormat, built: @escaping Built)
    func draw(encoder: MTLRenderCommandEncoder)
    var isPaused: Bool { get }
}

extension Scene {
    func tick(time: Float) { }
    var isPaused: Bool { false }
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


    func buildPipeline(device: MTLDevice, pixelFormat: MTLPixelFormat, built: @escaping Built) {
        let descriptor = buildBasicPipelineDescriptor(device: device, pixelFormat: pixelFormat)
        let pipeline = (try? device.makeRenderPipelineState(descriptor: descriptor))!


        let vertexBuffer = device.makeBuffer(bytes: basicVertices, length: MemoryLayout<Vertex>.stride * basicVertices.count, options: [])
        built(pipeline, vertexBuffer!)
    }

    func buildBasicPipelineDescriptor(device: MTLDevice, pixelFormat: MTLPixelFormat) -> MTLRenderPipelineDescriptor {
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

    func setUniforms(device: MTLDevice, encoder: MTLRenderCommandEncoder) { }

    var view: NSView? {
        nil
    }
}

enum SceneKind: Int, CaseIterable, Identifiable {
    case liveCode
    case rayMarch
    case mattCourse
    case leftRightTiler
    case futuristicUI
    case happyJumping
    case smiley
    case rotatingSquare
    case sierpinski
    case modelsScene
    case girihPattern
    case starfield
    case simplest3D
    case polarScene
    case domainDisortion

    var id: Int {
        rawValue
    }

    var name: String {
        switch self {
        case .liveCode:
            return "Live Code"
        case .mattCourse:
            return "Matt DesLauriers' Course"
        case .rayMarch:
            return "Ray Marching"
        case .leftRightTiler:
            return "Book of Shaders - Left/Right Tiler"
        case .happyJumping:
            return "Happy Jumping"
        case .smiley:
            return "Smiley"
        case .rotatingSquare:
            return "Rotating Square"
        case .sierpinski:
            return "Sierpinski"
        case .modelsScene:
            return "Loading Models"
        case .girihPattern:
            return "Girih"
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
        }
    }

    var scene: Scene {
        switch self {
            case .rayMarch: return RayMarch()
        case .mattCourse: return MattCourseScene()
        case .liveCode: return LiveCodeScene()
        case .leftRightTiler: return BoSLeftRightTiler()
        case .futuristicUI: return FuturisticUI()
        case .rotatingSquare: return RotatingSquare()
        case .sierpinski: return Sierpinski()
        case .happyJumping: return HappyJumping()
        case .girihPattern: return Girih()
        case .starfield: return StarField()
        case .smiley: return Smiley()
        case .simplest3D: return Simplest3D()
        case .polarScene: return PolarScene()
        case .domainDisortion: return DomainDistortion()
        case .modelsScene: return ModelsScene()
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

class HappyJumping: Scene {
    var name: String { "Simplest 3D" }
    var vertexFuncName: String { "happy_jumping_vertex" }
    var fragmentFuncName: String { "happy_jumping_fragment" }
    required init() {}
}

class Simplest3D: Scene {
    var name: String { "Simplest 3D" }
    var vertexFuncName: String { "simplest_3d_vertex" }
    var fragmentFuncName: String { "simplest_3d_fragment" }
    required init() {}
}

class Smiley: Scene {
    var name: String { "Smiley" }

    var vertexFuncName: String { "shape_vertex" }
    var fragmentFuncName: String { "shaderToySmiley" }
    required init() {}
}

class FuturisticUI: Scene {
    var name: String { "Futuristic UI" }

    var vertexFuncName: String { "futuristic_UI_vertex" }
    var fragmentFuncName: String { "futuristic_UI_fragment" }
    required init() {}
}

class BoSLeftRightTiler: Scene {
    var name: String { "Book of Shaders - Left/Right Tiler" }

    var vertexFuncName: String { "leftright_vertex" }
    var fragmentFuncName: String { "leftright_fragment" }
    required init() {}
}

class PolarScene: Scene {
    var name: String { "Polar Experiments" }

    var vertexFuncName: String { "polar_experiments_vertex" }
    var fragmentFuncName: String { "polar_experiments_fragment" }
    required init() {}
}

class DomainDistortion: Scene {
    var name: String { "Domain Distortion" }

    var vertexFuncName: String { "domain_distortion_vertex" }
    var fragmentFuncName: String { "domain_distortion_fragment" }
    required init() {}
}

class BasicShaderToy: Scene {
    var name: String { "Basic ShaderToy" }

    var vertexFuncName: String { "shape_vertex" }
    var fragmentFuncName: String { "shadertoy01" }
    required init() {}
}

class BookOfShaders05: Scene {
    var name: String { "Book of Shaders 05 - Algorithmic" }

    var vertexFuncName: String { "smoothing_vertex" }
    var fragmentFuncName: String { "smoothing_fragment" }
    required init() {}
}

class BookOfShaders06: Scene {
    var name: String { "Book of Shaders 06 - Colors" }

    var vertexFuncName: String { "color_vertex" }
    var fragmentFuncName: String { "color_fragment" }
    required init() {}
}
