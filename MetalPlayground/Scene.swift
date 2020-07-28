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
}

extension Scene {
    func buildPipeline(device: MTLDevice, pixelFormat: MTLPixelFormat) -> MTLRenderPipelineState {
        let pipelineDesc = MTLRenderPipelineDescriptor()
        let library = device.makeDefaultLibrary()
        pipelineDesc.vertexFunction = library?.makeFunction(name: vertexFuncName)
        pipelineDesc.fragmentFunction = library?.makeFunction(name: fragmentFuncName)
        pipelineDesc.colorAttachments[0].pixelFormat = pixelFormat
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
}

var allScenes: [Scene.Type] {
    [StarField.self, Smiley.self, BasicShaderToy.self, BookOfShaders05.self, BookOfShaders06.self]
}

class StarFieldConfig: ObservableObject {
    @Published var rotating: Bool = false
    @Published var numDepthLayers = 1
}

let starfieldConfig = StarFieldConfig()

struct StarField: Scene {

    struct Uniforms {
        var rotating: Bool
        var numDepthLayers: Float
    }

    var name: String { "Star Field" }
    var vertexFuncName: String { "shape_vertex" }
    var fragmentFuncName: String { "shaderToyStarfield" }
    var starFieldUniforms: Uniforms {
        Uniforms(rotating: starfieldConfig.rotating, numDepthLayers: Float(starfieldConfig.numDepthLayers))
    }

    var uniforms: Any? {
        starFieldUniforms
    }

    struct ConfigView: View {

        @EnvironmentObject var config: StarFieldConfig

        var body: some View {
            VStack {
                Toggle("Rotating", isOn: $config.rotating)
                Stepper("Depth Layers \(config.numDepthLayers)", value: $config.numDepthLayers, in: 0...5)
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
