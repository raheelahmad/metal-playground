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
};

struct VertexOut {
    float4 pos [[position]];
    float4 color;
};

vertex VertexOut liveCodeVertexShader(const device VertexIn *vertices [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexOut in;
    in.pos = {vertices[vid].pos.x, vertices[vid].pos.y, 0, 1};
    return in;
}

// MARK: - Fragment Shader

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
    float innerRadius = 0.26;
    float thickness = 0.10;
    float3 torusCenter = float3(2.2, 0.9, 0);
    point = point - torusCenter;
    float x = length(point.xz) - innerRadius;
    float y = length(float2(x, point.y)) - thickness;
    return y;
}

float getDistanceToBox(float3 point) {
    float3 boxPosition = float3(-1, 1.3, 1);
    float3 boxSize = float3(0.3);
    point = point - boxPosition;
    float3 q = abs(point) - boxSize;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float getDistance(float3 point) {
    float3 spherePosition = float3(-1, 0.6, 0);
    float sphereRadius = 0.2;
    float planeY = -0.2;
    float distanceToSphere = length(spherePosition - point) - sphereRadius;
    float distanceToPlane = point.y - planeY;
    float distanceToCapsule = getDistanceToCapsule(point);
    float distanceToTorus = getDistanceToTorus(point);
    float distanceToBox = getDistanceToBox(point);
    float distanceToCylinder = getDistanceToCylinder(point);

    float d = min(distanceToPlane, distanceToSphere);
    d = min(d, distanceToCapsule);
    d = min(d, distanceToTorus);
    d = min(d, distanceToBox);
    d = min(d, distanceToCylinder);
    return d;
}

float3 getNormal(float3 point) {
    float dist = getDistance(point);
    float2 e = float2(0.01, 0);
    float3 normal = dist - float3(
                                      getDistance(point - e.xyy),
                                      getDistance(point - e.yxy),
                                      getDistance(point - e.yyx)
                                      );
    return normalize(normal);
}

float rayMarch(float3 rayOrigin, float3 rayDirection, float time) {
    int MAX_STEPS = 200;
    float MAX_DISTANCE = 200.0;
    float MIN_SURFACE_DISTANCE = 0.001;
    float distance = 0;

    for (int i = 0; i < MAX_STEPS; i++) {
        float3 marchPointToNextDistance = rayOrigin + rayDirection * distance;
        float nextDistanceFromMarchPoint = getDistance(marchPointToNextDistance);
        distance += nextDistanceFromMarchPoint;
        if (distance > MAX_DISTANCE || nextDistanceFromMarchPoint < MIN_SURFACE_DISTANCE) { break; }
    }

    return distance;
}


float getLight(float3 point, float time) {
    float3 lightPosition = float3(0, 5, 6); // above the sphere
    lightPosition.xz = float2(3 * cos(time), 6 * sin(time));
    float3 lightVector = normalize(lightPosition - point);
    float3 normalAtPoint = getNormal(point);
    float diffuse = dot(normalAtPoint, lightVector);
    diffuse = clamp(diffuse, 0., 1.);

    float d = rayMarch(point + normalAtPoint * 0.02, lightVector, time);
    if (d < length(lightPosition - point)) {
        diffuse *= 0.2;
    }

    return diffuse;
}

fragment float4 liveCodeFragmentShader(
                                       VertexOut interpolated [[stage_in]],
                                       constant FragmentUniforms &uniforms [[buffer(0)]]
) {
    float2 uv = 2 * (float2(
       interpolated.pos.x / uniforms.screen_width,
       1 - interpolated.pos.y / uniforms.screen_height
    ) - 0.5);

    float3 rayOrigin = float3(0, 2.0, -3);
    float3 rayDirection = normalize(float3(uv.x, uv.y, 1.2));
    float d = rayMarch(rayOrigin, rayDirection, uniforms.time);
    float3 pointAtD = rayOrigin + rayDirection * d;
    float3 light = getLight(pointAtD, uniforms.time);
    float3 color = float3(light);

    return float4(color, 1.0);
}

