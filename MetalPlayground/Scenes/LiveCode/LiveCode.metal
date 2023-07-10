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

vertex VertexOut liveCodeVertexShader(const device VertexIn *vertices [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexOut in;
    in.pos = {vertices[vid].pos.x, vertices[vid].pos.y, 0, 1};
    return in;
}

float fmodal(float a, float b) {
    if(a<0.0) {
        return b - modf(abs(a), b);
    }
    return modf(a, b);
}

// MARK: - Ray Marching

float sdfSphere(float3 p, float r) {
    return length(p) - r;
}

float sdPlane(float3 p) {
    return p.y - (-1.3);
}

float2 scene(float3 position, float time) {
    // sphere
    float3 spherePosition = position - float3(0, 0.5, 1.0);
    float distance = sdfSphere(spherePosition, 0.8);
    float materialID = 1.0;

    // Other objects
    float3 objPosition = position - float3(0, 0.5, 1); // starting point
    objPosition.x = fract(objPosition.x + 0.5) - 0.5;
    objPosition.z = fmod(objPosition.z + 1.0, 2.0) - 1.0;
    objPosition.y += sin(position.x + time)  * 0.45;
    objPosition.y += cos(position.z + time * 3)  * 0.45;
    float distanceObjs = sdfSphere(objPosition, 0.2 * fract(objPosition.z));
    if (distanceObjs < distance) {
        distance = distanceObjs;
        materialID = 2.0;
    }

    float distancePlane = sdPlane(position);
    if (distancePlane < distance) {
        distance = distancePlane;
        materialID = 3.0;
    }

    return float2(distance, materialID);
}

const constant float NEAR_CLIPPING_PLANE = 0.21;
const constant float FAR_CLIPPING_PLANE = 20.01;
const constant float MAX_MARCH_STEPS = 200;
const constant float EPSILON = 0.01;
const constant float DISTANCE_BIAS = 0.7;

float2 rayMarchTo(float3 position, float3 direction, float time) {
    float total_distance = NEAR_CLIPPING_PLANE;
    float2 result;
    for(int i = 0; i < MAX_MARCH_STEPS; i++) {
        // result.x is the distance and result.y is the material
        result = scene(position + direction * total_distance, time);
        if (result.x < EPSILON) { break; }
        total_distance += result.x * DISTANCE_BIAS;
        if (total_distance > FAR_CLIPPING_PLANE) { break; }
    }

    return float2(total_distance, result.y);
}

float3 getNormal(float3 rayHitPosition, float smoothness, float time) {
    float3 n;
    float2 dn = float2(smoothness, 0);
    // here .x from the scene is the distance
    n.x = scene(rayHitPosition + dn.xyy, time).x - scene(rayHitPosition - dn.xyy, time).x;
    n.y = scene(rayHitPosition + dn.yxy, time).x - scene(rayHitPosition - dn.yxy, time).x;
    n.z = scene(rayHitPosition + dn.yyx, time).x - scene(rayHitPosition - dn.yyx, time).x;
    return normalize(n);
}

// MARK: - Fragment Shader

fragment float4 liveCodeFragmentShader(
                                       VertexOut interpolated [[stage_in]],
                                       constant FragmentUniforms &uniforms [[buffer(0)]]
) {
    float2 uv = 2 * (float2(
       interpolated.pos.x / uniforms.screen_width,
       1 - interpolated.pos.y / uniforms.screen_height
    ) - 0.5);

    float time = uniforms.time;
    float2 mouseXY = uniforms.mousePos / float2(5);

    // -- Main image generation

    float3 direction = normalize(float3(uv.x, uv.y, 2.5));
    float3 cameraOrigin = float3(0, 0, -6.5);
    float2 result = rayMarchTo(cameraOrigin, direction, time);

    // TODO: use fog
    float fog = 1.0 - result.x / FAR_CLIPPING_PLANE;

    float3 materialColor = float3(0.0, 0.0, 0);
    if (result.y == 1.0) {
        // sphere
        materialColor = float3(1.0, 0.25, 1);
    } else if (result.y == 2.0) {
        // sphere
        materialColor = float3(1.0, 0.75, 0.2);
    } else if (result.y == 3.0) {
        // sphere
        materialColor = float3(0.0, 0.15, 0.1);
    }

    // Lighting
    float3 intersection = cameraOrigin + direction * result.x;
    float3 nrml = getNormal(intersection, 0.01, time);
    float3 lightDir = normalize(float3(0, 1, 0.0));
    float diffuse = dot(lightDir, nrml);
    diffuse = diffuse * 0.5 + 0.5;
    // Combine ambient and diffuse
    float3 lightColor = float3(1.0, 1.2, 0.7);
    float3 ambientColor = float3(0.2, 0.45, 0.6);
    float3 diffuseLit = materialColor * (diffuse * lightColor + ambientColor);

    float3 color = diffuseLit * fog;

    // -- Image generation DONE

    return float4(color, 1.0);
}
