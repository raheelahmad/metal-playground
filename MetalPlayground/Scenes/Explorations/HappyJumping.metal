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

//float sdEllipsoid(float3 pos, float3 radii) {
//    float k0 = length(pos/radii);
//    float k1 = length(pos/radii/radii);
//    return k0 * (k0 - 1.0) / k1;
//}
//
//float sdSphere(float3 sphere, float radius) {
//    return length(sphere) - radius;
//}
//
//float smin(float a, float b, float k) {
//    float h = max(k - abs(a-b), 0.0);
//    float val = min(a, b) - h * h / (k * 4.0);
//    return val;
//}
//
//
//float smax(float a, float b, float k) {
//    float h = max(k - abs(a-b), 0.0);
//    float val = max(a, b) + h * h / (k * 4.0);
//    return val;
//}
//
//float2 sdGuy(float3 pos, float time, float3 center) {
//    time = fract(time / 2.0);
//    time = 0.5; // for modeling
//    float y = 4.0 * (1 - time) * time;
//    center.y = y;
//
//    float sy = 0.5 + 0.5 * y; // deform in y
//    float sz = 1.0 / sy; // inverse deform in z, so volume is preserved
//    float3 radii = float3(0.25, 0.25 * sy, 0.25 * sz);
//
//    float3 q = pos - center;
//
//    // main body
//    float d = sdEllipsoid(q, radii);
//
//    float3 h = q;
//
//    // head
//    float d2 = sdEllipsoid(h - float3(0.,0.28,0.), float3(0.2));
//    float d3 = sdEllipsoid(h - float3(0.,0.28,-0.1), float3(0.2)); // head's back
//    float head = smin(d3, d2, 0.03);
//    d = smin(d, head, 0.1);
//
//    float3 heye = {abs(h.x), h.y, h.z};
//
//    // eye brows
//    float3 eyebrowCoordinates = heye - float3(0.12,0.34,0.15);
//    // to rotate, can multiply by a pythagorean triplet;
//    // {3, 4, 5} → gives us 40-ish angle
//    float2x2 rotator = float2x2(3,4,-4,3);
//    float denom = 5.0;
//    eyebrowCoordinates.xy = ((rotator) * eyebrowCoordinates.xy) / denom;
//    float dEyebrow = sdEllipsoid(eyebrowCoordinates, float3(0.06, 0.035, 0.05));
//    d = smin(d, dEyebrow, 0.04);
//
//    // mouth
//    float dMouth = sdEllipsoid(h - float3(0.0, 0.1, 0.1), float3(0.1,0.035,0.3));
//    // carve out the mouth using smax
//    d =smax(d, -dMouth, 0.03);
//
//    float2 result = float2(d, 2.0); // 1 is the body identifier, 2 is head
//
//    // eye
//    float eye = sdSphere(heye - float3(0.08, 0.28, 0.16), 0.05);
//    if (eye < d) {
//        result = float2(eye, 3.0); // 3 is the eye id
//    }
//    float pupil = sdSphere(heye - float3(0.09, 0.28, 0.19), 0.02);
//    if (pupil < d) {
//        result = float2(pupil, 4.0); // 4 is the pupil id
//    }
//
//    return result;
//}
//
//float2 RayMarch(float3 pos, float t) {
//    float2 guy1 = sdGuy(pos, t, float3(0, 0, 0.0));
//
//    float planeY = -0.25;
//    float planeD = pos.y - planeY;
//
//    return (planeD < guy1.x) ? float2(planeD, 1.0) : guy1; // 1 is plane-id
//}
//
//float3 calcNormal(float3 pos, float t) {
//    float2 e = float2(0.001, 0.);
//    return normalize(
//                     float3(
//                            RayMarch(pos+e.xyy, t).x - RayMarch(pos-e.xyy, t).x,
//                            RayMarch(pos+e.yxy, t).x - RayMarch(pos-e.yxy, t).x,
//                            RayMarch(pos+e.yyx, t).x - RayMarch(pos-e.yyx, t).x
//                            )
//                     );
//}
//
//#define MAX_ITER 200
//#define MAX_DIST 20
//
///// ro → position of the point (probably on some surface) that we are checking if it's in shadow
///// rd → direction to light source
//float castShadow(float3 ro, float3 rd, float current_material) {
//    float res = 1.0;
//
//    float t = 0.001;
//    for (int i=0; i<100; i++) {
//        // if we hit something, we are in shadow, since we can't reach the light
//        // we'll also mark how close we are from hitting something, even if it didn't hit any objects
//
//        float3 pos = ro + t * rd;
//        float2 closest = RayMarch(pos, t);
//        float h = closest.x;
//
//
//        // t → how far we have come from pos
//        // h → the distance to the closest thing at t
//        // divide h by  → closer things will have a stronger shadow
//        if (closest.y != current_material) {
//            res = min(res, 16.0 * h / t); // find the closest thing, so min
//        }
//
//        h += t;
//
//        if (t > MAX_DIST) { break; }
//    }
//    return res;
//}
//
//float2 castRay(float3 ro, float3 rd, float time) {
//    float material = -1.0 ; // unknown
//    // distance from camera in to the scene
//    float t = 0;
//    for (int i = 0; i < MAX_ITER; i++) {
//        float3 pos = ro + t * rd; // current sampling position in to the scene
//        float2 h = RayMarch(pos, time); // distance and material of nearest item in scene from pos
//        material = h.y;
//        if (h.x < 0.001) { // we have hit something
//            break;
//        }
//        t += h.x; // march further in to scene (by the safe distance h)
//        if (t > MAX_DIST) {
//            break; // we have gone too far without hitting
//        }
//    }
//
//    if (t > MAX_DIST) {
//        material = -1.0; // if not hit, send -1.0
//    }
//    return float2(t, material);
//}

fragment float4 happy_jumping_fragment( VertexOut in [[stage_in]],
                                       constant FragmentUniforms &uniforms [[buffer( 0 )]] )
{
//    //    float2 uv = in.pos.xy;
//    float2 uv  = {in.pos.x / uniforms.screen_width, in.pos.y / uniforms.screen_height};
//    uv = 2 * uv - 1.0;
//    uv.y = -uv.y;
//
//    float time = uniforms.time;
//    float mouseOffset = 30.0 * uniforms.mousePos.x;
////    mouseOffset = 0;
//
//    float3 lookAt = float3(0,0.95,0); // camera target
//    float3 ro = lookAt + float3(1.5 * sin(mouseOffset), 0 , 1.5*cos(mouseOffset));
//    float3 forward = normalize(lookAt - ro);
//    float3 right = normalize(cross(forward, float3(0,1,0)));
//    float3 up = normalize(cross(right, forward));
//    float screenZPos = 1.3;
//    float3 rd = normalize( uv.x*right + uv.y*up + screenZPos*forward);
//
//    float3 sky_col = float3(.7,.75,.89);
//    float sky_gradient = uv.y * 0.4;
//    float3 col = sky_col - sky_gradient;
//
//    float2 tAndMaterial = castRay(ro, rd, time);
//
//    float t = tAndMaterial.x;
//    float tMaterial = tAndMaterial.y;
//    if (tMaterial > 0) { // we did hit something (-1 for not hit)
//        /// Calculate lighting
//        float3 pos = ro + t * rd; // position at the param t
//        float3 normal = calcNormal(pos, time);
//
//        // grass has albedo 0.2. Can use that as base color for objects.
//
//        float3 material = 0.18;
//
//        if (tMaterial < 1.5) {
//            material = {0.03, 0.13, 0.01};
//        } else if (tMaterial < 2.5) {
//            material = {0.1, 0.12, 0.01};
//        } else if (tMaterial < 3.5) {
//            material = {0.4, 0.52, 0.41};
//        } else if (tMaterial < 4.5) {
//            material = float3(0.001);
//        }
//
//        float3 sun_dir = {0.8,0.4,0.2};
//        float sun_dif = clamp(dot(normal, sun_dir), 0.,1.0);
//        float3 sun_col = material * float3(7.0,5.0,2.6);
//        float sun_sha =
////        step(castShadow(pos + normal * 0.001, sun_dir, tMaterial), 0);
//        step(castRay(pos + normal * 0.001, sun_dir, time).y, 0);
//        col = sun_col * sun_dif * sun_sha;
//
//        float3 sky_col = material * float3(0.5, 0.8, 0.9);
//        float3 sky_dir =  float3(0,1.0,0.0);
//        float sky_dif = clamp(0.5 + 0.5 * dot(normal, sky_dir), 0.,1.);
//        col += sky_col * sky_dif;
//
//        // Bounce calculates light in "up" direction. Otherwise, similar to sky.
//        float3 bounce_dir = float3(0,-1,0);
//        float bounce_dif = clamp(0.5 + 0.5 * dot(normal, bounce_dir), 0.,1.);
//        float3 bounce_col = float3(0.7,0.3,0.2);
//        col += material * bounce_col * bounce_dif;
//    }
//
//    // gamma correction
//    col = pow(col, 0.4545);
//
////    col = step(length(uv), 0.2);

    return float4(float3(1), 1.0 );
}

