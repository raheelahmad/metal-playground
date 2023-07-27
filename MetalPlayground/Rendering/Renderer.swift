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
            let x = mouseLocation.x / uniforms.screen_width * 2 - 0.5
            let y = (0.5 - 2 * mouseLocation.y / uniforms.screen_height)
            uniforms.mouseLocation = vector_float2(x, y)
        }
    }
    let device: MTLDevice
    let queue: MTLCommandQueue
    let pixelFormat: MTLPixelFormat = .bgra8Unorm

    static var aspectRatio: Float = 1.0

    private let compileQueue = DispatchQueue.init(label: "Shader compile queue")

    var pipelineState: MTLRenderPipelineState!
    private var uniforms: FragmentUniforms = .init(time: 0, screen_width: 0, screen_height: 0, screen_scale: 0, mouseLocation: .init(0,0))

    override init() {
        device = MTLCreateSystemDefaultDevice()!
        queue = device.makeCommandQueue()!

        super.init()
    }

    func setup(_ view: MTKView) {
        view.device = device
        view.colorPixelFormat = pixelFormat
        view.preferredFramesPerSecond = 30
        view.delegate = self
        uniforms.screen_scale = 2
        setupPipeline()
    }

    var lastRenderTime: CFTimeInterval? = nil
    var currentTime: Double = 0
    let gpuLock = DispatchSemaphore(value: 1)

    var scene: Playground = SceneKind.allCases[0].scene {
        didSet {
            setupPipeline()
        }
    }

    var vertexBuffer: MTLBuffer?

    private func setupPipeline() {
        scene.buildPipeline(device: device, pixelFormat: pixelFormat) { [weak self] pipelineState,vertexBuffer in
            self?.pipelineState = pipelineState
            self?.vertexBuffer = vertexBuffer
        }
    }

    func draw(in view: MTKView) {
        guard let commandBuffer = queue.makeCommandBuffer() else { return }
        guard let passDescriptor = view.currentRenderPassDescriptor else { return }
        guard let pipelineState = self.pipelineState else { return }

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

        compileQueue.async {
            self.compileScenePipeline()
        }

        encoder.setRenderPipelineState(pipelineState)

        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

        let uniformsBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout<FragmentUniforms>.size, options: [])
        encoder.setFragmentBuffer(uniformsBuffer, offset: 0, index: 0)
        scene.setUniforms(device: device, encoder: encoder)

        guard scene.ready else { return }
        scene.draw(encoder: encoder)

        encoder.endEncoding()
        commandBuffer.present(view.currentDrawable!)
        commandBuffer.commit()
    }

    var shaderContents = ""
    func compileScenePipeline() {
        guard scene.liveReloads else { return }
        let fm = FileManager()
        let filePath = scene.filePath as NSString
        let shaderPath: String = filePath.deletingLastPathComponent.appending("/\(scene.fileName).metal")
        let helpersPath = (filePath.deletingLastPathComponent) + "/Helpers.metal"
        guard
            let shaderContentsData = fm.contents(atPath: shaderPath),
            let helpersData = fm.contents(atPath: helpersPath),
            var shaderContents = String(data: shaderContentsData, encoding: .utf8),
            let helperContents = String(data: helpersData, encoding: .utf8)
        else {
            assertionFailure()
            return
        }
        var shaderContentLines = shaderContents.split(separator: "\n")
        if let headerIndex = shaderContentLines.firstIndex(where: { $0 == "#include \"../ShaderHeaders.h\"" }) {
            shaderContentLines.remove(at: headerIndex)

            var headerLines = helperContents.split(separator: "\n")
            if let helperHeaderIndex = headerLines.firstIndex(where: { String($0) == "#include \"ShaderHeaders.h\"" }) {
                headerLines.remove(at: helperHeaderIndex)
            }
            shaderContentLines.insert(contentsOf: headerLines, at: headerIndex)
        }
        shaderContents = shaderContentLines.joined(separator: "\n")

        let oldValue = self.shaderContents
        self.shaderContents = shaderContents

        guard shaderContents != oldValue else {
            return
        }

        do {
            let pipelineDesc = MTLRenderPipelineDescriptor()
            let library = try device.makeLibrary(source: shaderContents, options: nil)
            pipelineDesc.vertexFunction = library.makeFunction(name: scene.vertexFuncName)
            pipelineDesc.fragmentFunction = library.makeFunction(name: scene.fragmentFuncName)
            pipelineDesc.colorAttachments[0].pixelFormat = pixelFormat

            let pipeline = (try? device.makeRenderPipelineState(descriptor: pipelineDesc))!

            let vertexBuffer = device.makeBuffer(bytes: scene.basicVertices, length: MemoryLayout<Vertex>.stride * scene.basicVertices.count, options: [])
            DispatchQueue.main.async {
                self.pipelineState = pipeline
                self.vertexBuffer = vertexBuffer
            }
        } catch {
            print(error.localizedDescription)
        }

    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        uniforms.screen_width = Float(size.width)
        uniforms.screen_height = Float(size.height)
        Self.aspectRatio = Float(uniforms.screen_width/uniforms.screen_height)
    }
}
