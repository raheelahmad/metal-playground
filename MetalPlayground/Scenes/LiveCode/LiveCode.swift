//
//  LiveCode.swift
//  MetalPlayground
//
//  Created by Raheel Ahmad on 1/9/21.
//  Copyright © 2021 Raheel Ahmad. All rights reserved.
//

import MetalKit

final class LiveCodeScene: Scene {
    let name = "Live Code"

    let vertexFuncName = "liveCodeVertexShader"
    let fragmentFuncName = "liveCodeFragmentShader"
    private let compileQueue = DispatchQueue.init(label: "Shader compile queue")

    private var shaderContents = ""

    init() { }

    private var device: MTLDevice?
    private var pixelFormat: MTLPixelFormat?

    // TODO: retain cycle?
    private var built: Built?

    func buildPipeline(device: MTLDevice, pixelFormat: MTLPixelFormat, built: @escaping (MTLRenderPipelineState, MTLBuffer) -> ()) {
        self.device = device
        self.pixelFormat = pixelFormat

        beginCopyTimer()
        self.built = built

        compile()
    }

    private var timer: Timer?
    private func beginCopyTimer() {
        let timer = Timer(timeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.compile()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    deinit { timer?.invalidate() }

    private func tick() {
        compileQueue.async {
            self.compile()
        }
    }

    private func compile() {
        let fm = FileManager()
        guard
            let shaderContentsData = fm.contents(atPath: "/Users/raheel/Projects/etc/MetalPlayground/MetalPlayground/Scenes/LiveCode/LiveCode.metal"),
            let shaderContents = String(data: shaderContentsData, encoding: .utf8)
        else {
            assertionFailure()
            return
        }
        let oldValue = self.shaderContents
        self.shaderContents = shaderContents

        guard shaderContents != oldValue else {
            return
        }

        do {

            guard let device = self.device, let pixelFormat = self.pixelFormat else {
                fatalError()
            }


            let pipelineDesc = MTLRenderPipelineDescriptor()
            let library = try device.makeLibrary(source: shaderContents, options: nil)
            pipelineDesc.vertexFunction = library.makeFunction(name: vertexFuncName)
            pipelineDesc.fragmentFunction = library.makeFunction(name: fragmentFuncName)
            pipelineDesc.colorAttachments[0].pixelFormat = pixelFormat

            let pipeline = (try? device.makeRenderPipelineState(descriptor: pipelineDesc))!

            let vertexBuffer = device.makeBuffer(bytes: basicVertices, length: MemoryLayout<Vertex>.stride * basicVertices.count, options: [])
            DispatchQueue.main.async {
                self.built?(pipeline, vertexBuffer!)
            }
        } catch {
            print(error.localizedDescription)
        }
    }

}
