//
//  Noise.metal
//  MetalPlayground
//
//  Created by Raheel Ahmad on 5/14/20.
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
};

struct VertexOut {
    float4 pos [[position]];
    float4 color;
};

float randomize(float x) {
    return fract(sin(x) * 10.0);
}


vertex VertexOut noiseVertexShader(const device VertexIn *vertices [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexOut in;
    in.pos = {vertices[vid].pos.x, vertices[vid].pos.y, 0, 1};
    return in;
}

fragment float4 noiseFragmentShader(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
    float x = interpolated.pos.x / uniforms.screen_width;
    float y = interpolated.pos.y / uniforms.screen_height;
    float i = floor(x);
    float f = fract(x);
//    y = randomize(i);
    y = mix(randomize(i), randomize(i + 1), f * f * (3 - 2.0 * f));
    return float4(float3(y), 1);
}
