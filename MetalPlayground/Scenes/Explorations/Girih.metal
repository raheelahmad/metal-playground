//
//  RepeatingCircles.metal
//  MetalPlayground
//
//  Created by Raheel Ahmad on 8/2/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#include "../ShaderHeaders.h"

struct VertexOut {
    float4 pos [[position]];
    float4 color;
};

struct VertexIn {
    vector_float2 pos;
};

typedef enum {
    GirihPatternFirstThingsFirst = 0,
    GirihPatternSixesInterpolated = 1
} GirihPatternKind;

struct FragmentUniforms {
    float time;
    float screen_width;
    float screen_height;
    float screen_scale;
    float2 mousePos;
};

struct GirihUniforms {
    GirihPatternKind kind;
    bool rotating;
    float num_rows;
    float num_polygons;
    float scale;
};

vertex VertexOut girih_vertex(const device VertexIn *vertexArray [[buffer(0)]], unsigned int vid [[vertex_id]]) {
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

float lineDistance(float2 p, float2 v, float2 w) {
    const float l2 = length_squared(w - v);  // i.e. |w-v|^2 -  avoid a sqrt
    if (l2 == 0.0) return distance(p, v);   // v == w case

    // Consider the line extending the segment, parameterized as v + t (w - v).
    // We find projection of point p onto the line.
    // It falls where t = [(p-v) . (w-v)] / |w-v|^2
    // We clamp t from [0,1] to handle points outside the segment vw.
    const float t = max(0.0, min(1.0, dot(p - v, w - v) / l2));
    const float2 projection = v + t * (w - v);  // Projection falls on the segment
    return distance(p, projection);
}

float onLine(float2 p, float2 v, float2 w) {
    float dist = lineDistance(p, v, w);
//    return smoothstep(0.004, 0.001, dist);
    return 1 - step(0.005, dist);
}

float2 lineIntersection(float2 p1, float2 p2, float2 p3, float2 p4) {
    float pxNum = (p1.x*p2.y - p1.y*p2.x)*(p3.x - p4.x) - (p1.x - p2.x)*(p3.x*p4.y - p3.y*p4.x);
    float pyNum = (p1.x*p2.y - p1.y*p2.x)*(p3.y - p4.y) - (p1.y - p2.y)*(p3.x*p4.y - p3.y*p4.x);

    float den = (p1.x - p2.x)*(p3.y - p4.y) - (p1.y - p2.y)*(p3.x - p4.x);
    float px = pxNum / den;
    float py = pyNum / den;
    return {px, py};
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

struct Mask {
    float circleMask;
    float polygonMask;
    // circle intersections from which we build new circles
    float2 intersections [6];
};

Mask girih_circles_mask(float2 st, float r, float rotating, float scaleFactor, float time) {
    if (rotating) {
        st *= rotate(sin(time/4) * M_PI_F);
    }

    // scale down a bit so we are away from the boundary
    st = scale(1/scaleFactor) * st;

    float2 centerPos = {0,0};

    int totalCircles = 6;
    float thickness = 0.004;
    float blur = 0.001;

    Mask mask;
    mask.circleMask = CircleBand(st, centerPos, r, thickness, blur); // start w/ middle circle
    mask.polygonMask = 0;

    // midpoints between consecutive intersections
    float2 midpoints[6];

    // for outer intersections
    float2 innerCircleCenters[6];

    // Build circles and intersections, and collect midpoints
    for (int idx = 0; idx < totalCircles; idx++) {
        float2 circle2Pos = (idx == 0) ?
        circle2Pos = {centerPos.x + r, 0} // to the right first
        :
        mask.intersections[idx - 1]; // or the last circle

        float2 intersection = circlesIntersctionPoint(r, true, centerPos, circle2Pos);
        mask.circleMask += CircleBand(st, intersection, r, thickness, blur);

        innerCircleCenters[idx] = circle2Pos;

//        if (idx > 0) {
            float2 outerIntersection = circlesIntersctionPoint(r, true, circle2Pos, intersection);
            mask.circleMask += CircleBand(st, outerIntersection, r, thickness, blur);
//        }

        float2 line_point1 = circle2Pos;
        float2 line_point2 = intersection;

        midpoints[idx] = float2((line_point1.x+line_point2.x)/2, (line_point1.y+line_point2.y)/2);

        mask.intersections[idx] = intersection;
    }

    // Lines between midpoints of the inner hexagon
    for (int idx = 0; idx < totalCircles; idx++) {
        int n = totalCircles;
        float2 p1 = lineIntersection(
                                     midpoints[idx], midpoints[(idx + 2)%n],
                                     midpoints[(idx + 1)%n],
                                     midpoints[(idx + (n - 1))%n]
                                     );
        float2 p2 = midpoints[idx];
        float fallsOnLine1 = onLine(st, p1, p2);
        mask.polygonMask = max(mask.polygonMask, fallsOnLine1);

        float2 p3 = lineIntersection(
                                     midpoints[idx], midpoints[(idx + n - 2)%n],
                                     midpoints[(idx + n - 1)%n],
                                     midpoints[(idx + 1)%n]
                                     );
        float2 p4 = midpoints[idx];
        float fallsOnLine2 = onLine(st, p3, p4);
        mask.polygonMask = max(mask.polygonMask, fallsOnLine2);
    }

    mask.circleMask = min(mask.circleMask, 1.0);
    return mask;
}

float3 colorForMask(Mask mask, float2 st, float scale) {
    float3 basePerimeterColor = float3(0.4, 0.2, 0.42);
    float3 baseLineColor = float3(0.9, 0.8, 0.1);
    float3 color = 0;

    // Circle outline
    color += (1 - mask.polygonMask) * mask.circleMask * basePerimeterColor;
    // Polygon
    color += mask.polygonMask * baseLineColor;

    // Intersection circles
    if (scale == 1) {
        float3 intersectionColor = 0;
        for (int i=0; i<6; i++) {
            float dist = distance(st, mask.intersections[i]);
            float thickness = 0.01;
            dist = smoothstep(thickness, thickness - 0.001, dist);
            intersectionColor += dist * basePerimeterColor;
        }

        if (length(intersectionColor) > 0) {
            color = intersectionColor;
        }
    }

    color = min(color, 1.0);
    return color;
}


float3 girih_color(float2 st, int rows_count, int polygons_count, bool rotating, float scale, float time) {
    float r = 0.5;

    st *= rows_count;
    st = fract(st);

    st -= 0.5;
    st *= 1.01; // inset a little bit from the edges

    float angleBetweenPoints = M_PI_F / 3.0; // 6 in 2_PI
    float rotationAngle = angleBetweenPoints / polygons_count;

    float3 color = 0;
    for (int i=0; i<polygons_count;i++) {
        st = rotate(rotationAngle) * st;
        Mask rotatedMask = girih_circles_mask(st, r, rotating, scale, time);
        color += colorForMask(rotatedMask, st, scale);
    }
    return color;
}

fragment float4 girih_fragment(
                           VertexOut interpolated [[stage_in]],
                           constant FragmentUniforms &uniforms [[buffer(0)]],
                           constant GirihUniforms &repeating_uniforms [[buffer(1)]]
                               )
{
    float t = uniforms.time;
    float2 st  = {interpolated.pos.x / uniforms.screen_width, 1 - interpolated.pos.y / uniforms.screen_height};
    st.x *= uniforms.screen_width / uniforms.screen_height;

    float3 color = 0;
    if (repeating_uniforms.kind == GirihPatternFirstThingsFirst) {
        color = girih_color(st, repeating_uniforms.num_rows, repeating_uniforms.num_polygons, repeating_uniforms.rotating, repeating_uniforms.scale, t);
    } else {
        color = {0.2, 0.2, 0.2};
    }

    return vector_float4(color, 1.0);
}
