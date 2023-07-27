//
//  06Colors.metal
//  MetalPlayground
//
//  Created by Raheel Ahmad on 7/9/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

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

struct VertexOut {
    float4 pos [[position]];
    float4 color;
};


vertex VertexOut bos_shapes_vertex(const device VertexIn *vertexArray [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexIn in = vertexArray[vid];
    VertexOut out;
    out.pos = float4(in.pos, 0, 1);
    return out;
}

fragment float4 bos_shapes_fragment(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
    float2 st  = {interpolated.pos.x / uniforms.screen_width, 1 - interpolated.pos.y / uniforms.screen_height};

//    st = float2(0.5) - st;
//    st.x *= uniforms.screen_width/uniforms.screen_height;

    float bl = floor(st.x * 10) * step(0.2, st.y);
    float tr = (1 - step(0.9, st.x)) * (1 - step(0.9, st.y));
//    float  = step(0.1, st.x);

    float3 col = bl * tr;

    float4 color = float4(col, 1);
    return color;
}
