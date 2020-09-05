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
    var rotation: float3 = [0, radians_from_degrees(Float(45)),0]
    var scale: float3 = [1,1,1]

    var modelMatrix: float4x4 {
        let t = float4x4(translation: position)
        let r = float4x4(rotation: rotation)
//        let s = float4x4(scaling: scale)
        return t * r
//            * s
    }

    func setUniforms(device: MTLDevice, encoder: MTLRenderCommandEncoder) {
        var u = RaysUniforms(model: modelMatrix, view: viewMatrix, projection: projectionMatrix)

        let length = MemoryLayout.stride(ofValue: u)
        encoder.setVertexBytes(&u, length: length, index: 1)
    }

    var cameraPos: float3 = [0.0, 0, -3]

    var viewMatrix: float4x4 {
        let t = float4x4(translation: cameraPos)

        return t.inverse
    }

    func mesh(device: MTLDevice) -> MTKMesh? {
        let allocator = MTKMeshBufferAllocator(device: device)
        let size: Float = 1
        let mdlMesh = MDLMesh(
            capsuleWithExtent: [size,size,size],
            cylinderSegments: vector_uint2(20,20),
            hemisphereSegments: 30, inwardNormals: false,
            geometryType: .triangles,
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
        nil
//        NSHostingView(rootView: <#T##_#>)
    }
}
