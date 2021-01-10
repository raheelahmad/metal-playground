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

float2x2 scale(float2 _scale){
    return float2x2(_scale.x,0.0, 0.0,_scale.y);
}

float lerp(float x, float m, float n, float a, float b) {
    return a + (x-m)/(n-m) * (b - a);
}

float circle(float2 st, float time, float rad, float2 center) {
    float variation =
    (1 + cos(time)) / 2.0
    ;
    float pct = distance(st, center);
    float dist = 1 - step(rad * variation, pct);
    return dist;
}
