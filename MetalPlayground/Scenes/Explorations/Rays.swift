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
struct Rays: Playground {
    var fileName: String {
        "Explorations/Rays"
    }
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


    let cylinderSize: Float = 1

    var modelSize: float3 {
        [0.1,cylinderSize*30,0.1]
    }

    var modelMatrix: float4x4 {
        struct Ray {
            var position: float3
            var direction: float3

            var rotation: float3 {
                let thetaX: Float = -atan2(direction.z, direction.y)
                var thetaZ: Float = atan2(direction.x, direction.y)
                if direction.y < 0 {
                    thetaZ += .pi
                }
                return [thetaX, 0, thetaZ]
            }

            func translation(modelHeight: Float) -> float3 {
                [0, modelHeight/2, 0] // assuming that it's placed at center (0,0,0)
            }

        }

        let ray = Ray(
            position: float3(0, 0, 0),
            direction: float3(raysConfig.modelPosX,raysConfig.modelPosY,raysConfig.modelPosZ)
        )

        let t = float4x4(translation: ray.translation(modelHeight: modelSize.y))
        let r = float4x4(rotation: ray.rotation)
        let s = float4x4(scaling: [
            raysConfig.modelScale, raysConfig.modelScale, raysConfig.modelScale
        ])
        return r * t * s // First translate up and then rotate
    }

    private var decreasingWithTime = false

    mutating func tick(time: Float) {
        let delta: Float = 0.3
        raysConfig.modelPosX += decreasingWithTime ? -delta : delta
        if abs(raysConfig.modelPosX) > 40 {
            decreasingWithTime.toggle()
        }
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
        let mdlMesh = MDLMesh(
            cylinderWithExtent: modelSize, segments: vector_uint2(80,80), inwardNormals: false,
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
