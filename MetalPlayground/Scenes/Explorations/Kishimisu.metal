//
//  QuizlesHappyJumping.metal
//  MetalPlayground
//
//  Created by Raheel Ahmad on 9/15/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

/*

struct VertexOut {
    float4 pos [[position]];
    float4 color;
};

typedef struct {
    float time;
    float3 appResolution;
} CustomUniforms;

float hitYet(float3 pos) {
    float sphereR = 0.25;
    float sphereD = length(pos) - sphereR;

    float floorY = -sphereR;
    float floorD = pos.y - floorY;

    return min(floorD, sphereD);
}

float3 calcNormal(float3 pos) {
    float3 e = float3(0.001,0,0);
    return normalize(
                     float3(
                            hitYet(pos+e.xyy) - hitYet(pos-e.xyy),
                            hitYet(pos+e.yxy) - hitYet(pos-e.yxy),
                            hitYet(pos+e.yyx) - hitYet(pos-e.yyx)
                            )
                     );
}

float t_max() { return 20.0; };

float castRay(float3 ro, float3 rd) {
    float t = 0.0;
    for (int i = 0; i < 100; i++) {
        float3 pos = ro + t * rd;

        float h = hitYet(pos);
        if (h < 0.001) { // if we are negative, then we are inside, so stop
            break;
        }

        t += h;

        if (t > t_max()) { // don't go too far in to the scene
            break;
        }
    }
    if (t > t_max()) {
        // if we don't hit, always return -1, which is useful for shadows;
        t = -1.0;
    }
    return t;
}

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

vertex VertexOut happy_jumping_vertex_old(const device VertexIn *vertexArray [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexIn in = vertexArray[vid];
    VertexOut out;
    out.pos = float4(in.pos, 0, 1);
    return out;
}


fragment float4 happy_jumping_fragment_old( VertexOut in [[stage_in]],
                               constant FragmentUniforms &uniforms [[buffer( 0 )]] )
{
//    float2 uv = in.pos.xy;
     float2 uv  = {in.pos.x / uniforms.screen_width, in.pos.y / uniforms.screen_height};
    uv.x -= 0.5;
    uv.y -= 0.5;
    uv.y = 0.5 - uv.y - 0.5;

    // uv.x *= 2;

//    uv.x *= uniforms.appResolution.z;

    float an = 10 * uniforms.mousePos.x;

    float3 ro = float3(4.0 * sin(an),2.0,4.0 * cos(an));

    // build camera
    float3 ta = float3(0,0,0);
    float3 ww = normalize(ta - ro);
    float3 uu = normalize(cross(ww, float3(0,1,0)));
    float3 vv = normalize(cross(uu, ww));

    float3 rd = normalize(uv.x*uu + uv.y*vv + 1.5*ww); // without camera
//    float3 rd = normalize(float3(uv, -1.5)); // without camera

    // did we hit something
    float t = castRay(ro, rd);

    float3 sky_color = float3(0.1, 0.75, 1.0);
    sky_color -= 0.7 * rd.y; // lighter at the bottom of sky (could also use uv.y)
    float3 col = sky_color;
    if (t > 0.0) { // if we did hit
        float3 pos = ro + t * rd;
        float3 norm = calcNormal(pos);

        float3 material = float3(0.2,0.2,0.2); // 0.2 albedo is the value in reality

        // Sun contribution
        float3 sun_dir = normalize(float3(0.9,0.4,0.2)); // position
        float sun_diffuse = clamp(dot(norm, sun_dir), 0.0, 1.0);
        // shadow: cast ray from this position to sun
        float sun_shadow = castRay(pos + norm * 0.001, sun_dir);
        // make sure we are between 0 and 1;
        sun_shadow = step(sun_shadow, 0.0);
        col = material * float3(7.0,4.5,3.0) * sun_diffuse * sun_shadow;

        // Sky contribution
        float3 sky_dir = float3(0.0,1.0,0.0);
        float sky_diffuse = clamp(0.5 + 0.5 * dot(norm, sky_dir), 0.0, 1.0);
        col += material * float3(0.5,0.8,0.9) * sky_diffuse;

        // Bounce contribution (so that bottoms are not pure black)
        float3 bounce_dir = float3(0,-1,0);
        float bounce_diffuse = clamp(0.5 + 0.5 * dot(norm, bounce_dir), 0.0, 1.0);
        col += material * float3(0.7,0.3,0.2) * bounce_diffuse;
    }

    // Apply gamma correction
    col = pow(col, float3(0.4545));

    return float4( col, 1.0 );
}

 */
