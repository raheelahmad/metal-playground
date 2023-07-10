//
//  Girih.swift
//  MetalPlayground
//
//  Created by Raheel Ahmad on 9/14/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

import MetalKit
import SwiftUI


fileprivate class Config: ObservableObject {
    enum Pattern: Int, CaseIterable, Identifiable {
        case firstThingsFirst
        case sixesInterpolated
        var name: String {
            switch self {
            case .firstThingsFirst:
                return "First Things First"
            case .sixesInterpolated:
                return "Sixes Interpolated"
            }
        }
        var id: Int {
            rawValue
        }
    }

    @Published var rotating: Bool = false
    @Published var numRows: Float = 1
    @Published var numPolygons: Float = 1
    @Published var scale: Float = 1
    @Published var pattern: Pattern = .firstThingsFirst
}

let nf: NumberFormatter = {
    let f = NumberFormatter()
    f.maximumFractionDigits = 2
    f.minimumFractionDigits = 2
    return f
}()
extension Float {
    var str: String {
        nf.string(from: NSNumber(value: self))!
    }
}


class Girih: Scene {
    struct Uniforms {
        var patternKind: Float
        var rotating: Bool
        var numRows: Float
        var numPolygons: Float
        var scale: Float
    }

    var name: String { "Girih" }
    var fileName: String {
        "Explorations/Girih"
    }
    private var config = Config()

    var fragmentUniforms: Any? {
        Uniforms(patternKind: Float(config.pattern.rawValue), rotating: config.rotating, numRows: config.numRows, numPolygons: config.numPolygons, scale: config.scale)
    }

    struct ConfigView: View {
        @EnvironmentObject private var config: Config
        @State fileprivate var kind = Config.Pattern.firstThingsFirst

        var body: some View {
            VStack(alignment: .leading, spacing: 19) {
                Picker(selection: $config.pattern, label: Text("Pattern")) {
                    ForEach(Config.Pattern.allCases) {
                        Text($0.name).tag($0)
                    }
                }
                Toggle("Rotating", isOn: $config.rotating)
                TitledSlider(title: "Rows", value: $config.numRows, in: 1...10, step: 1) {
                    self.config.numRows = 1
                }

                TitledSlider(title: "Polygons", value: $config.numPolygons, in: 1...10, step: 1) {
                    self.config.numPolygons = 1
                }
                TitledSlider(title: "Scale", value: $config.scale, in: 0.1...4.0) {
                    self.config.scale = 1
                }
            }
        }
    }

    func setUniforms(device: MTLDevice, encoder: MTLRenderCommandEncoder) {
        guard var uniforms = self.fragmentUniforms else {
            return
        }

        let length = MemoryLayout.stride(ofValue: uniforms)
        encoder.setFragmentBytes(&uniforms, length: length, index: 1)
    }


    var view: NSView? {
        NSHostingView(
            rootView: ConfigView().environmentObject(config)
        )
    }

    var vertexFuncName: String { "girih_vertex" }
    var fragmentFuncName: String { "girih_fragment" }

    required init() { }
}
