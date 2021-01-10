//
//  MetalHeaders.h
//  MetalPlayground
//
//  Created by Raheel Ahmad on 7/11/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//


#ifndef METAL_CONSTANTS
#define METAL_CONSTANTS

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

struct VertexOut {
    float4 pos [[position]];
    float4 color;
};

enum class CircleKind { single, multiple };

float3 blurRect(float2 st, float time, float4 margins);

float3 rect(float2 st, float time, float4 margins, float3 mainColor);

float3 outlineRect(float2 st, float4 margins, float time);

float circle(float2 st, float time, float rad, float2 center);

float remap(float a, float b, float c, float d, float t);

#endif
