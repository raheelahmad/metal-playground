//
//  BoSShapes.swift
//  MetalPlayground
//
//  Created by Raheel Ahmad on 7/17/23.
//  Copyright © 2023 Raheel Ahmad. All rights reserved.
//

import Foundation
import MetalKit
import SwiftUI

class BoSNoise: Playground {
    var fileName: String {
        "BookShaders/BosNoise"
    }
    var vertexFuncName: String { "bos_noise_vertex" }
    var fragmentFuncName: String { "bos_noise_fragment" }
    required init() {}

    /*
     * Don't need this config yet.
    enum SketchKind: Int, CaseIterable, Identifiable {
        case bezierCurve
        case flowingCurves

        var id: Int { rawValue }

        var name: String {
            switch self {
                case .bezierCurve:
                    return "Bezier Curve"
                case .flowingCurves:
                    return "Flowing Curves"
            }
        }
    }

    class Config: ObservableObject {
        @Published var kind: SketchKind = .bezierCurve
    }

    struct Uniforms {
        let kind: Float
    }

    fileprivate var config: Config = .init()
    var fragmentUniforms: Uniforms {
        .init(kind: Float(config.kind.rawValue))
    }

    func setUniforms(device: MTLDevice, encoder: MTLRenderCommandEncoder) {
        var uniforms = fragmentUniforms
        let length = MemoryLayout.stride(ofValue: uniforms)
        encoder.setFragmentBytes(&uniforms, length: length, index: 1)
    }

    struct ConfigView: View {
        @EnvironmentObject private var config: Config
        @State fileprivate var kind = SketchKind.bezierCurve

        var body: some View {
            VStack(alignment: .leading, spacing: 19) {
                Picker(selection: $config.kind, label: Text("Kind")) {
                    ForEach(SketchKind.allCases) {
                        Text($0.name).tag($0)
                    }
                }
            }
        }
    }

    var view: NSView? {
        NSHostingView(
            rootView: ConfigView().environmentObject(config)
        )
    }
     */
}

