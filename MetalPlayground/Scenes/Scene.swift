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
    var name: String { get }
    var vertexFuncName: String { get }
    var fragmentFuncName: String { get }

    init()

    var view: NSView? { get }
    func tick(time: Float)
    func setUniforms(device: MTLDevice, encoder: MTLRenderCommandEncoder)
    func buildPipeline(device: MTLDevice, pixelFormat: MTLPixelFormat) -> (MTLRenderPipelineState, MTLBuffer)
    func draw(encoder: MTLRenderCommandEncoder)
}

extension Scene {
    func tick(time: Float) { }
    private var basicVertices: [Vertex] {
        [
            Vertex(position: [-1, -1]),
            Vertex(position: [-1, 1]),
            Vertex(position: [1, 1]),

            Vertex(position: [-1, -1]),
            Vertex(position: [1, 1]),
            Vertex(position: [1, -1]),
        ]
    }

    func buildPipeline(device: MTLDevice, pixelFormat: MTLPixelFormat) -> (MTLRenderPipelineState, MTLBuffer) {
        let descriptor = buildBasicPipelineDescriptor(device: device, pixelFormat: pixelFormat)
        let pipeline = (try? device.makeRenderPipelineState(descriptor: descriptor))!


        let vertexBuffer = device.makeBuffer(bytes: basicVertices, length: MemoryLayout<Vertex>.stride * basicVertices.count, options: [])
        return (pipeline, vertexBuffer!)
    }

    func buildBasicPipelineDescriptor(device: MTLDevice, pixelFormat: MTLPixelFormat) -> MTLRenderPipelineDescriptor {
        let pipelineDesc = MTLRenderPipelineDescriptor()
        let library = device.makeDefaultLibrary()
        pipelineDesc.vertexFunction = library?.makeFunction(name: vertexFuncName)
        pipelineDesc.fragmentFunction = library?.makeFunction(name: fragmentFuncName)
        pipelineDesc.colorAttachments[0].pixelFormat = pixelFormat
        return pipelineDesc
    }

    func draw(encoder: MTLRenderCommandEncoder) {
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: basicVertices.count)
    }

    func setUniforms(device: MTLDevice, encoder: MTLRenderCommandEncoder) { }

    var view: NSView? {
        nil
    }
}

enum SceneKind: Int, CaseIterable, Identifiable {
    case modelsScene
    case girihPattern
    case smiley
    case starfield
    case simplest3D
    case rays
    case polarScene
    case domainDisortion
    case bookOfShaders05
    case bookOfShaders06

    var id: Int {
        rawValue
    }

    var name: String {
        switch self {
        case .modelsScene: return "Models"
        case .girihPattern: return "Girih Pattern #1"
        case .starfield: return "Starfield"
        case .smiley: return "Smiley"
        case .simplest3D: return "Simplest 3D"
        case .rays: return "Rays"
        case .polarScene: return "Polar scene"
        case .domainDisortion: return "Domain distortion"
        case .bookOfShaders05: return "Book of Shaders 05"
        case .bookOfShaders06: return "Book of Shaders 06"
        }
    }

    var scene: Scene {
        switch self {
        case .girihPattern: return Girih()
        case .starfield: return StarField()
        case .smiley: return Smiley()
        case .simplest3D: return Simplest3D()
        case .rays: return Rays()
        case .polarScene: return PolarScene()
        case .domainDisortion: return DomainDistortion()
        case .bookOfShaders05: return BookOfShaders05()
        case .bookOfShaders06: return BookOfShaders06()
        case .modelsScene: return ModelsScene()
        }
    }
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
