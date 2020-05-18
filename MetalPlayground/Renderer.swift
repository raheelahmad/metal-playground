//
//  Renderer.swift
//  MetalPlayground
//
//  Created by Raheel Ahmad on 5/11/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

import Metal
import MetalKit

struct Vertex {
    var position: vector_float2;
}

struct FragmentUniforms {
    var time: Float
    var screen_width: Float
    var screen_height: Float
    var screen_scale: Float
}

final class Renderer: NSObject, MTKViewDelegate {
    let device: MTLDevice
    let queue: MTLCommandQueue
    var piplelineState: MTLRenderPipelineState!
    private var uniforms: FragmentUniforms = .init(time: 0, screen_width: 0, screen_height: 0, screen_scale: 0)

    override init() {
        device = MTLCreateSystemDefaultDevice()!
        queue = device.makeCommandQueue()!

        super.init()
    }

    func setup(_ view: MTKView) {
        view.device = device
        view.colorPixelFormat = .bgra8Unorm
        view.delegate = self
        piplelineState = Self.buildPipeleiine(device: device, view: view)
        uniforms.screen_scale = 2
    }

    var lastRenderTime: CFTimeInterval? = nil
    var currentTime: Double = 0
    let gpuLock = DispatchSemaphore(value: 1)

    func draw(in view: MTKView) {
        guard let commandBuffer = queue.makeCommandBuffer() else { return }
        guard let passDescriptor = view.currentRenderPassDescriptor else { return }

        if lastRenderTime == nil, var frame = view.window?.frame {
            frame.size = .init(width: 500, height: 500)
            view.window?.setFrame(frame, display: true, animate: false)
        }

        // update time
        let systemTime = CACurrentMediaTime()
        let timeDiff = lastRenderTime.map { systemTime - $0 } ?? 0
        currentTime += timeDiff
        lastRenderTime = systemTime

        uniforms.time = Float(currentTime)

        passDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.3, green: 0.3, blue: 0.4, alpha: 1)
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor) else { return }

        let vertexBuffer = device.makeBuffer(bytes: vertices, length: MemoryLayout<Vertex>.stride * vertices.count, options: [])
        encoder.setRenderPipelineState(piplelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        let uniformsBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout<FragmentUniforms>.size, options: [])
        encoder.setFragmentBuffer(uniformsBuffer, offset: 0, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)

        encoder.endEncoding()
        commandBuffer.present(view.currentDrawable!)
        commandBuffer.commit()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        uniforms.screen_width = Float(size.width)
        uniforms.screen_height = Float(size.height)

    }

    private static func buildPipeleiine(device: MTLDevice, view: MTKView) -> MTLRenderPipelineState {
        let pipelineDesc = MTLRenderPipelineDescriptor()
        let library = device.makeDefaultLibrary()
        pipelineDesc.vertexFunction = library?.makeFunction(name: "cellularVertexShader")
        pipelineDesc.fragmentFunction = library?.makeFunction(name: "tileFragmentShader")
        pipelineDesc.colorAttachments[0].pixelFormat = view.colorPixelFormat
        return (try? device.makeRenderPipelineState(descriptor: pipelineDesc))!
    }

    private var vertices: [Vertex] = [
        Vertex(position: [-1, -1]),
        Vertex(position: [-1, 1]),
        Vertex(position: [1, 1]),

        Vertex(position: [-1, -1]),
        Vertex(position: [1, 1]),
        Vertex(position: [1, -1]),
    ]

//    Vertex(position: [-1, -1], color: [Float((0...1).randomElement()!), 0.2, 0.3, 1]),
//    Vertex(position: [-1, 1], color: [Float((0...1).randomElement()!), 0.2, 0.3, 1]),
//    Vertex(position: [1, 1], color: [Float((0...1).randomElement()!), 0.2, 0.3, 1]),
//
//    Vertex(position: [-1, -1], color: [Float((0...1).randomElement()!), 0.2, 0.3, 1]),
//    Vertex(position: [1, 1], color: [Float((0...1).randomElement()!), 0.2, 0.3, 1]),
//    Vertex(position: [1, -1], color: [Float((0...1).randomElement()!), 0.2, 0.3, 1]),
//    ]
}
