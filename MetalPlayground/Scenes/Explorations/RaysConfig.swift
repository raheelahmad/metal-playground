//
//  RaysConfig.swift
//  MetalPlayground
//
//  Created by Raheel Ahmad on 9/5/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

import SwiftUI
import simd

class RaysConfig: ObservableObject {
    @Published var cameraPosX: Float = 0
    @Published var cameraPosY: Float = 0
    @Published var cameraPosZ: Float = -30
    @Published var cameraRotX: Float = 0
    @Published var cameraRotY: Float = 0
    @Published var cameraRotZ: Float = 0

    @Published var modelPosX: Float = 0
    @Published var modelPosY: Float = 0
    @Published var modelPosZ: Float = 0
    @Published var modelRotX: Float = 0
    @Published var modelRotY: Float = 0
    @Published var modelRotZ: Float = 0

    @Published var modelScale: Float = 1


    func resetModelPos() {
        modelPosX = 0
        modelPosY = 0
        modelPosZ = 0
    }

    func resetModelRot() {
        modelRotX = 0
        modelRotY = 0
        modelRotZ = 0
    }

    func resetModelScale() {
        modelScale = 1
    }

    func resetCameraPos() {
        cameraPosX = 0
        cameraPosY = 0
        cameraPosZ = -30
    }

    func resetCameraRot() {
        cameraRotX = 0
        cameraRotY = 0
        cameraRotZ = 0
    }
}

let raysConfig = RaysConfig()

struct RaysConfigView: View {
    @EnvironmentObject fileprivate var config: RaysConfig

    private var modelPos: some View {
        VStack {
            Text("Model").font(.subheadline)
            Spacer().frame(height: 10)
            HStack {
                Text("Position")
                Button(action: {
                    raysConfig.resetModelPos()
                }, label: { Text("Reset") })
            }
            VStack(spacing: 0) {
                numSlider($config.modelPosX, "x", extent: 40)
                numSlider($config.modelPosY, "y", extent: 40)
                numSlider($config.modelPosZ, "z", extent: 40)
            }
        }
    }

    var modelRot: some View {
        VStack {
            HStack {
                Text("Rotation")
                Button(action: {
                    raysConfig.resetModelRot()
                }, label: { Text("Reset") })
            }
            VStack(spacing: 0) {
                numSlider($config.modelRotX, "x", extent: 3)
                numSlider($config.modelRotY, "y", extent: 3)
                numSlider($config.modelRotZ, "z", extent: 3)
            }
        }
    }

    var modelScale: some View {
        VStack {
            HStack {
                Text("Scale")
                Button(action: {
                    raysConfig.resetModelScale()
                }, label: { Text("Reset") })
            }
            numSlider($config.modelScale, "", extent: 1.0, minExtent: 0)
        }
    }

    var model: some View {
        VStack(spacing: 10) {
            modelPos
            modelRot
            modelScale
        }
    }

    func numSlider(_ binding: Binding<Float>, _ label: String, extent: Float, minExtent: Float? = nil) -> some View {
        HStack {
            Text(label)
            Slider(value: binding, in: (minExtent ?? -extent)...extent)
                .frame(width: 120)
            HStack {
                Spacer()
                Text(String(format: "%.2f", binding.wrappedValue))
            }
        }
    }

    var camera: some View {
        VStack {
            Text("Camera").font(.subheadline)
            Spacer().frame(height: 10)
            HStack {
                Text("Position")
                Button(action: {
                    raysConfig.resetCameraPos()
                }, label: { Text("Reset") })
            }
            VStack(spacing: 0) {
                numSlider($config.cameraPosX, "x", extent: 40)
                numSlider($config.cameraPosY, "y", extent: 40)
                numSlider($config.cameraPosZ, "z", extent: 40)
            }
            Spacer().frame(height: 10)
            HStack {
                Text("Rotation")
                Button(action: {
                    raysConfig.resetCameraRot()
                }, label: { Text("Reset") })
            }
            VStack(spacing: 0) {
                numSlider($config.cameraRotX, "x", extent: 3.14)
                numSlider($config.cameraRotY, "y", extent: 3.14)
                numSlider($config.cameraRotZ, "z", extent: 3.14)
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            camera
            model

            Spacer()
        }
    }
}

