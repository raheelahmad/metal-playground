//
//  Shapes.metal
//  MetalPlayground
//
//  Created by Raheel Ahmad on 5/13/20.
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

vertex VertexOut vertexShapeShader(const device VertexIn *vertexArray [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexIn in = vertexArray[vid];
    VertexOut out;
    out.pos = float4(in.pos, 0, 1);
    return out;
}

vector_float3 circleAnimated(vector_float2 pos, vector_float2 center, float radius, float3 col, FragmentUniforms uniforms) {
    bool animate = 1;
    float timeOffset = animate ? sin(uniforms.time) : 1;

    float d = distance(pos, center);
    vector_float3 result = smoothstep(radius, radius - 0.1, d) > radius/2 ? vector_float3(0) : timeOffset * col;
    return result;
}

fragment float4 fragmentShapeShader(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
    float x = interpolated.pos.x / uniforms.screen_width;
    float y = 1 - interpolated.pos.y / uniforms.screen_height;
    vector_float2 pos = vector_float2(x, y) ;

    vector_float3 col1 = circleAnimated(pos, {0.3, 0.5}, 0.1, float3(0.3, 0.1, 0.9), uniforms);
    vector_float3 col2 = circleAnimated(pos, {0.8, 0.6}, 0.15, float3(0.8, 0.2, 0.6), uniforms);

    vector_float3 col = col1 + col2;

    return vector_float4(col, 1);
}

