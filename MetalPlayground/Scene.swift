//
//  Scene.swift
//  MetalPlayground
//
//  Created by Raheel Ahmad on 7/26/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

import MetalKit

enum Scene {
    case starField
    case smiley

    var vertexFuncName: String {
        switch self {
        case .starField, .smiley: return "shape_vertex"
        }
    }

    var fragmentFuncName: String {
        switch self {
        case .starField: return "shaderToyStarfield"
        case .smiley: return "shaderToySmiley"
        }
    }

    var uniforms: Any? {
        switch self {
        case .starField: return FragmentUniforms(time: 0.2, screen_width: 21, screen_height: 20, screen_scale: 1, mouseLocation: .one)
        case .smiley: return nil
        }
    }

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
}
