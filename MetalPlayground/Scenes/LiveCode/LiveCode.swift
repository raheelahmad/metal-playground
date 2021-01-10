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
    func tearDown() {
    }

    private var device: MTLDevice?
    private var pixelFormat: MTLPixelFormat?

    private var built: Built?

    func buildPipeline(device: MTLDevice, pixelFormat: MTLPixelFormat, built: @escaping (MTLRenderPipelineState, MTLBuffer) -> ()) {
        self.device = device
        self.pixelFormat = pixelFormat

        self.built = built

        compile()
    }

    func tick(time: Float) {
        compileQueue.async {
            self.compile()
        }
    }

    private func compile() {
        let fm = FileManager()
        let filename = #filePath as NSString
        let shaderPath: String = (filename.deletingPathExtension) + ".metal"
        let helpersPath = (filename.deletingLastPathComponent as NSString).deletingLastPathComponent + "/Helpers.metal"
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
