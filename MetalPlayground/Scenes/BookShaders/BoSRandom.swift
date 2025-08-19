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

class BoSRandom: Playground {
    var fileName: String {
        "BookShaders/BosRandom"
    }
    var vertexFuncName: String { "bos_random_vertex" }
    var fragmentFuncName: String { "bos_random_fragment" }
    required init() {
        
    }

    enum SketchKind: Int, CaseIterable, Identifiable {
        case randomSquares
        case maze
        case rowVairants

        var id: Int { rawValue }

        var name: String {
            switch self {
            case .randomSquares:
                    return "Random Squares"
                case .maze:
                    return "Maze"
            case .rowVairants:
                return "Row Variants"
            }
        }
    }

    @Observable
    class Config {
        var kind: SketchKind = .randomSquares
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
        @Environment(Config.self) private var config: Config

        var body: some View {
            VStack(alignment: .leading, spacing: 19) {
                Picker(selection: Binding(get: {
                    config.kind
                }, set: {
                    config.kind = $0
                }), label: Text("Kind")) {
                    ForEach(SketchKind.allCases) {
                        Text($0.name).tag($0)
                    }
                }
            }
        }
    }

    var view: AnyView? {
        AnyView(ConfigView().environment(config))
    }
}

