//
//  RayMarch.metal
//  MetalPlayground
//
//  Created by Raheel Ahmad on 6/23/23.
//  Copyright © 2023 Raheel Ahmad. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#import <simd/simd.h>

struct VertexIn {
    vector_float2 pos;
};

struct FragmentUniforms {
    float time;
    float screen_width;
    float screen_height;
    float screen_scale;
    float mousePos;
};

struct VertexOut {
    float4 pos [[position]];
    float4 color;
};


vertex VertexOut rayMarchingSimpleVertex(const device VertexIn *vertices [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexOut in;
    in.pos = {vertices[vid].pos.x, vertices[vid].pos.y, 0, 1};
    return in;
}

/// -- Drawing


fragment float4 rayMarchingSimpleFragment(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
    float2 uv = {interpolated.pos.x / uniforms.screen_width, 1 - interpolated.pos.y/uniforms.screen_height};
    uv = 2 * (uv - 0.5);
    float3 color = float3(0);

//    float time = uniforms.time;
//    float2 mouseXY = uniforms.mousePos / float2(5);
//
//    float3 rayOrigin = float3(0, 2.5, -6);
//    float3 rayDirection = normalize(float3(uv.x, uv.y, 1.2));
//    // rotate with mouse
//    rayOrigin.yz = rayOrigin.yz * rotateBy(mouseXY.y * M_PI_F + M_PI_F/1.3);
//    rayOrigin.xz = rayOrigin.xz * rotateBy(-mouseXY.x * M_PI_F - M_PI_F / 1);
//
//    float d = rayMarch(rayOrigin, rayDirection, time);
//    float3 pointAtD = rayOrigin + rayDirection * d;
//    float3 light = getLight(pointAtD, time);
//    float3 color = float3(0.2, 0.8, 0.3) * light;


    return float4(color, 1.0);
}
