//
//  RepeatingCircles.swift
//  MetalPlayground
//
//  Created by Raheel Ahmad on 9/14/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

import MetalKit
import SwiftUI


private class Config: ObservableObject {
    @Published var rotating: Bool = false
    @Published var numRows: Float = 1
    @Published var numPolygons: Float = 1
    @Published var scale: Float = 1
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

private var config = Config()

class RepeatingCircles: Scene {
    struct Uniforms {
        var rotating: Bool
        var numRows: Float
        var numPolygons: Float
        var scale: Float
    }

    var name: String { "Repeating Circles" }

    var fragmentUniforms: Any? {
        Uniforms(rotating: config.rotating, numRows: config.numRows, numPolygons: config.numPolygons, scale: config.scale)
    }

    struct ConfigView: View {
        @EnvironmentObject private var config: Config

        var body: some View {
            VStack(alignment: .leading, spacing: 19) {
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

    var vertexFuncName: String { "repeating_cirlces_vertex" }
    var fragmentFuncName: String { "repeating_circles_fragment" }

    required init() { }
}
