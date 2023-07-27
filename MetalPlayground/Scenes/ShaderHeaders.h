//
//  ShaderHeaders.h
//  MetalPlayground
//
//  Created by Raheel Ahmad on 1/9/21.
//  Copyright © 2021 Raheel Ahmad. All rights reserved.
//

#ifndef MyDefs
#define MyDefs

float absSin(float t);
float lerp(float x, float m, float n, float a, float b);
float2x2 rotate(float angle);
float2x2 scale(float2 _scale);
float circle(float2 st, float time, float rad, float2 center);
float getDistanceToCylinder(float3 point);
float getDistanceToCapsule(float3 point);
float getDistanceToTorus(float3 point);
float getDistanceToBox(float3 point);
float getDistanceToPlane(float3 point);
float subtractSDFs(float a, float b);
float intersectSDFs(float a, float b);
float unionSDFs(float a, float b);
float blendSDFs(float a, float b, float t);
float smoothUnionSDFs( float a, float b, float k);

#endif
