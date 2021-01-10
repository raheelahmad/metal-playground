//
//  ShaderToyDistortions.metal
//  MetalPlayground
//
//  Created by Raheel Ahmad on 8/2/20.
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

vertex VertexOut domain_distortion_vertex(const device VertexIn *vertices [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexOut v;
    v.pos = float4(vertices[vid].pos, 0, 1);
    return v;
}

// ---

float baand(float p, float start, float end, float endsBlur) {
    float m = smoothstep(start - endsBlur, start + endsBlur, p);
    m *= smoothstep(end + endsBlur, end - endsBlur, p);
    float2x2 ma = float2x2(0,1,1,0);
    float3 x = {0};
    float2 mas = x.xz * ma;
    x.xz = mas;
    return m;
}

float rectangle(float2 st, float left, float right, float bottom, float top, float blur) {
    return
    baand(st.x, left, right, blur)
    *
    baand(st.y, bottom, top, blur)
    ;
}

float remapper(float a, float b, float c, float d, float t) {
    float val = (t - a) / (b - a) * (d - c) + c;
    return clamp(val, 0.0, 1.0);
}


fragment float4 domain_distortion_fragment(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
    float t = uniforms.time;
    float2 st = {interpolated.pos.x / uniforms.screen_width, 1 - interpolated.pos.y/uniforms.screen_height};
    st -= 0.5;
    float3 col = {0.7, 0.5, 0.1};

    float x = st.x;
    float m = sin(x*10 + t*2)/10;
    st.y = st.y - m;

    float blur = remapper(-0.5, 0.5, 0, .3, st.x);
    blur *= blur;
    float val = rectangle(st, -.4, .4, -.1, .1, blur);
    col = col * val;
    return float4(col, 1);
}
