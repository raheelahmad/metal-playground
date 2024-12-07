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

fragment float4 fract_and_friends_fragment(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
    float2 st  = {interpolated.pos.x / uniforms.screen_width, 1 - interpolated.pos.y / uniforms.screen_width};

    // Background
    float3 color = gray();

    // Grid
    float3 cell = fract(float3(st, 0) * 10);
    cell = abs(cell - 0.5);
    float distToCellCenter = 1 - 2.0 * max(cell.x, cell.y);
    float cellLine = smoothstep(0, 0.04, distToCellCenter);
    color = mix(black()+0.5, color, cellLine);

    // Axes
    float xAxis = step(0.002, abs(st.x - 0.5));
    float yAxis = step(0.002, abs(st.y - 0.5));
    color = mix(yellow(), color, xAxis);
    color = mix(yellow(), color, yAxis);

    // Lines
#warning("Follow from 12:20 in the video")

    return vector_float4(color, 1.0);
}


