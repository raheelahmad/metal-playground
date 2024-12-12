//
//  FractAndFriends.metal
//  MetalPlayground
//
//  Created by Raheel Ahmad on 12/6/24.
//  Copyright © 2024 Raheel Ahmad. All rights reserved.
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

vertex VertexOut fract_and_friends_vertex(const device VertexIn *vertexArray [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexIn in = vertexArray[vid];
    VertexOut out;
    out.pos = float4(in.pos, 0, 1);
    return out;
}

fragment float4 fract_and_friends_fragment(VertexOut interpolated [[stage_in]], texture2d<float> baseColorTexture [[texture(10)]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
    float2 st  = {interpolated.pos.x / uniforms.screen_width, 1 - interpolated.pos.y / uniforms.screen_width};

    constexpr sampler textureSampler(filter::nearest, mip_filter::linear, max_anisotropy(8), address::repeat);
    float2 uv = 1 - st;
    float3 baseColor = baseColorTexture.sample(textureSampler, uv).rgb;

    // Background
    float3 color = baseColor;

    float2 pst = (st + uniforms.time * .012) * 400;
    float val = lerp(sin(pst.y), -1,1, 0.2, 1);
    color = mix(blue(), green(), val) * color;

    return vector_float4(color, 1.0);
}


