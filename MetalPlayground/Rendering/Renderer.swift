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
    var mouseLocation: vector_float2
}

final class Renderer: NSObject, MTKViewDelegate {
    var mouseLocation: vector_float2 = .init(repeating: 0) {
        didSet {
            uniforms.mouseLocation = vector_float2(mouseLocation.x / uniforms.screen_width, 1 - mouseLocation.y / uniforms.screen_height)
        }
    }
    let device: MTLDevice
    let queue: MTLCommandQueue
    let pixelFormat: MTLPixelFormat = .bgra8Unorm

    static var aspectRatio: Float = 1.0

    var piplelineState: MTLRenderPipelineState!
    private var uniforms: FragmentUniforms = .init(time: 0, screen_width: 0, screen_height: 0, screen_scale: 0, mouseLocation: .init(0,0))

    override init() {
        device = MTLCreateSystemDefaultDevice()!
        queue = device.makeCommandQueue()!

        super.init()
    }

    func setup(_ view: MTKView) {
        view.device = device
        view.colorPixelFormat = pixelFormat
        view.delegate = self
        uniforms.screen_scale = 2
        setupPipeline()
    }

    var lastRenderTime: CFTimeInterval? = nil
    var currentTime: Double = 0
    let gpuLock = DispatchSemaphore(value: 1)

    var scene: Scene = SceneKind.allCases[0].scene {
        didSet {
            setupPipeline()
        }
    }

    var vertexBuffer: MTLBuffer?

    private func setupPipeline() {
        let setup = scene.buildPipeline(device: device, pixelFormat: pixelFormat)

        self.piplelineState = setup.0
        self.vertexBuffer = setup.1
    }

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
        scene.tick(time: Float(currentTime))

        encoder.setRenderPipelineState(piplelineState)

        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

        let uniformsBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout<FragmentUniforms>.size, options: [])
        encoder.setFragmentBuffer(uniformsBuffer, offset: 0, index: 0)
        scene.setUniforms(device: device, encoder: encoder)
        scene.draw(encoder: encoder)

        encoder.endEncoding()
        commandBuffer.present(view.currentDrawable!)
        commandBuffer.commit()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        uniforms.screen_width = Float(size.width)
        uniforms.screen_height = Float(size.height)
        Self.aspectRatio = Float(uniforms.screen_width/uniforms.screen_height)
    }
}
