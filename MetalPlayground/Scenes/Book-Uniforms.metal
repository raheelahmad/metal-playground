//
//  Book-Metal.metal
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

vertex VertexOut vertexUniformShader(const device VertexIn *vertexArray [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexIn in = vertexArray[vid];
    VertexOut out;
    out.pos = float4(in.pos, 0, 1);
    return out;
}

fragment float4 fragmentUniformShader(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
    float x = interpolated.pos.x / uniforms.screen_width;
    float y = 1 - interpolated.pos.y / uniforms.screen_height;

    float2 st = {x,y};

    float xD05 = abs( distance(st, uniforms.mousePos));
    if (xD05 < 0.1) {
        return float4(0);
    }

    float red = x;
//    abs(sin(uniforms.time));
    float green = y;

    return vector_float4(red, green, 0.48, 0.4);
}

