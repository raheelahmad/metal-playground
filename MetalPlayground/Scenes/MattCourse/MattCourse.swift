//
//  MattCourse.swift
//  MetalPlayground
//
//  Created by Raheel Ahmad on 1/10/21.
//  Copyright © 2021 Raheel Ahmad. All rights reserved.
//

import MetalKit
import SwiftUI

fileprivate enum SketchKind: Int, CaseIterable, Identifiable {
    case one, two

    var id: Int {
        rawValue
    }

    var name: String {
        switch self {
        case .one:
            return "One"
        case .two:
            return "Two"
        }
    }
}

fileprivate class Config: ObservableObject {
    @Published var kind: SketchKind = .one
}

final class MattCourseScene: Scene {
    struct Uniforms {
        let kind: Float
    }

    fileprivate var config: Config = .init()
    var fragmentUniforms: Uniforms {
        .init(kind: Float(config.kind.rawValue))
    }


    let name = "MattCourse"

    let vertexFuncName = "matt_course_vertex"
    let fragmentFuncName = "matt_course_fragment"
    var fileName: String {
        "MattCourse/MattCourse"
    }

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
    }

}

extension MattCourseScene {
    struct ConfigView: View {
        @EnvironmentObject private var config: Config
        @State fileprivate var kind = SketchKind.one

        var body: some View {
            VStack(alignment: .leading, spacing: 19) {
                Picker(selection: $config.kind, label: Text("Pattern")) {
                    ForEach(SketchKind.allCases) {
                        Text($0.name).tag($0)
                    }
                }
            }
        }
    }


    func setUniforms(device: MTLDevice, encoder: MTLRenderCommandEncoder) {
        var uniforms = fragmentUniforms
        let length = MemoryLayout.stride(ofValue: uniforms)
        encoder.setFragmentBytes(&uniforms, length: length, index: 1)
    }

    var view: NSView? {
        NSHostingView(
            rootView: ConfigView().environmentObject(config)
        )
    }
}
