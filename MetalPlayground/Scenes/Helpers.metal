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

float circle(float2 st, float time, float rad, float2 center) {
    float variation =
    (1 + cos(time)) / 2.0
    ;
    float pct = distance(st, center);
    float dist = 1 - step(rad * variation, pct);
    return dist;
}
