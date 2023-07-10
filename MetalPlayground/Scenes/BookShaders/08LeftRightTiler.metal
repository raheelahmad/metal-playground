//
//  07FuturisticUI.metal
//  MetalPlayground
//
//  Created by Raheel Ahmad on 12/31/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


struct VertexOut {
    float4 pos [[position]];
    float4 color;
};

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


float3 bricks(float2 uv, float time) {
    float zoom = 20.0;
    uv *= zoom;
    time *= 1.3;
    float horizontal = step(fmod(time, 4.0), 2.0);
    float offset = step(fmod(horizontal > 0 ? uv.x : uv.y, 2.0), 1.0) * 2.0 - 1.0;
    uv = fract(uv);

    uv = 2.0*uv - 1.;
    uv.y = -uv.y;

    float t = 0;

    uv.y += fmod(time , 2.0) * offset * horizontal;
    uv.x += fmod(time , 2.0) * offset * (1- horizontal);

    float side = 0.52;
    t += smoothstep(side,side-0.001, length(uv));

    if (horizontal > 0) {
        uv.y -= 2.0;
    } else {
        uv.x -= 2.0;
    }
    t += smoothstep(side,side-0.001, length(uv));
    if (horizontal > 0) {
        uv.y += 4.0;
    } else {
        uv.x += 4.0;
    }
    t += smoothstep(side,side-0.001, length(uv));
    return (1-t) * float3(0.8);
}

vertex VertexOut leftright_vertex(const device VertexIn *vertices [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexOut v;
    v.pos = float4(vertices[vid].pos, 0, 1);
    return v;
}

fragment float4 leftright_fragment(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
    float2 uv = {interpolated.pos.x / uniforms.screen_width, 1 - interpolated.pos.y/uniforms.screen_height};
    uv.x *= uniforms.screen_width / uniforms.screen_height;
    float time = uniforms.time;
    float3 col = bricks(uv, time);
    return float4( col, 1.0 );
}
