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

vertex VertexOut kishimisu_vertex(const device VertexIn *vertexArray [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexIn in = vertexArray[vid];
    VertexOut out;
    out.pos = float4(in.pos, 0, 1);
    return out;
}

float3 palette( float t ) {
    float3 a = float3(0.5, 0.5, 0.5);
    float3 b = float3(0.5, 0.5, 0.5);
    float3 d = float3(0.263,0.416,0.557);
    float3 c = float3(1,1,1);
    return a + b*cos( 6.28318*(c*t+d) );
}


fragment float4 kishimisu_fragment( VertexOut in [[stage_in]],
                               constant FragmentUniforms &uniforms [[buffer( 0 )]] )
{
    float3 finalCol = float3(0);
    float time = uniforms.time;
    float2 resolution = float2(uniforms.screen_width, uniforms.screen_height);
    float2 uv  = in.pos.xy / resolution * 2.0 - 1.0;
    float2 uv0 = uv;

    for (float i =0; i < 3; i++) {
        uv.x *= resolution.x / resolution.y;

        float3 col = palette(length(uv0) + i*0.9 + time);

        uv = fract(uv * 1.5) - 0.5;

        float d = length(uv) * exp(-length(uv0));
        float wave = 8;
        d = sin(d * wave + time) / wave;
        d = abs(d);

        d = 0.01/d;

        finalCol += col * d;
    }

    return float4(finalCol, 1.0 );
}
