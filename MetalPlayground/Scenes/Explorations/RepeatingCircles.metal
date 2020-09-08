//
//  RepeatingCircles.metal
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

vertex VertexOut repeating_cirlces_vertex(const device VertexIn *vertexArray [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexIn in = vertexArray[vid];
    VertexOut out;
    out.pos = float4(in.pos, 0, 1);
    return out;
}

// ---

float Band(float p, float start, float end, float blur) {
    float mask = smoothstep(start - blur, start + blur, p);
    mask *= smoothstep(end + blur, end - blur, p);
    return mask;
}

// ---

float CircleBand(float2 st, float2 pos, float r, float thickness, float blur) {
    float d = length(st - pos);
    float color = Band(d, r, r + thickness, blur);
    return color;
}


/// From http://paulbourke.net/geometry/circlesphere/
float2 circleIntersction(float r, bool top, float2 center0, float2 center1) {
    float d = distance(center0, center1);
    float a = d/2;
    float2 p2 = center0 + a * (center1 - center0) / d;
    float h = sqrt(pow(r, 2) - pow(a, 2));
    float xPart = (h * (center1.y - center0.y) / d);
    float x3 = p2.x;
    if (top) {
        x3 -= xPart;
    } else {
        x3 += xPart;
    }
    float yPart = (h * (center1.x - center0.x) / d);
    float y3 = p2.y;
    if (top) {
        y3 += yPart;
    } else {
        y3 -= yPart;
    }
    return float2(x3, y3);
}

fragment float4 repeating_circles_fragment(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
    //    float t = uniforms.time;
    //    int index = int(uniforms.time);
    float2 st  = {interpolated.pos.x / uniforms.screen_width, 1 - interpolated.pos.y / uniforms.screen_height};
    st -= .5;

    float3 basePerimeterColor = float3(0.9, 0.8, 0.1);

    float r = 0.15;
    float2 centerPos = {0,0};

    float totalCircles = 6;
    float thickness = 0.004;
    float blur = 0.001;
    float colorT = CircleBand(st, centerPos, r, thickness, blur);
    float2 last_intersection;
    for (uint idx = 0; idx < totalCircles; idx++) {
        float2 circle2Pos = (idx == 0) ?
            circle2Pos = {centerPos.x + r, 0} // to the right
            :
            last_intersection;

        last_intersection = circleIntersction(r, true, centerPos, circle2Pos);
        colorT += CircleBand(st, last_intersection, r, thickness, 0.001);
    }

    colorT = min(colorT, 1.0);

    float3 color = colorT * basePerimeterColor;

    return vector_float4(color, 1.0);
}
