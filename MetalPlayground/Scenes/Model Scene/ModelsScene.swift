//
//  ModelsScene.swift
//  MetalPlayground
//
//  Created by Raheel Ahmad on 9/22/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

import MetalKit

final class ModelsScene: Scene {
    var name: String { "Models" }
    var vertexFuncName: String { "models_vertex" }
    var fragmentFuncName: String { "models_fragment" }

    var mesh: MTKMesh!
}

// MARK: Drawing
extension ModelsScene {
    func draw(encoder: MTLRenderCommandEncoder) {
        encoder.setTriangleFillMode(.lines)
        for submesh in mesh.submeshes {
            encoder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: submesh.indexBuffer.offset)
        }
    }
}

// MARK: Pipeline
extension ModelsScene {
    func buildPipeline(device: MTLDevice, pixelFormat: MTLPixelFormat, built: @escaping (MTLRenderPipelineState, MTLBuffer) -> ()) {
        let descriptor = buildBasicPipelineDescriptor(device: device, pixelFormat: pixelFormat)
        let mesh = self.mesh(device: device)!
        descriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mesh.vertexDescriptor)
        let pipeline =  (try? device.makeRenderPipelineState(descriptor: descriptor))!

        let vertexBuffer = mesh.vertexBuffers[0].buffer

        // let's set up the mesh so we don't recreate it in draw()
        self.mesh = mesh

        built(pipeline, vertexBuffer)
    }

    func mesh(device: MTLDevice) -> MTKMesh? {
        let allocator = MTKMeshBufferAllocator(device: device)
        guard let assetURL = Bundle.main.url(forResource: "train", withExtension: "obj") else {
            assertionFailure()
            return nil
        }

        let vertexDesc = MTLVertexDescriptor()
        vertexDesc.attributes[0].format = .float3
        vertexDesc.attributes[0].offset = 0
        vertexDesc.attributes[0].bufferIndex = 0
        vertexDesc.layouts[0].stride = MemoryLayout<SIMD3<Float>>.stride
        let meshDescriptor = MTKModelIOVertexDescriptorFromMetal(vertexDesc)
        (meshDescriptor.attributes[0] as! MDLVertexAttribute).name = MDLVertexAttributePosition
        let asset = MDLAsset(url: assetURL, vertexDescriptor: meshDescriptor, bufferAllocator: allocator)
        let mdlMesh = asset.childObjects(of: MDLMesh.self).first as! MDLMesh

        do {
            let mesh = try MTKMesh(mesh: mdlMesh, device: device)
            return mesh
        } catch {
            assertionFailure(error.localizedDescription)
            return nil
        }
    }
}
