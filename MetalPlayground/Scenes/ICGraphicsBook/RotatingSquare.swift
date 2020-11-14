//
//  RotatingSquare.swift
//  MetalPlayground
//
//  Created by Raheel Ahmad on 11/10/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

import MetalKit

private struct VertexUniforms {
    var angle: Float
}

final class RotatingSquare: Scene {
    var name: String { "Sierpinski" }
    var vertexFuncName: String { "rotate_vertex" }
    var fragmentFuncName: String { "passthrough_fragment" }

    var pointsCount = 0
    private var uniforms = VertexUniforms(angle: 0)

    var pointsBuffer: MTLBuffer!

    func buildPipeline(device: MTLDevice, pixelFormat: MTLPixelFormat) -> (MTLRenderPipelineState, MTLBuffer) {
        let descriptor = buildBasicPipelineDescriptor(device: device, pixelFormat: pixelFormat)
        descriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(MDLVertexDescriptor.default)
        let pipeline =  (try? device.makeRenderPipelineState(descriptor: descriptor))!

        self.pointsBuffer = squarePoints(device: device)

        return (pipeline, pointsBuffer)
    }

    func squarePoints(device: MTLDevice) -> MTLBuffer {
        var vertices: [float3] = [
            [0.0, 1.0, 0],
            [1.0,  0.0, 0],
            [-1.0,  0.0, 0],
            [ 0.0, -1.0, 0],
        ]

        self.pointsCount = vertices.count
        let buff = device.makeBuffer(bytes: &vertices, length: MemoryLayout<float3>.stride * vertices.count, options: [])
        return buff!
    }

    func setUniforms(device: MTLDevice, encoder: MTLRenderCommandEncoder) {
        uniforms.angle += 0.01
        if uniforms.angle > 2 * 3.141 {
            uniforms.angle = 0
        }
        let length = MemoryLayout.stride(ofValue: uniforms)
        encoder.setVertexBytes(&uniforms, length: length, index: 1)
    }

    func draw(encoder: MTLRenderCommandEncoder) {
        encoder.setTriangleFillMode(.lines)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: pointsCount)
    }
}
