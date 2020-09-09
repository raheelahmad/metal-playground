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


float CircleBand(float2 st, float2 pos, float r, float thickness, float blur) {
    float d = length(st - pos);
    float color = Band(d, r, r + thickness, blur);
    return color;
}


// ---


/// Whether st lies on the line joining point0 and point1
float onLine(float2 st, float2 point1, float2 point2) {
    float distance_offset = (distance(st, point1) + distance(st, point2)) - distance(point1, point2);
    // measure 1 of distance (easy but has a curve to it)
    float d1 = 1.0 - step(0.0004, distance_offset);

    float x0 = st.x;
    float y0 = st.y;
    float x1 = point1.x;
    float y1 = point1.y;
    float x2 = point2.x;
    float y2 = point2.y;
    float num = (y2 - y1)*x0 - (x2 - x1)*y0 + x2*y1 - y2*x1;
    float denom = sqrt(pow(y2-y1, 2) + pow(x2-x1, 2));
    float distance_to_line = abs(num) / denom;

    // measure 2 of distance (solid lines, but go acrosss
    float d2 = 1.0 - step(0.001, distance_to_line);

    return d1 * d2;
}

/// Intersection point between two circles of same radius r,
/// and positioned at center0 and center1. top: whether we want the top or bottom intersection.
/// From http://paulbourke.net/geometry/circlesphere/
float2 circlesIntersctionPoint(float r, bool at_top, float2 center0, float2 center1) {
    float d = distance(center0, center1);
    float a = d/2;
    float2 p2 = center0 + a * (center1 - center0) / d;
    float h = sqrt(pow(r, 2) - pow(a, 2));
    float xPart = (h * (center1.y - center0.y) / d);
    float x3 = p2.x;
    if (at_top) {
        x3 -= xPart;
    } else {
        x3 += xPart;
    }
    float yPart = (h * (center1.x - center0.x) / d);
    float y3 = p2.y;
    if (at_top) {
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
    float3 baseLineColor = float3(0.1, 0.4, 0.8);

    float r = 0.15;
    float2 centerPos = {0,0};

    int totalCircles = 6;
    float thickness = 0.004;
    float blur = 0.001;

    float onAnyCircleMask = 0;
    float onAnyLineMask = 0;

    onAnyCircleMask = CircleBand(st, centerPos, r, thickness, blur); // start w/ middle circle

    // circle intersections from which we build new circles
    float2 intersections [6];
    // midpoints between consecutive intersections
    float2 midpoints[6];

    // Build circles and intersections, and collect midpoints
    for (int idx = 0; idx < totalCircles; idx++) {
        float2 circle2Pos = (idx == 0) ?
            circle2Pos = {centerPos.x + r, 0} // to the right first
            :
            intersections[idx - 1]; // or the last circle

        float2 intersection = circlesIntersctionPoint(r, true, centerPos, circle2Pos);
        onAnyCircleMask += CircleBand(st, intersection, r, thickness, blur);

        float2 line_point1 = circle2Pos;
        float2 line_point2 = intersection;
        onAnyLineMask = max(onAnyLineMask, onLine(st, line_point1, line_point2));

        midpoints[idx] = float2((line_point1.x+line_point2.x)/2, (line_point1.y+line_point2.y)/2);

        intersections[idx] = intersection;
    }

    // Build midpoints
    for (int idx = 0; idx < totalCircles; idx++) {
        float2 line_point1 = midpoints[idx];
        int second_point_index = idx >= (totalCircles - 2) ? abs(totalCircles - idx - 2) : idx + 2;
        float2 line_point2 = midpoints[second_point_index];
        onAnyLineMask = max(onAnyLineMask, onLine(st, line_point1, line_point2));
    }

    onAnyCircleMask = min(onAnyCircleMask, 1.0);

    float3 color = onAnyCircleMask * basePerimeterColor + onAnyLineMask * baseLineColor;
    color = min(color, 1.0);

    return vector_float4(color, 1.0);
}
