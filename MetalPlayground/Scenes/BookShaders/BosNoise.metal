//
//  06Colors.metal
//  MetalPlayground
//
//  Created by Raheel Ahmad on 7/9/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

#include <metal_stdlib>
#include "../ShaderHeaders.h"
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

vertex VertexOut bos_noise_vertex(const device VertexIn *vertexArray [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexIn in = vertexArray[vid];
    VertexOut out;
    out.pos = float4(in.pos, 0, 1);
    return out;
}

float box(float2 _st, float2 _size){
    _size = float2(0.5) - _size*0.5;
    float2 uv = smoothstep(_size,
                         _size+float2(0.001),
                         _st);
    uv *= smoothstep(_size,
                     _size+float2(0.001),
                     float2(1.0)-_st);
    return uv.x*uv.y;
}

float rand(float n) {
    return fract(sin(n) * 43758.5453123); // pseudo-random generator
}

float noise1D(float x) {
    float i = floor(x);
    float f = fract(x);

    float a = rand(i);
    float b = rand(i + 1.0);
    float t = mix(a, b, smoothstep(0, 1, f));
    return t;
  }

fragment float4 bos_noise_fragment(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
    float time = uniforms.time;
    float2 st  = {interpolated.pos.x / uniforms.screen_width, interpolated.pos.y / uniforms.screen_height};

    st.x *= uniforms.screen_width/uniforms.screen_height;

    st *= 10;

    float2 translate = float2((1 + sin(time * noise1D(ceil(st.x) * ceil(st.y))))/2) * 0.47;
    float2x2 roation = rotate(time/4 * noise1D(ceil(st.y)));

    st = fract(st);
    st *= roation;
    st += translate;

    float3 col = box(st, float2(0.3, 0.3));
    float4 color = float4(col, 1);
    return color;
}
