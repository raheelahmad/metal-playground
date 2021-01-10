//
//  Simplest3D.metal
//  MetalPlayground
//
//  Created by Raheel Ahmad on 9/17/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


struct VertexIn {
    float3 pos [[attribute(0)]];
//    float3 normal [[attribute(1)]];
//    float3 uv [[attribute(2)]];
//
};

struct VertexUniforms {
    float angle;
};

struct FragmentUniforms {
    float time;
    float screen_width;
    float screen_height;
    float screen_scale;
    float2 mousePos;
};

struct VertexOut {
    float4 pos [[position]];
};

vertex VertexOut passthrough_vertex(VertexIn vin [[stage_in]]) {
    VertexOut out;
    out.pos = float4(vin.pos, 1);
    return out;
}

vertex VertexOut rotate_vertex(VertexIn vin [[stage_in]], constant VertexUniforms &uniforms [[buffer(1)]]) {
    VertexOut out;
    float4 pos = float4(vin.pos, 1);
    float thet = uniforms.angle;
    pos.x = -sin(thet) * vin.pos.x + cos(thet) * vin.pos.y;
    pos.y = sin(thet) * vin.pos.y + cos(thet) * vin.pos.x;
    out.pos = pos;
    return out;
}

// ---
fragment float4 passthrough_fragment(VertexOut interpolated [[stage_in]],
                                    constant FragmentUniforms &uniforms [[buffer(0)]]) {
    float3 col = interpolated.pos.xyz;

    return float4(col, 1);
}
