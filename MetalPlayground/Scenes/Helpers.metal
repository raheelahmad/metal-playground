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

// -- transformations

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

// -- operations

float lerp(float x, float u, float v, float m, float n) {
    float prog = (x - u) / (v - u);
    return m + (n - m) * prog;
}

float lerpU(float x, float u, float v) {
    return lerp(x, u, v, 0.0, 1.0);
}

// --- Random and Noise

float random (float st) {
    return fract(sin(dot(float2(st,st), float2(12.9898,78.233)))*
                 43758.5453123);
}

float hash(float2 p)  // replace this by something better
{
    p  = 50.0*fract( p*0.3183099 + float2(0.71,0.113));
    return -1.0+2.0*fract( p.x*p.y*(p.x+p.y) );
}

float noise( float2 p )
{
    float2 i = floor( p );
    float2 f = fract( p );

    float2 u = f*f*(3.0-2.0*f);

    return mix( mix( hash( i + float2(0.0,0.0) ),
                    hash( i + float2(1.0,0.0) ), u.x),
               mix( hash( i + float2(0.0,1.0) ),
                   hash( i + float2(1.0,1.0) ), u.x), u.y);
}

// -- shapes

float circle(float2 uv, float r) {
    return smoothstep(r+0.0001, r, length(uv));
}

float circleOutline(float2 uv, float r, float th) {
    return circle(uv, r) - circle(uv, r - th);
}

float arc(float2 uv, float r, float angleSt, float angleEnd, float th) {
    uv = rotate(M_PI_F) * uv;
    float angle = atan2(uv.y, uv.x);
    angle = lerp(angle, -M_PI_F, M_PI_F, 0, M_PI_F * 2.);
    if (angleSt < angleEnd) {
        if (angle < angleSt || angle > angleEnd) { return 0.; }
    } else {
        if (angle > angleSt || angle < angleEnd) { return 0.; }
    }
    return circleOutline(uv, r, th);
}

// box: left, top, right, bottom
float rectangle(float2 uv, float4 box) {
    float d = 0.001;
    float left = smoothstep(box.x, box.x+d, uv.x);
    float top = smoothstep(box.y+d, box.y, uv.y);
    float right = smoothstep(box.z+d, box.z, uv.x);
    float bottom = smoothstep(box.w, box.w+d, uv.y);

    return
    (left*top * right*bottom);
}

