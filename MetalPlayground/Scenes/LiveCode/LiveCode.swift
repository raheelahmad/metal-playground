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
    @Published var fullDurationMinutes: Int = 15
    @Published var hourOfDay: Int = 0
    @Published var speed: Float = 20
}


final class LiveCodeScene: Scene {
    // Uniforms for the stamp
    struct Uniforms {
        var stamp: Float
        var hourOfDay: Float
        var fullDurationMinutes: Float
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
        hourOfDay: 2,
        fullDurationMinutes: Float(25),
        progress: 100
    )

    func buildPipeline(device: MTLDevice, pixelFormat: MTLPixelFormat, built: @escaping (MTLRenderPipelineState, MTLBuffer) -> ()) {
        self.device = device
        self.pixelFormat = pixelFormat

        self.built = built

        compile()
    }

    var progresses: [Float] = []
    func tick(time: Float) {
        compileQueue.async {
            self.compile()
        }

        uniforms = Uniforms(
            stamp: Float(StampKind.flower.rawValue),
            hourOfDay: Float(config.hourOfDay),
            fullDurationMinutes: Float(config.fullDurationMinutes),
            progress: simd_fract(time/config.speed)
        )

        progresses.append(uniforms.progress)

        if progresses.count % 50 == 0 {
            for p in progresses { print(p) }
            progresses.removeAll()
        }
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

        // Remove ShaderHeaders, and include the new contents
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
                Picker(selection: $config.fullDurationMinutes, label: Text("Full Duration")) {
                    Text("15").tag(15)
                    Text("30").tag(30)
                    Text("45").tag(45)
                    Text("60").tag(60)
                }
                .pickerStyle(RadioGroupPickerStyle())
                Slider(
                    value: $config.speed, in: 1...100.0,
                    onEditingChanged: { _ in },
                    label: {
                        Text("Speed")
                    })
                Picker(selection: $config.hourOfDay, label: Text("Hour of Day")) {
                    ForEach(0..<24) {  fl in
                        Text("\(fl)").tag(fl)
                    }
                }
            }
        }
    }

    var view: NSView? {
        NSHostingView(rootView: ConfigView().environmentObject(config))
    }
}
