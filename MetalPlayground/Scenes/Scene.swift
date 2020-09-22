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
    func mesh(device: MTLDevice) -> MTKMesh?
    var vertices: [simd_float3]? { get }
    func tick(time: Float)
    func setUniforms(device: MTLDevice, encoder: MTLRenderCommandEncoder)
}

extension Scene {
    func tick(time: Float) { }
    func buildPipeline(device: MTLDevice, pixelFormat: MTLPixelFormat) -> MTLRenderPipelineState {
        let pipelineDesc = MTLRenderPipelineDescriptor()
        let library = device.makeDefaultLibrary()
        pipelineDesc.vertexFunction = library?.makeFunction(name: vertexFuncName)
        pipelineDesc.fragmentFunction = library?.makeFunction(name: fragmentFuncName)
        pipelineDesc.colorAttachments[0].pixelFormat = pixelFormat
        if let mesh = self.mesh(device: device) {
            pipelineDesc.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mesh.vertexDescriptor)
        }
        return (try? device.makeRenderPipelineState(descriptor: pipelineDesc))!
    }


    func setUniforms(device: MTLDevice, encoder: MTLRenderCommandEncoder) { }

    var view: NSView? {
        nil
    }

    func mesh(device: MTLDevice) -> MTKMesh? { nil }

    var vertices: [simd_float3]? { nil }
}

enum SceneKind: Int, CaseIterable, Identifiable {
    case girihPattern1
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
        case .girihPattern1: return "Girih Pattern #1"
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
        case .girihPattern1: return RepeatingCircles()
        case .starfield: return StarField()
        case .smiley: return Smiley()
        case .simplest3D: return Simplest3D()
        case .rays: return Rays()
        case .polarScene: return PolarScene()
        case .domainDisortion: return DomainDistortion()
        case .bookOfShaders05: return BookOfShaders05()
        case .bookOfShaders06: return BookOfShaders06()
        }
    }
}

var allScenes: [Scene.Type] {
    [
        RepeatingCircles.self,
        Simplest3D.self,
        RayMarching.self,
        QuizlesHappyJumping.self,
        Rays.self,
        MetalByTutorials04.self,
        MetalByTutorials03.self,
        PolarScene.self,
        MetalByTutorials01.self,
        DomainDistortion.self, BasicShaderToy.self, StarField.self, Smiley.self, BookOfShaders05.self, BookOfShaders06.self]
}

class StarFieldConfig: ObservableObject {
    @Published var rotating: Bool = false
    @Published var flying: Bool = true
    @Published var numDepthLayers: Float = 1
    @Published var numDensityLayers: Float = 1
}

let starfieldConfig = StarFieldConfig()

class Torus: Scene {
    var name: String { "Torus" }
    var vertexFuncName: String { "torus_vertex" }
    var fragmentFuncName: String { "torus_fragment" }
    required init() {}
}

class Simplest3D: Scene {
    var name: String { "Simplest 3D" }
    var vertexFuncName: String { "simplest_3d_vertex" }
    var fragmentFuncName: String { "simplest_3d_fragment" }
    required init() {}
}

class RayMarching: Scene {
    var name: String { "Ray Marching" }
    var vertexFuncName: String { "raymarching_vertex" }
    var fragmentFuncName: String { "raymarching_fragment" }
    required init() {}
}

class QuizlesHappyJumping: Scene {
    var name: String { "Torus" }
    var vertexFuncName: String { "quizles_happy_jumping_vertex" }
    var fragmentFuncName: String { "quizles_happy_jumping_fragment" }
    required init() {}
}

class StarField: Scene {
    struct Uniforms {
        var rotating: Bool
        var flying: Bool
        var numDepthLayers: Float
        var numDensityLayers: Float
    }

    var name: String { "Star Field" }
    var vertexFuncName: String { "shape_vertex" }
    var fragmentFuncName: String { "shaderToyStarfield" }
    var starFieldUniforms: Uniforms {
        Uniforms(rotating: starfieldConfig.rotating, flying: starfieldConfig.flying, numDepthLayers: Float(starfieldConfig.numDepthLayers), numDensityLayers: Float(starfieldConfig.numDensityLayers))
    }

    var fragmentUniforms: Any? {
        starFieldUniforms
    }
    struct ConfigView: View {
        @EnvironmentObject var config: StarFieldConfig

        var body: some View {
            VStack(alignment: .leading, spacing: 19) {
                Toggle("Rotating", isOn: $config.rotating)
                Toggle("Flying", isOn: $config.flying)
                TitledSlider(title: "Depth Layers", value: $config.numDepthLayers, in: 0...10, step: 1) {
                    self.config.numDepthLayers = 1
                }
                TitledSlider(title: "Density Layers", value: $config.numDensityLayers, in: 1...10, step: 1) {
                    self.config.numDensityLayers = 1
                }
            }
        }
    }

    func setUniforms(device: MTLDevice, encoder: MTLRenderCommandEncoder) {
        var uniform = self.starFieldUniforms
        let length = MemoryLayout.size(ofValue: uniform)
        encoder.setFragmentBytes(&uniform, length: length, index: 1)
    }


    var view: NSView? {
        NSHostingView(
            rootView: ConfigView().environmentObject(starfieldConfig)
        )
    }
    required init() {}
}

class Smiley: Scene {
    var name: String { "Smiley" }

    var vertexFuncName: String { "shape_vertex" }
    var fragmentFuncName: String { "shaderToySmiley" }
    required init() {}
}

class MetalByTutorials03: Scene {
    var name: String { "3 - Metal By Tutorials"}
    var vertexFuncName: String { "metalByTutorials01_vertex" }
    var fragmentFuncName: String { "metalByTutorials01_fragment" }

    func mesh(device: MTLDevice) -> MTKMesh? {
        let allocator = MTKMeshBufferAllocator(device: device)
        let size: Float = 1
        let mdlMesh = MDLMesh(
            boxWithExtent: [size, size, size],
            segments: [1,1,1],
            inwardNormals: false,
            geometryType: .triangles,
            allocator: allocator
        )

        do {
            let mesh = try MTKMesh(mesh: mdlMesh, device: device)
            return mesh
        } catch {
            assertionFailure(error.localizedDescription)
            return nil
        }
    }
    required init() {}
}

class MetalByTutorials04: Scene {
    var name: String { "3 - Metal By Tutorials"}
    var vertexFuncName: String { "metalByTutorials04_vertex" }
    var fragmentFuncName: String { "metalByTutorials04_fragment" }

    var vertices: [simd_float3]? {
        [[0,0,0.5]]
    }
    required init() {}
}

class MetalByTutorials01: Scene {
    var name: String { "1 - Metal By Tutorials"}
    var vertexFuncName: String { "metalByTutorials01_vertex" }
    var fragmentFuncName: String { "metalByTutorials01_fragment" }

    func mesh(device: MTLDevice) -> MTKMesh? {
        let allocator = MTKMeshBufferAllocator(device: device)
        guard let assetURL = Bundle.main.url(forResource: "mushroom", withExtension: "obj") else {
            assertionFailure()
            return nil
        }

        let vertexDesc = MTLVertexDescriptor()
        vertexDesc.attributes[0].format = .float3
        vertexDesc.attributes[0].offset = 0
        vertexDesc.attributes[0].bufferIndex = 0
        vertexDesc.layouts[0].stride = MemoryLayout<SIMD3<Float>>.stride
        let meshDescriptor = MTKModelIOVertexDescriptorFromMetal(vertexDesc)
        (meshDescriptor.attributes[0] as! MDLVertexAttribute).name = MDLVertexAttributePosition
        let asset = MDLAsset(url: assetURL, vertexDescriptor: meshDescriptor, bufferAllocator: allocator)
        let mdlMesh = asset.childObjects(of: MDLMesh.self).first as! MDLMesh

//        let mdlMesh = MDLMesh(sphereWithExtent: [0.75, 0.75, 0.75], segments: [100, 100], inwardNormals: false, geometryType: .triangles, allocator: allocator)
        do {
            let mesh = try MTKMesh(mesh: mdlMesh, device: device)
            return mesh
        } catch {
            assertionFailure(error.localizedDescription)
            return nil
        }
    }
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
