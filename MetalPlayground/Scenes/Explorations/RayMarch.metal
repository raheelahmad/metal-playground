//
//  RayMarch.metal
//  MetalPlayground
//
//  Created by Raheel Ahmad on 6/23/23.
//  Copyright © 2023 Raheel Ahmad. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#import <simd/simd.h>

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


vertex VertexOut rayMarchingSimpleVertex(const device VertexIn *vertices [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexOut in;
    in.pos = {vertices[vid].pos.x, vertices[vid].pos.y, 0, 1};
    return in;
}

/// -- Drawing

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

float getDistanceToBox(float3 point) {
    float3 boxSize = float3(1, 1, 0.2);
    float3 q = abs(point) - boxSize;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float2x2 rotateBy(float a) {
    float s = sin(a);
    float c = cos(a);
    return float2x2(c, -s, s, c);
}

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

float getDistanceToPlane(float3 point) {
    float p = dot(point, normalize(float3(0, 1, 0)));
    return p;
}

float getDistance(float3 point, float time) {
    float3 spherePosition = float3(0);
    float sphereRadius = 1.2;
    float planeY = -1.2;

    // Torus
    float distanceToTorus = getDistanceToTorus(point);

    // Box
    float3 boxPoint = point;
    boxPoint -= float3(0.0, 1.8, -2);
    boxPoint.xz = boxPoint.xz * rotateBy(time);
    float scale = mix(1, 4, smoothstep(-1, 1, boxPoint.y));
    boxPoint.xz *= scale;
    boxPoint.xz = boxPoint.xz * rotateBy(boxPoint.y*4);
    float distanceToBox = getDistanceToBox(boxPoint) / (scale * 4);

    // Sphere
    float3 spherePoint = point;
    spherePoint = point - float3(0.0);

    // Final shape
    float shapeD = distanceToBox;

    float d = getDistanceToPlane(point);
    d = min(d, shapeD);
    //    d = min(d, distanceToSphere);
//    d = min(d, distanceToTorus);
//    d = min(d, distanceToBox);
//    d = min(d, distanceToCylinder);
    return d;
}

float3 getNormal(float3 point, float time) {
    float dist = getDistance(point, time);
    float2 e = float2(0.01, 0);
    float3 normal = dist - float3(
                                      getDistance(point - e.xyy, time),
                                      getDistance(point - e.yxy, time),
                                      getDistance(point - e.yyx, time)
                                      );
    return normalize(normal);
}

float rayMarch(float3 rayOrigin, float3 rayDirection, float time) {
    int MAX_STEPS = 200;
    float MAX_DISTANCE = 400.0;
    float MIN_SURFACE_DISTANCE = 0.01;
    float distance = 0;

    for (int i = 0; i < MAX_STEPS; i++) {
        float3 marchPointToNextDistance = rayOrigin + rayDirection * distance;
        float nextDistanceFromMarchPoint = getDistance(marchPointToNextDistance, time);
        distance += nextDistanceFromMarchPoint;
        // the abs() allows us to back track if we have gone really far in to the negative.
        if (distance > MAX_DISTANCE || abs(nextDistanceFromMarchPoint) < MIN_SURFACE_DISTANCE) { break; }
    }

    return distance;
}


float getLight(float3 point, float time) {
    float3 lightPosition = float3(2, 5, -4); // above the sphere
//    lightPosition.xz = float2(3 * cos(time), 6 * sin(time));
    float3 lightVector = normalize(lightPosition - point);
    float3 normalAtPoint = getNormal(point, time);
    float diffuse = dot(normalAtPoint, lightVector);
    diffuse = clamp(diffuse, 0., 1.);

    float d = rayMarch(point + normalAtPoint * 0.02, lightVector, time);
    if (d < length(lightPosition - point)) {
        diffuse *= 0.2;
    }

    return diffuse;
}

fragment float4 rayMarchingSimpleFragment(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
    float2 uv = {interpolated.pos.x / uniforms.screen_width, 1 - interpolated.pos.y/uniforms.screen_height};
    uv = 2 * (uv - 0.5);
    float time = uniforms.time;

    float3 rayOrigin = float3(0, 2.5, -6);
    float3 rayDirection = normalize(float3(uv.x, uv.y, 1.2));
    float d = rayMarch(rayOrigin, rayDirection, time);
    float3 pointAtD = rayOrigin + rayDirection * d;
    float3 light = getLight(pointAtD, time);
    float3 color = float3(light);

    return float4(color, 1.0);
}
