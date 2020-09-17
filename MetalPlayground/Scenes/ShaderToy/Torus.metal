//
//  Torus.metal
//  MetalPlayground
//
//  Created by Raheel Ahmad on 9/2/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


struct VertexOut {
    float4 pos [[position]];
    float4 color;
};

struct VertexIn {
    vector_float2 pos;
};


struct FragmentUniforms {
    float time;
    float screen_width;
    float screen_height;
    float screen_scale;
    float2 mousePos;
};

vertex VertexOut torus_vertex(const device VertexIn *vertices [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexOut v;
    v.pos = float4(vertices[vid].pos, 0, 1);
    return v;
}

// ---
fragment float4 torus_fragment(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
    float3 col = {0.7, 0.5, 0.1};

    return float4(col, 1);
}
