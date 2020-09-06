//
//  Rays.swift
//  MetalPlayground
//
//  Created by Raheel Ahmad on 9/2/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

import MetalKit
import SwiftUI

struct RaysUniforms {
    var model: matrix_float4x4
    var view: matrix_float4x4
    var projection: matrix_float4x4
}

private class RaysConfig: ObservableObject {
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

private let raysConfig = RaysConfig()

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

struct Rays: Scene {
    var name: String { "Rays" }
    var vertexFuncName: String { "rays_vertex" }
    var fragmentFuncName: String { "rays_fragment" }
    var fragmentUniforms: Any? { nil }

    var fieldOfView: Float = 70
    var nearZ: Float = 0.001
    var farZ: Float = 100.0

    var projectionMatrix: float4x4 {
        float4x4(
            perspectiveProjectionRHFovY: radians_from_degrees(fieldOfView),
            aspectRatio: Renderer.aspectRatio,
            nearZ: nearZ,
            farZ: farZ
        )
    }

    var vertexUniforms: (Any, Int)? {
        let u = RaysUniforms(model: modelMatrix, view: viewMatrix, projection: projectionMatrix)
        return (u, MemoryLayout<RaysUniforms>.stride)
    }

    var position: float3 = [0,0.3,0]
    var rotation: float3 = [0, radians_from_degrees(Float(0)),0]
    var scale: float3 = [1,1,1]

    var modelMatrix: float4x4 {
        let t = float4x4(translation: [raysConfig.modelPosX, raysConfig.modelPosY, raysConfig.modelPosZ])
        let r = float4x4(rotation: [raysConfig.modelRotX, raysConfig.modelRotY, raysConfig.modelRotZ])
        let s = float4x4(scaling: [raysConfig.modelScale, raysConfig.modelScale, raysConfig.modelScale])
        return t * r * s
    }

    func setUniforms(device: MTLDevice, encoder: MTLRenderCommandEncoder) {
        var u = RaysUniforms(model: modelMatrix, view: viewMatrix, projection: projectionMatrix)

        let length = MemoryLayout.stride(ofValue: u)
        encoder.setVertexBytes(&u, length: length, index: 1)
    }

    var viewMatrix: float4x4 {
        let t = float4x4(translation: [raysConfig.cameraPosX, raysConfig.cameraPosY, raysConfig.cameraPosZ])
        let r = float4x4(rotation: [raysConfig.cameraRotX, raysConfig.cameraRotY, raysConfig.cameraRotZ])

        let mat = t * r

        return mat.inverse
    }

    func mesh(device: MTLDevice) -> MTKMesh? {
        let allocator = MTKMeshBufferAllocator(device: device)
        let size: Float = 1
        let mdlMesh = MDLMesh(
            cylinderWithExtent: [size,size*10,size], segments: vector_uint2(80,80), inwardNormals: false,
            topCap: false, bottomCap: false, geometryType: .triangles,
            allocator: allocator
        )
        do {
            return try MTKMesh(mesh: mdlMesh, device: device)
        } catch {
            assertionFailure(error.localizedDescription)
            return nil
        }
    }

    var view: NSView? {
        NSHostingView(rootView: RaysConfigView().environmentObject(raysConfig))
    }
}

struct Rays_Previews: PreviewProvider {
    static var previews: some View {
        RaysConfigView().environmentObject(raysConfig)
    }
}
