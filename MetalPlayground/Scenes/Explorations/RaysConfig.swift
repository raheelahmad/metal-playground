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
    @Published var cameraPosZ: Float = -3
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
        modelPosZ = -3
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
        cameraPosZ = -3
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
                HStack {
                    Text("x")
                    Slider(value: $config.modelPosX, in: Float(-20.0)...Float(20.0))
                        .frame(minWidth: 120)
                }
                HStack {
                    Text("y")
                    Slider(value: $config.modelPosY, in: Float(-20.0)...Float(20.0))
                }
                HStack {
                    Text("z")
                    Slider(value: $config.modelPosZ, in: Float(-20.0)...Float(20.0))
                }
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
                HStack {
                    Text("x")
                    Slider(value: $config.modelRotX, in: Float(-3.0)...Float(3.0))
                        .frame(minWidth: 120)
                }
                HStack {
                    Text("y")
                    Slider(value: $config.modelRotY, in: Float(-3.0)...Float(3.0))
                }
                HStack {
                    Text("z")
                    Slider(value: $config.modelRotZ, in: Float(-3.0)...Float(3.0))
                }
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
            VStack(spacing: 0) {
                Slider(value: $config.modelScale, in: Float(0.0)...Float(1.0))
                    .frame(minWidth: 120)
            }
        }
    }

    var model: some View {
        VStack(spacing: 10) {
            modelPos
            modelRot
            modelScale
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
                HStack {
                    Text("x")
                    Slider(value: $config.cameraPosX, in: Float(-20.0)...Float(20.0))
                        .frame(minWidth: 120)
                }
                HStack {
                    Text("y")
                    Slider(value: $config.cameraPosY, in: Float(-20.0)...Float(20.0))
                }
                HStack {
                    Text("z")
                    Slider(value: $config.cameraPosZ, in: Float(-20.0)...Float(20.0))
                }
            }
            Spacer().frame(height: 10)
            HStack {
                Text("Rotation")
                Button(action: {
                    raysConfig.resetCameraRot()
                }, label: { Text("Reset") })
            }
            VStack(spacing: 0) {
                HStack {
                    Text("x")
                    Slider(value: $config.cameraRotX, in: Float(-3.0)...Float(3.0))
                        .frame(minWidth: 120)
                }
                HStack {
                    Text("y")
                    Slider(value: $config.cameraRotY, in: Float(-3.0)...Float(3.0))
                }
                HStack {
                    Text("z")
                    Slider(value: $config.cameraRotZ, in: Float(-3.0)...Float(3.0))
                }
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

