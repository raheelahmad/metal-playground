//
//  MathUtils.swift
//  MetalByTutorialsScratch
//
//  Created by Raheel Ahmad on 8/23/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

import Foundation
import simd
typealias float3 = SIMD3<Float>
typealias float4 = SIMD4<Float>

extension float4 {
    init(_ v: float3, _ w: Float) {
        self.init(x: v.x, y: v.y, z: v.z, w: w)
    }

    // RGB color from HSV color (all parameters in range [0, 1])
    init(hue: Float, saturation: Float, brightness: Float) {
        let c = brightness * saturation
        let x = c * (1 - fabsf(fmodf(hue * 6, 2) - 1))
        let m = brightness - saturation

        var r: Float = 0
        var g: Float = 0
        var b: Float = 0
        switch hue {
        case _ where hue < 0.16667:
            r = c; g = x; b = 0
        case _ where hue < 0.33333:
            r = x; g = c; b = 0
        case _ where hue < 0.5:
            r = 0; g = c; b = x
        case _ where hue < 0.66667:
            r = 0; g = x; b = c
        case _ where hue < 0.83333:
            r = x; g = 0; b = c
        case _ where hue <= 1.0:
            r = c; g = 0; b = x
        default:
            break
        }

        r += m; g += m; b += m
        self.init(x: r, y: g, z: b, w: 1)
    }

    var xyz: float3 {
        return float3(x, y, z)
    }
}

extension float4x4 {
    // MARK:- Translate
    init(translation: float3) {
        let matrix = float4x4(
            [            1,             0,             0, 0],
            [            0,             1,             0, 0],
            [            0,             0,             1, 0],
            [translation.x, translation.y, translation.z, 1]
        )
        self = matrix
    }

    // MARK:- Scale
    init(scaling: float3) {
        let matrix = float4x4(
            [scaling.x,         0,         0, 0],
            [        0, scaling.y,         0, 0],
            [        0,         0, scaling.z, 0],
            [        0,         0,         0, 1]
        )
        self = matrix
    }

    init(scaling: Float) {
        self = matrix_identity_float4x4
        columns.3.w = 1 / scaling
    }

    // MARK:- Rotate
    init(rotationX angle: Float) {
        let matrix = float4x4(
            [1,           0,          0, 0],
            [0,  cos(angle), sin(angle), 0],
            [0, -sin(angle), cos(angle), 0],
            [0,           0,          0, 1]
        )
        self = matrix
    }

    init(rotationY angle: Float) {
        let matrix = float4x4(
            [cos(angle), 0, -sin(angle), 0],
            [         0, 1,           0, 0],
            [sin(angle), 0,  cos(angle), 0],
            [         0, 0,           0, 1]
        )
        self = matrix
    }

    init(rotationZ angle: Float) {
        let matrix = float4x4(
            [ cos(angle), sin(angle), 0, 0],
            [-sin(angle), cos(angle), 0, 0],
            [          0,          0, 1, 0],
            [          0,          0, 0, 1]
        )
        self = matrix
    }

    init(rotation angle: float3) {
        let rotationX = float4x4(rotationX: angle.x)
        let rotationY = float4x4(rotationY: angle.y)
        let rotationZ = float4x4(rotationZ: angle.z)
        self = rotationX * rotationY * rotationZ
    }


    init(rotationAroundAxis axis: float3, by angle: Float) {
        let unitAxis = normalize(axis)
        let ct = cosf(angle)
        let st = sinf(angle)
        let ci = 1 - ct
        let x = unitAxis.x, y = unitAxis.y, z = unitAxis.z
        self.init(columns:(float4(    ct + x * x * ci, y * x * ci + z * st, z * x * ci - y * st, 0),
                           float4(x * y * ci - z * st,     ct + y * y * ci, z * y * ci + x * st, 0),
                           float4(x * z * ci + y * st, y * z * ci - x * st,     ct + z * z * ci, 0),
                           float4(                  0,                   0,                   0, 1)))
    }

    init(translationBy v: float3) {
        self.init(columns:(float4(1, 0, 0, 0),
                           float4(0, 1, 0, 0),
                           float4(0, 0, 1, 0),
                           float4(v.x, v.y, v.z, 1)))
    }

    var upperLeft: float3x3 {
        let x = columns.0.xyz
        let y = columns.1.xyz
        let z = columns.2.xyz
        return float3x3(columns: (x, y, z))
    }

    init(perspectiveProjectionRHFovY fovy: Float, aspectRatio: Float, nearZ: Float, farZ: Float, lhs: Bool = true) {
        let ys = 1 / tanf(fovy * 0.5)
        let xs = ys / aspectRatio
        let zs = lhs ? farZ / (farZ - nearZ) : farZ / (nearZ - farZ)
        let X = float4( xs,  0,  0,  0)
        let Y = float4( 0,  ys,  0,  0)
        let Z = lhs ? float4( 0,  0,  zs, 1) : float4( 0,  0,  zs, -1)
        let W = lhs ? float4( 0,  0,  zs * -nearZ,  0) : float4( 0,  0,  zs * nearZ,  0)
        self.init()
        columns = (X,Y,Z,W)
    }
}

func radians_from_degrees(_ degrees: Float) -> Float {
    return (degrees / 180) * .pi
}
