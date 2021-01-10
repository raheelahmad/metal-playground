//
//  07Shape.metal
//  MetalPlayground
//
//  Created by Raheel Ahmad on 7/11/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

/*
#include "MetalHeaders.h"

vertex VertexOut shape_vertex(const device VertexIn *vertexArray [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexIn in = vertexArray[vid];
    VertexOut out;
    out.pos = float4(in.pos, 0, 1);
    return out;
}

float3 distanceField(float2 st, float time) {
    // map from 0 -> 1 to -1 to 1.
    // This maps the center from bottom-left to center of the screen.
    // Can think of having 4 quadrants instead of 1, with the top right having +ve x and y.
    st = st * 2 - 1;
    // calculate the distance of st to 0.5, 0.5. Which is in the center of the top-right quadrant.
    // however, with the abs, a point in any other quadrant acts like as if it's in top-right.
    float d = length(abs(st) - 0.50);

    // outer and inner are the radii inside which dist is true.
    float outer = 0.5;
    float inner = 0.1;
    float value = step(inner, d) * step(d, outer);
//    float value = smoothstep(0.3, 0.4, d) * smoothstep(0.54, 0.45, d);
    return float3(value);
}

float3 circles(float2 st, float time) {
    return
        circle(st, time, 0.6, {0.3, 0.3}) * float3(0.9, 0.1, 0.1)
//         + circle(st, time, 0.2, {0.8, 0.8}, float3(0.9, 0.8, 0.3))
//        + circle(st, time, 0.16, {0.8, 0.2}, float3(0.9, 0.8, 0.3))
//        + circle(st, time, 0.16, {0.5, 0.4}, float3(0.4, 0.4, 0.7))

    ;
}

float polarShape(float2 st, float time) {
    float2 pos = float2(0.5) - st;

    // For a particular angle (and its corresponding f),
    float a = atan2(pos.y, pos.x);
    float r = length(pos) * 2.0;
    // animate:
    a += time;

    float f =
    // Variants:
//    abs(cos(a * 3));
//    abs(cos(a * 2.5)) * 0.5 + 0.3;
//    abs(cos(a * 12) * sin(a * 3)) * 0.8 + 0.2;
    smoothstep(-.5,1., cos(a*20.0))*0.2+0.5;

    // Cut out hole:
    f = f * step(0.4, r);

    float color = 1.0 - step(f, r);
    return color;
}

float3 stroke(float2 st, float time) {
    float radii [8] = {0.2, 0.1, 0.13, 0.21, 0.3, 0.13, 0.21, 0.12};
    float2 pos [8] = {
        {0.3, 0.5},
        {0.1, 0.3},
        {0.4, 0.29},
        {0.7, 0.1},
        {0.41, 0.91},
        {0.29, 0.31},
        {0.83, 0.51},
        {0.11, 0.81},
    };

    float val = 0;
    for(int i = 0; i < 8; i++) {
        val += circle(st, 1, radii[i], pos[i]);
    }

    float3 col = {0.9, 0.2, 0.1};
    return min(1.0, val) * col;
}

float3 rectangles(float2 st, float time) {
    float4 rects [3] = {
        {0.2, 0.7, 0.6, 0.1 },
        {0.2, 0.1, 0.5, 0.4 },
    };
    float3 colors [3] = {
        float3(0.7, 0.8, 0.9),
        float3(0.9, 0.5, 0.7),
    };
    float3 color = 0;
    for(int i = 0; i < 2; i++) {
        color += rect(st, time, rects[i], colors[i]);
    }
    return color;
}

fragment float4 shape_fragment(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
    float2 st  = {interpolated.pos.x / uniforms.screen_width, 1 - interpolated.pos.y / uniforms.screen_height};

    float3 color = polarShape(st, uniforms.time);

    return vector_float4(color, 1.0);
}
 */
