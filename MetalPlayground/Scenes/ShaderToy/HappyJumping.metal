//
//  QuizlesHappyJumping.metal
//  MetalPlayground
//
//  Created by Raheel Ahmad on 9/15/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 pos [[position]];
    float4 color;
};

typedef struct {
    float time;
    float3 appResolution;
} CustomUniforms;


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


vertex VertexOut happy_jumping_vertex(const device VertexIn *vertexArray [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexIn in = vertexArray[vid];
    VertexOut out;
    out.pos = float4(in.pos, 0, 1);
    return out;
}

float sdEllipsoid(float3 pos, float3 radii) {
    float k0 = length(pos/radii);
    float k1 = length(pos/radii/radii);
    return k0 * (k0 - 1.0) / k1;
}

float sdSphere(float3 sphere, float radius) {
    return length(sphere) - radius;
}

float smin(float a, float b, float k) {
    float h = max(k - abs(a-b), 0.0);
    float val = min(a, b) - h * h / (k * 4.0);
    return val;
}

float sdGuy(float3 pos, float time, float3 center) {
    time = fract(time);
    time = 0.5; // for modeling
    float y = 4.0 * (1 - time) * time;
    center.y = y;

    float sy = 0.5 + 0.5 * y; // deform in y
    float sz = 1.0 / sy; // inverse deform in z, so volume is preserved
    float3 radii = float3(0.25, 0.25 * sy, 0.25 * sz);

    float3 q = pos - center;

    // main body
    float d = sdEllipsoid(q, radii);

    float3 h = q;

    // head
    float d2 = sdEllipsoid(h - float3(0.,0.28,0.), float3(0.2));
    float d3 = sdEllipsoid(h - float3(0.,0.28,-0.1), float3(0.2)); // head's back
    float head = smin(d3, d2, 0.03);
    d = smin(d, head, 0.1);

    // eye
    float3 heye = {abs(h.x), h.y, h.z};
    float eye = sdSphere(heye - float3(0.08, 0.28, 0.16), 0.05);
    d = min(d, eye);

    return d;
}

float RayMarch(float3 pos, float t) {
    float guy1 = sdGuy(pos, t, float3(0, 0, 0.0));

    float planeY = -0.25;
    float planeD = pos.y - planeY;
    float planeZ = pos.z - (-2.0 + 2 *sin(t));
    planeZ = 20; // disable planeZ

    float d = min(planeD, guy1);
    d = min(d, planeZ);

    return d;
}

float3 calcNormal(float3 pos, float t) {
    float2 e = float2(0.001, 0.);
    return normalize(
                     float3(
                            RayMarch(pos+e.xyy, t) - RayMarch(pos-e.xyy, t),
                            RayMarch(pos+e.yxy, t) - RayMarch(pos-e.yxy, t),
                            RayMarch(pos+e.yyx, t) - RayMarch(pos-e.yyx, t)
                            )
                     );
}

#define MAX_ITER 200
#define MAX_DIST 20

float castRay(float3 ro, float3 rd, float time) {
    // distance from camera in to the scene
    float t = 0;
    for (int i = 0; i < MAX_ITER; i++) {
        float3 pos = ro + t * rd; // current sampling position in to the scene
        float h = RayMarch(pos, time); // distance of nearest item in scene from pos
        if (h < 0.001) { // we have hit something
            break;
        }
        t += h; // march further in to scene (by the safe distance h)
        if (t > MAX_DIST) {
            break; // we have gone too far without hitting
        }
    }

    if (t > MAX_DIST) {
        t = -1.0; // if not hit, send -1.0
    }
    return t;
}

fragment float4 happy_jumping_fragment( VertexOut in [[stage_in]],
                                       constant FragmentUniforms &uniforms [[buffer( 0 )]] )
{
    //    float2 uv = in.pos.xy;
    float2 uv  = {in.pos.x / uniforms.screen_width, in.pos.y / uniforms.screen_height};
    uv = 2 * uv - 1.0;
    uv.y = -uv.y;

    float time = uniforms.time;
    float mouseOffset = 30.0 * uniforms.mousePos.x;
//    mouseOffset = 0;

//     float3 ro = {2 * sin(mouseOffset),1, 2 * cos(mouseOffset)};
//     float zoom = 1;
//
//     // ray from camera to the screen point (and then in to the screen to hit an object)
//     float3 lookAt = {0};
//
//     float3 forward = normalize(lookAt - ro);
//     float3 right = normalize(cross( float3(0, 1, 0), forward));
//     float3 up = normalize(cross(forward, right));
//
//     float3 screenCenter = ro + forward * zoom;
//
//     float3 screenPoint = screenCenter + uv.x * right + uv.y * up;
//     float3 rd = normalize(screenPoint - ro);

    float3 lookAt = float3(0,0.95,0); // camera target
    float3 ro = lookAt + float3(1.5 * sin(mouseOffset), 0 , 1.5*cos(mouseOffset));
    float3 forward = normalize(lookAt - ro);
    float3 right = normalize(cross(forward, float3(0,1,0)));
    float3 up = normalize(cross(right, forward));
    float screenZPos = 1.3;
    float3 rd = normalize( uv.x*right + uv.y*up + screenZPos*forward);

    float3 sky_col = float3(.7,.75,.89);
    float sky_gradient = uv.y * 0.4;
    float3 col = sky_col - sky_gradient;

    float t = castRay(ro, rd, time);

    if (t > 0) { // we did hit something (-1 for not hit)
        /// Calculate lighting
        float3 pos = ro + t * rd; // position at the param t
        float3 normal = calcNormal(pos, time);

        // grass has albedo 0.2. Can use that as base color for objects.

        float3 material = 0.18;

        float3 sun_dir = {0.8,0.4,0.2};
        float sun_dif = clamp(dot(normal, sun_dir), 0.,1.0);
        float3 sun_col = material * float3(7.0,5.0,2.6);
        float sun_sha = step(castRay(pos + normal * 0.001, sun_dir, time), 0);
        col = sun_col * sun_dif * sun_sha;

        float3 sky_col = material * float3(0.5, 0.8, 0.9);
        float3 sky_dir =  float3(0,1.0,0.0);
        float sky_dif = clamp(0.5 + 0.5 * dot(normal, sky_dir), 0.,1.);
        col += sky_col * sky_dif;

        // Bounce calculates light in "up" direction. Otherwise, similar to sky.
        float3 bounce_dir = float3(0,-1,0);
        float bounce_dif = clamp(0.5 + 0.5 * dot(normal, bounce_dir), 0.,1.);
        float3 bounce_col = float3(0.7,0.3,0.2);
        col += material * bounce_col * bounce_dif;
    }

    // gamma correction
    col = pow(col, 0.4545);

//    col = step(length(uv), 0.2);

    return float4(col, 1.0 );
}

