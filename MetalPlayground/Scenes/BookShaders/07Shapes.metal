//
//  06Colors.metal
//  MetalPlayground
//
//  Created by Raheel Ahmad on 7/9/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
#include "../ShaderHeaders.h"

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

float3 hash32(float2 p) {
    float3 p3 = fract(float3(p.xyx) * float3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+33.33);
    return fract((p3.xxy+p3.yzz)*p3.zyx);
}

float rectangle(float2 st, float width) {
    float bl = step(width, st.x) * step(width, st.y);
    float tr = (1 - step((1 - width), st.x)) * (1 - step((1 - width), st.y));
    return bl * tr;
}

float3 circle(float2 st, float time) {
//    st = 4 * (st + 0.5);
//    st = fract(st) - 0.5;
    float t = min(length(st), length(st - 0.3));
    float r = 0.5 * absSin(time);
    return smoothstep(r - 0.02, r, t);
}

fragment float4 bos_shapes_fragment(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
    float3 red = float3(0.8, 0.2, 0.1);
    float3 green = float3(0.4, 0.7, 0.1);
    float2 st  = {interpolated.pos.x / uniforms.screen_width, 1 - interpolated.pos.y / uniforms.screen_height};
//    st = float2(0.5) - st;

    st.x *= uniforms.screen_width/uniforms.screen_height;

    st = 2 * st - 1;

    float l = length(float2(0.3) - abs(st));
    float pct = step(0.5, l);
    pct = fract(l * 10);

    float3 col = green * pct;

    float4 color = float4(col, 1);
    return color;
}
