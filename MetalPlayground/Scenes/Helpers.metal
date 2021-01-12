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


float lerp(float x, float u, float v, float m, float n) {
    float prog = (x - u) / (v - u);
    return m + (n - m) * prog;
}

float lerpU(float x, float u, float v) {
    return lerp(x, u, v, 0.0, 1.0);
}

float circle(float2 uv, float r) {
    return smoothstep(r+0.01, r, length(uv));
}

float circleOutline(float2 uv, float r, float th) {
    return circle(uv, r) - circle(uv, r - th);
}

float arc(float2 uv, float r, float angleSt, float angleEnd, float th) {
    uv = rotate(M_PI_F) * uv;
    float angle = atan2(uv.y, uv.x);
    angle = lerp(angle, -M_PI_F, M_PI_F, 0, M_PI_F * 2.);
    if (angle < angleSt || angle > angleEnd) { return 0.; }
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
