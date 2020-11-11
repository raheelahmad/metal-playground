//
//  Sierpinski.swift
//  MetalPlayground
//
//  Created by Raheel Ahmad on 11/10/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

import MetalKit

class Sierpinski: Scene {
    var name: String { "Sierpinski" }
    var vertexFuncName: String { "sierpinski_vertex" }
    var fragmentFuncName: String { "sierpinski_fragment" }
    var mesh: MTKMesh!

    var pointsBuffer: MTLBuffer!

    var pointsCount = 0

    required init() {}

    enum Kind { case points, triangles }

    let kind: Kind = .triangles

    func buildPipeline(device: MTLDevice, pixelFormat: MTLPixelFormat) -> (MTLRenderPipelineState, MTLBuffer) {
        let descriptor = buildBasicPipelineDescriptor(device: device, pixelFormat: pixelFormat)
        descriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(MDLVertexDescriptor.default)
        let pipeline =  (try? device.makeRenderPipelineState(descriptor: descriptor))!

        self.pointsBuffer = sierpinski(device: device)

        return (pipeline, pointsBuffer)
    }

    func sierpinski(device: MTLDevice) -> MTLBuffer {
        switch kind {
        case .points: return sierpinskiPoints(device: device)
        case .triangles: return sierpinskiTriangles(device: device)
        }
    }

    func sierpinskiTriangles(device: MTLDevice) -> MTLBuffer {
        var points: [float3] = []
        func triangle(_ a: float3, _ b: float3, _ c: float3) {
            points += [a,b,c]
        }

        func divideTriangle(a: float3, b: float3, c: float3, count: Int) {
            if count == 0 {
                triangle(a, b, c)
            } else {
                let ab = mix(a, b, t: 0.5);
                let ac = mix(a, c, t: 0.5);
                let bc = mix(b, c, t: 0.5);

                let nextCount = count - 1;

                divideTriangle(a: a, b: ab, c: ac, count: nextCount)
                divideTriangle(a: c, b: ac, c: bc, count: nextCount)
                divideTriangle(a: b, b: bc, c: ab, count: nextCount)
            }
        }

        let vertices: [float3] = [
            [-1.0, -1.0, 0],
            [0.0, 1.0, 0],
            [1.0, -1.0, 0],
        ]

        divideTriangle(a: vertices[0], b: vertices[1], c: vertices[2], count: 9)
        self.pointsCount = points.count
        let buff = device.makeBuffer(bytes: &points, length: MemoryLayout<float3>.stride * points.count, options: [])
        return buff!
    }

    func sierpinskiPoints(device: MTLDevice) -> MTLBuffer {
        // vertices of the outer triangle
        let vertices: [float3] = [
            float3(-1.0, -1.0,  0.0),
            float3(0.0,  1.0,  0.0),
            float3(1.0, -1.0,  0.0),
        ]
        let u = mix(vertices[0], vertices[1], t: 0.5)
        let v = mix(vertices[0], vertices[2], t: 0.5)
        let p = mix(u, v, t: 0.5)

        // points to render
        var points: [float3] = [p]

        for idx in (1..<10000) {
            let j = Int(Float.random(in: 0..<1.0) * 3)
            let m: Float = 0.5
            let p: float3 = mix(points[idx - 1], vertices[j], t: m);
            points.append(p)
        }

        self.pointsCount = points.count

        let mesh = device.makeBuffer(bytes: &points, length: MemoryLayout<float3>.stride * points.count, options: [])
        return mesh!
    }

    func draw(encoder: MTLRenderCommandEncoder) {
        assert(pointsCount > 0)
        switch kind {
        case .points:
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: pointsCount)
        case .triangles:
            encoder.setTriangleFillMode(.fill)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: pointsCount)
        }
    }
}


