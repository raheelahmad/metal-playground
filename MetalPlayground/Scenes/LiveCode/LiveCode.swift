//
//  LiveCode.swift
//  MetalPlayground
//
//  Created by Raheel Ahmad on 1/9/21.
//  Copyright © 2021 Raheel Ahmad. All rights reserved.
//

import MetalKit
import SwiftUI

fileprivate class Config: ObservableObject {
    @Published var fullDurationMinutes: Float = 15
    @Published var startTime: Float = 0

    init() {
        regenerate()
    }

    func regenerate() {
        let timeInterval = Date().addingTimeInterval(Double.random(in: -10000..<10000)).timeIntervalSince1970
        startTime = Float(timeInterval)
    }
}


final class LiveCodeScene: Scene {
    enum StampKind: Int {
        case flower = 1
    }

    // Uniforms for the stamp
    struct Uniforms {
        var stamp: Float
        var startTime: Float
        var fullDuration: Float
        var progress: Float
    }

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
    private var config = Config()

    private var uniforms = Uniforms(
        stamp: Float(StampKind.flower.rawValue),
        startTime: Float(Date().timeIntervalSince1970),
        fullDuration: Float(25 * 60 ),
        progress: 0.0
    )

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

        uniforms = Uniforms(
            stamp: Float(StampKind.flower.rawValue),
            startTime: config.startTime,
            fullDuration: config.fullDurationMinutes * 60,
            progress: simd_fract(time/10)
        )
    }

    func setUniforms(device: MTLDevice, encoder: MTLRenderCommandEncoder) {
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
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

    struct ConfigView: View {
        @EnvironmentObject private var config: Config

        var body: some View {
            VStack(alignment: .leading, spacing: 19) {
                TitledSlider(title: "Full Duration", value: $config.fullDurationMinutes, in: 10...60, step: 1) {
                    self.config.fullDurationMinutes = 15
                }
                VStack {
                    Button(action: { config.regenerate() }) {
                        Text("Regenerate Start Time")
                    }

                    Text(config.startTime.str)
                }

//                TitledSlider(title: "Polygons", value: $config.numPolygons, in: 1...10, step: 1) {
//                    self.config.numPolygons = 1
//                }
//                TitledSlider(title: "Scale", value: $config.scale, in: 0.1...4.0) {
//                    self.config.scale = 1
//                }
            }
        }
    }

    var view: NSView? {
        NSHostingView(rootView: ConfigView().environmentObject(config))
    }
}
