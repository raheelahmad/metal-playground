//
//  PolarExperiments.metal
//  MetalPlayground
//
//  Created by Raheel Ahmad on 8/4/20.
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

vertex VertexOut polar_experiments_vertex(const device VertexIn *vertices [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexOut v;
    v.pos = float4(vertices[vid].pos, 0, 1);
    return v;
}

// ---

float remaps(float a, float b, float c, float d, float t) {
    float val = (t - a) / (b - a) * (d - c) + c;
    return clamp(val, 0.0, 1.0);
}

float2 polar(float2 st) {
    float2 polSt = float2(atan2(st.y, st.x), length(st));
    return polSt;
}


fragment float4 polar_experiments_fragment(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
//    float t = uniforms.time;
    float3 col = {0.7, 0.5, 0.1};

    float2 st = {interpolated.pos.x / uniforms.screen_width, 1 - interpolated.pos.y/uniforms.screen_height};
    st -= 0.5;

    float x = st.x * 2.;
    float m = min(fract(x), fract(1-x));
    float c = smoothstep(0., .1, m - st.y);

    float2 polSt = polar(st);
    float mask = remaps(-M_PI_F, M_PI_F, 0, 1, polSt[0]);
    col *= mask;

    return float4(c);
}
