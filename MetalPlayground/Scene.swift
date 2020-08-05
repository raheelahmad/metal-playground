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

    var uniforms: Any? { get }

    var view: NSView? { get }
    func mesh(device: MTLDevice) -> MTKMesh?
}

extension Scene {
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

    func setFragment(device: MTLDevice, encoder: MTLRenderCommandEncoder) {
        guard var uniform = self.uniforms else {
            return
        }
        let length = MemoryLayout.size(ofValue: uniform)
        let uniformsBuffer = device.makeBuffer(bytes: &uniform, length: length, options: [])
        encoder.setFragmentBuffer(uniformsBuffer, offset: 0, index: 1)
    }

    var view: NSView? {
        nil
    }

    func mesh(device: MTLDevice) -> MTKMesh? { nil }
}

var allScenes: [Scene.Type] {
    [
        MetalByTutorials01.self,
        PolarScene.self,
        DomainDistortion.self, RepeatingCircles.self, BasicShaderToy.self, StarField.self, Smiley.self, BookOfShaders05.self, BookOfShaders06.self]
}

class StarFieldConfig: ObservableObject {
    @Published var rotating: Bool = false
    @Published var flying: Bool = true
    @Published var numDepthLayers = 1
    @Published var numDensityLayers = 1
}

let starfieldConfig = StarFieldConfig()

struct StarField: Scene {
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

    var uniforms: Any? {
        starFieldUniforms
    }

    struct ConfigView: View {
        @EnvironmentObject var config: StarFieldConfig

        var body: some View {
            VStack(alignment: .leading) {
                Toggle("Rotating", isOn: $config.rotating)
                Toggle("Flying", isOn: $config.flying)
                Stepper("Depth Layers \(config.numDepthLayers)", value: $config.numDepthLayers, in: 0...10)
                Stepper("Density Layers \(config.numDensityLayers)", value: $config.numDensityLayers, in: 0...10)
                Spacer()
            }
        }
    }

    var view: NSView? {
        NSHostingView(
            rootView: ConfigView().environmentObject(starfieldConfig)
        )
    }
}

struct Smiley: Scene {
    var name: String { "Smiley" }

    var vertexFuncName: String { "shape_vertex" }
    var fragmentFuncName: String { "shaderToySmiley" }
    var uniforms: Any? { nil }
}

struct MetalByTutorials01: Scene {
    var name: String { "1 - Metal By Tutorials"}
    var vertexFuncName: String { "metalByTutorials01_vertex" }
    var fragmentFuncName: String { "metalByTutorials01_fragment" }
    var uniforms: Any? { nil }

    func mesh(device: MTLDevice) -> MTKMesh? {
        let allocator = MTKMeshBufferAllocator(device: device)
        let mdlMesh = MDLMesh(sphereWithExtent: [0.75, 0.75, 0.75], segments: [100, 100], inwardNormals: false, geometryType: .triangles, allocator: allocator)
        do {
            let mesh = try MTKMesh(mesh: mdlMesh, device: device)
            return mesh
        } catch {
            assertionFailure(error.localizedDescription)
            return nil
        }
    }
}

struct PolarScene: Scene {
    var name: String { "Polar Experiments" }

    var vertexFuncName: String { "polar_experiments_vertex" }
    var fragmentFuncName: String { "polar_experiments_fragment" }
    var uniforms: Any? { nil }
}

struct DomainDistortion: Scene {
    var name: String { "Domain Distortion" }

    var vertexFuncName: String { "domain_distortion_vertex" }
    var fragmentFuncName: String { "domain_distortion_fragment" }
    var uniforms: Any? { nil }
}

struct RepeatingCircles: Scene {
    var name: String { "Repeating Circles" }

    var vertexFuncName: String { "repeating_cirlces_vertex" }
    var fragmentFuncName: String { "repeating_circles_fragment" }
    var uniforms: Any? { nil }
}

struct BasicShaderToy: Scene {
    var name: String { "Basic ShaderToy" }

    var vertexFuncName: String { "shape_vertex" }
    var fragmentFuncName: String { "shadertoy01" }
    var uniforms: Any? { nil }
}

struct BookOfShaders05: Scene {
    var name: String { "Book of Shaders 05 - Algorithmic" }

    var vertexFuncName: String { "smoothing_vertex" }
    var fragmentFuncName: String { "smoothing_fragment" }
    var uniforms: Any? { nil }
}

struct BookOfShaders06: Scene {
    var name: String { "Book of Shaders 06 - Colors" }

    var vertexFuncName: String { "color_vertex" }
    var fragmentFuncName: String { "color_fragment" }
    var uniforms: Any? { nil }
}
