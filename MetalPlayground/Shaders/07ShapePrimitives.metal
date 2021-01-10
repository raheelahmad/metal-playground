//
//  07ShapePrimitives.metal
//  MetalPlayground
//
//  Created by Raheel Ahmad on 7/11/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

float3 blurRect(float2 st, float time, float4 margins) {
    float blur = (1 + sin(time * 10))/2 * 0.04;
    float2 left_bottom = smoothstep({margins[1], margins[2]}, {margins[1] + blur, margins[2] + blur}, st);
    float2 right_top = smoothstep({margins[3], margins[0]}, {margins[3] + blur, margins[0] + blur}, 1 - st);

    float visibility = left_bottom.x * left_bottom.y * right_top.x * right_top.y;

    float3 color = visibility * float3(0.5, 0.1, 0.9);
    return color;
}

float3 rect(float2 st, float time, float4 margins, float3 mainColor) {
    float2 left_bottom = step({margins[1], margins[2]}, st);
    float2 right_top = step({margins[3], margins[0]}, 1 - st);

    float visibility = left_bottom.x * left_bottom.y * right_top.x * right_top.y;

    float3 color = visibility * mainColor;
    return color;
}

float3 outlineRect(float2 st, float4 margins, float time) {
    float thickness = 0.01;
    float4 innerMargins = margins + thickness;

    float2 left_bottom = step({margins[1], margins[2]}, st);
    float2 right_top = step({margins[3], margins[0]}, 1 - st);

    float2 left_bottom_inner = step({innerMargins[1], innerMargins[2]}, st);
    float2 right_top_inner = step({innerMargins[3], innerMargins[0]}, 1 - st);

    float visibility_outer = left_bottom.x * left_bottom.y * right_top.x * right_top.y;
    float visibility_inner = left_bottom_inner.x * left_bottom_inner.y * right_top_inner.x * right_top_inner.y;

    float visibility = visibility_outer * (1 - visibility_inner);

    float3 color = visibility * float3(0.5, 0.1, 0.9);
    return color;
}

