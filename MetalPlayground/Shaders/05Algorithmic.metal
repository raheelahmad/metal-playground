//
//  05Algorithmic.metal
//  MetalPlayground
//
//  Created by Raheel Ahmad on 7/6/20.
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

float plotColor(float2 st, float y) {
    if (abs(st.y - y) <= 0.01) {
        // it's a plot point
        return 1;
    } else {
        return 0;
    }

}

vertex VertexOut smoothing_vertex(const device VertexIn *vertexArray [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexIn in = vertexArray[vid];
    VertexOut out;
    out.pos = float4(in.pos, 0, 1);
    return out;
}

fragment float4 smoothing_fragment(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
    float2 st  = {interpolated.pos.x / uniforms.screen_width, 1 - interpolated.pos.y / uniforms.screen_width};
    float x = st.x * 2*M_PI_F;

    float y = fract(4+sin(x))/8;

    float3 color = plotColor(st, y);

    return vector_float4(color, 1.0);
}


