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

vertex VertexOut simon_sdfs_vertex(const device VertexIn *vertexArray [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexIn in = vertexArray[vid];
    VertexOut out;
    out.pos = float4(in.pos, 0, 1);
    return out;
}

// ---

float3 backgroundColor(float2 st) {
    float distanceFromCenter = length(st);
    float vignette = 1.0 - distanceFromCenter;
    vignette = smoothstep(0, 0.7, vignette);
    vignette = lerp(vignette, 0, 1, 0.3, 1);
    return float3(vignette);
}

float3 grid(float2 st, float aspect, float3 color, float3 backgroundColor, float cellSpacing, float lineWidth) {
    float2 cells = abs(fract(st * cellSpacing) - 0.5);

    float distanceToCenter = (0.5 - max(cells.x, cells.y));
    float t = smoothstep(0.00, lineWidth, distanceToCenter);


    color = mix(color, backgroundColor, t);

    return color;
}

float sdfCircle(float2 p, float r) {
    return length(p) - r;
}

float sdfLine(float2 p, float2 a, float2 b) {
    float2 pa = p - a;
    float2 ba = b - a;

    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba *  h);

}

float sdBox(float2 p, float2 b )
{
    float2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

fragment float4 simon_sdfs_fragment(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
    float2 st  = {interpolated.pos.x / uniforms.screen_width, 1 - interpolated.pos.y / uniforms.screen_height};
    st = st - 0.5;

    // Background
    float3 color = backgroundColor(st);

    // Grid
    float aspect = uniforms.screen_width / uniforms.screen_height;
    color = grid(st, aspect, gray(), color, 100, 0.08);
    color = grid(st, aspect, black(), color, 20, 0.04);

    // Circles
    float radius = 1.0/9;
    // smooth the edges (antialias) with smoothstep; useful for curves
    float offset = 0.3;
    float circle1 = sdfCircle(st - float2(-offset, offset), radius);
    float circle2 = sdfCircle(st - float2(offset, offset), radius);
    float circle3 = sdfCircle(st - float2(0, -offset), radius);

    float circles = unionSDFs(unionSDFs(circle1, circle2), circle3);

    // Box
    float box = sdBox(rotate(uniforms.time) * st, float2(0.28, 0.28));

    float colorK = lerp(circles - box, -1, 1, 0, 1);
    float3 shapeCol = mix(blue(), red(), smoothstep(0, 1, colorK));

    // Final shape
    float shape = softMin(circles, box, 0.02);

    color = mix(shapeCol * 0.2, color, smoothstep(0.0, 0.003, shape));
    color = mix(shapeCol, color, smoothstep(0, 0.001, shape));


//    float line = sdfLine(rotate(uniforms.time) * st, float2(0.5, 0.0), float2(-0.5, 0.0));
//    line = step(0.01, line);
//
//
//    color = mix(yellow(), color, line);
//


    return vector_float4(color, 1.0);
}


