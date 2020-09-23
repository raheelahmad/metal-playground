//
//  Starfield.swift
//  MetalPlayground
//
//  Created by Raheel Ahmad on 9/22/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

import MetalKit
import SwiftUI

class StarField: Scene {
    class StarFieldConfig: ObservableObject {
        @Published var rotating: Bool = false
        @Published var flying: Bool = true
        @Published var numDepthLayers: Float = 1
        @Published var numDensityLayers: Float = 1
    }

    let starfieldConfig = StarFieldConfig()

    struct Uniforms {
        var rotating: Bool
        var flying: Bool
        var numDepthLayers: Float
        var numDensityLayers: Float
    }

    var name: String { "Star Field" }
    var vertexFuncName: String { "shape_vertex" }
    var fragmentFuncName: String { "shaderToyStarfield" }
    var starFieldUniforms: Uniforms {
        Uniforms(rotating: starfieldConfig.rotating, flying: starfieldConfig.flying, numDepthLayers: Float(starfieldConfig.numDepthLayers), numDensityLayers: Float(starfieldConfig.numDensityLayers))
    }

    var fragmentUniforms: Any? {
        starFieldUniforms
    }
    struct ConfigView: View {
        @EnvironmentObject var config: StarFieldConfig

        var body: some View {
            VStack(alignment: .leading, spacing: 19) {
                Toggle("Rotating", isOn: $config.rotating)
                Toggle("Flying", isOn: $config.flying)
                TitledSlider(title: "Depth Layers", value: $config.numDepthLayers, in: 0...10, step: 1) {
                    self.config.numDepthLayers = 1
                }
                TitledSlider(title: "Density Layers", value: $config.numDensityLayers, in: 1...10, step: 1) {
                    self.config.numDensityLayers = 1
                }
            }
        }
    }

    func setUniforms(device: MTLDevice, encoder: MTLRenderCommandEncoder) {
        var uniform = self.starFieldUniforms
        let length = MemoryLayout.size(ofValue: uniform)
        encoder.setFragmentBytes(&uniform, length: length, index: 1)
    }

    var view: NSView? {
        NSHostingView(
            rootView: ConfigView().environmentObject(starfieldConfig)
        )
    }
    required init() {}
}
