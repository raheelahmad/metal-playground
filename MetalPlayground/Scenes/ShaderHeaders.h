//
//  ShaderHeaders.h
//  MetalPlayground
//
//  Created by Raheel Ahmad on 1/9/21.
//  Copyright © 2021 Raheel Ahmad. All rights reserved.
//

#ifndef MyDefs
#define MyDefs

float lerp(float x, float m, float n, float a, float b);
float2x2 rotate(float angle);
float2x2 scale(float2 _scale);

float circle(float2 uv, float r);
float circleOutline(float2 uv, float r, float th);
float circle(float2 st, float time, float rad, float2 center);
float arc(float2 uv, float r, float angleSt, float angleEnd, float th);
float rectangle(float2 uv, float4 box);
float random (float st);
float hash(float2 p);
float noise( float2 p );

#endif
