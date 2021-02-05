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
float filledArc(float2 p, float r, float a1, float a2);
float sdEquilateralTriangle(float2 p );
float sdTriangleIsosceles(float2 p, float2 q );
float sdVesica(float2 p, float r, float d);
float sdEgg( float2 p, float ra, float rb );
float star(float2 st, float time);
float rectangle(float2 uv, float4 box);
float random (float st);
float hash(float2 p);
float noise( float2 p );

#endif
