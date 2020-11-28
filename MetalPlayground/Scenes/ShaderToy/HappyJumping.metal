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


float RayMarch(float3 pos) {
    float sphereR = 0.25;
    float sphereD = length(pos) - sphereR;

    float planeY = -0.25;
    float planeD = pos.y - planeY;

    float d = min(planeD, sphereD);
    return d;
}

float3 calcNormal(float3 pos) {
    float2 e = float2(0.001, 0.);
    return normalize(
                     float3(
                            RayMarch(pos+e.xyy) - RayMarch(pos-e.xyy),
                            RayMarch(pos+e.yxy) - RayMarch(pos-e.yxy),
                            RayMarch(pos+e.yyx) - RayMarch(pos-e.yyx)
                            )
                     );
}

#define MAX_ITER 200
#define MAX_DIST 20

float castRay(float3 ro, float3 rd) {
    // distance from camera in to the scene
    float t = 0;
    for (int i = 0; i < MAX_ITER; i++) {
        float3 pos = ro + t * rd; // current sampling position in to the scene
        float h = RayMarch(pos); // distance of nearest item in scene from pos
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

    float mouseOffset = 10.0 * uniforms.mousePos.x;

    float3 ro = float3(sin(mouseOffset),0,1.0 * cos(mouseOffset));

    float3 ta = float3(0,0,0);
    float3 ww = normalize(ta - ro);
    float3 uu = normalize(cross(ww, float3(0,1,0)));
    float3 vv = normalize(cross(uu, ww));

    float screenPos = -1.5;
    float3 rd = normalize( uv.x*uu + uv.y*vv - screenPos*ww);

    float3 sky_col = float3(.7,.75,.89);
    float sky_gradient = uv.y * 0.4;
    float3 col = sky_col - sky_gradient;

    float t = castRay(ro, rd);

    if (t > 0) { // we did hit something (-1 for not hit)
        /// Calculate lighting
        float3 pos = ro + t * rd; // position at the param t
        float3 normal = calcNormal(pos);

        // grass has albedo 0.2. Can use that as base color for objects.

        float3 material = 0.18;

        float3 sun_dir = {0.8,0.4,0.2};
        float sun_dif = clamp(dot(normal, sun_dir), 0.,1.0);
        float3 sun_col = material * float3(7.0,5.0,2.6);
        float sun_sha = step(castRay(pos + normal * 0.001, sun_dir), 0);
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
