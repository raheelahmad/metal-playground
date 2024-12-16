//
//  Helpers.metal
//  MetalPlayground
//
//  Created by Raheel Ahmad on 1/9/21.
//  Copyright © 2021 Raheel Ahmad. All rights reserved.
//

#include <metal_stdlib>

using namespace metal;
#include "ShaderHeaders.h"

float2x2 rotate(float angle) {
    return float2x2(cos(angle),sin(-angle), sin(angle),cos(angle));
}

float2x2 scale(float2 sc) {
    sc = 1/sc;
    return float2x2(
                    sc.x, 0.,
                    0., sc.y
                    );
}

float absSin(float t) {
    return (sin(t) + 1)/2.0;
}

float lerp(float x, float u, float v, float m, float n) {
    float prog = (x - u) / (v - u);
    return m + (n - m) * prog;
}

float lerpU(float x, float u, float v) {
    return lerp(x, u, v, 0.0, 1.0);
}

float circle(float2 st, float time, float rad, float2 center) {
    float variation =
    (1 + cos(time)) / 2.0
    ;
    float pct = distance(st, center);
    float dist = 1 - step(rad * variation, pct);
    return dist;
}

// MARK: SDFs

float getDistanceToCylinder(float3 point) {
    float spheresRadius = 0.4;
    float3 startAPosition = float3(-0, 0.5, 1);
    float3 endBPosition = float3(4, 0.5, 3);
    float3 aToB = endBPosition - startAPosition;
    float3 pointToA = point - startAPosition;
    float t = dot(pointToA, aToB) / dot(aToB, aToB);
    float3 center = startAPosition + t * aToB;
    float x = length(point - center) - spheresRadius;
    float y = (abs(t - 0.5) - 0.5) * length(aToB);
    float exterior = length(max(float2(x, y), 0));
    float interior = min(max(x, y), 0.);
    return exterior + interior;
}

float getDistanceToCapsule(float3 point) {
    float spheresRadius = 0.1;
    float3 startAPosition = float3(1, 0.5, 1);
    float3 endBPosition = float3(1.5, 0.5, 1);
    float3 aToB = endBPosition - startAPosition;
    float3 pointToA = point - startAPosition;
    float t = dot(pointToA, aToB) / dot(aToB, aToB);
    t = clamp(t, 0., 1.);
    float3 center = startAPosition + t * aToB;
    float d = length(point - center) - spheresRadius;
    return d;
}

float getDistanceToTorus(float3 point) {
    float innerRadius = 1.06;
    float thickness = 0.40;
    float x = length(point.xz) - innerRadius;
    float y = length(float2(x, point.y)) - thickness;
    return y;
}

float getDistanceToBox(float3 point, float size) {
    float3 boxSize = float3(size);
    float3 q = abs(point) - boxSize;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float getDistanceToPlane(float3 point) {
    float p = dot(point, normalize(float3(0, 1, 0)));
    return p;
}

// MARK: SDF Operations

float subtractSDFs(float a, float b) {
    return max(-a, b);
}

float intersectSDFs(float a, float b) {
    return max(a, b);
}
float unionSDFs(float a, float b) {
    return min(a, b);
}

float blendSDFs(float a, float b, float t) {
    return mix(a, b, t);
}

float smoothUnionSDFs( float a, float b, float k) {
    float h = clamp( 0.5+0.5* (b-a)/k, 0., 1. );
    return mix( b, a, h) - k*h* (1.0-h);
}

float softMax(float a, float b, float k) {
    return log(exp(k * a) + exp(k * b)) / k;
}

float softMin(float a, float b, float k) {
    k *= 1.0; // why?
    float r = exp2(-a/k) + exp2(-b/k);
    return -k * log2(r);
}

// MARK: Colors
float3 red() { return float3(1.0, 0.0, 0.0); }
float3 green() { return float3(0.0, 1.0, 0.0); }
float3 blue() { return float3(0.4, 0.4, 1.0); }
float3 yellow() { return float3(1.0, 1.0, 0.0); }
float3 black() { return float3(0.0, 0.0, 0.0); }
float3 gray() { return float3(0.8, 0.8, 0.8); }
