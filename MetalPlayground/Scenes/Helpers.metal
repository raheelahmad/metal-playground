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

float star(float2 st, float time) {
    float a = time;
    a = 0.;
    st = rotate(a) * st;
    float r = 0.2 + 0.1 * cos(atan2(st.y, st.x) * 10 + 25 * st.x);
    float t = smoothstep(r, r + 0.01, length(st));
    return t;
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
//    return smoothstep(r+0.005, r, length(uv));
    return 1-step(r, length(uv));
}

float circleOutline(float2 uv, float r, float th) {
    return circle(uv, r) - circle(uv, r - th);
}

float sdEquilateralTriangle(float2 p )
{
    const float k = sqrt(3.0);
    p.x = abs(p.x) - 1.0;
    p.y = p.y + 1.0/k;
    if( p.x+k*p.y>0.0 ) p = float2(p.x-k*p.y,-k*p.x-p.y)/2.0;
    p.x -= clamp( p.x, -2.0, 0.0 );
    return -length(p)*sign(p.y);
}

float sdTriangleIsosceles(float2 p, float2 q )
{
    p.x = abs(p.x);
    float2 a = p - q*clamp( dot(p,q)/dot(q,q), 0.0, 1.0 );
    float2 b = p - q*float2( clamp( p.x/q.x, 0.0, 1.0 ), 1.0 );
    float s = -sign( q.y );
    float2 d = min( float2( dot(a,a), s*(p.x*q.y-p.y*q.x) ),
                 float2( dot(b,b), s*(p.y-q.y)  ));
    return -sqrt(d.x)*sign(d.y);
}

float arc(float2 uv, float r, float angleSt, float angleEnd, float th) {
    float t = step(r-th/2, length(uv)) * step(length(uv), r + th/2);

    float a = atan2(uv.y,uv.x);
    if (a < 0) {
        a = a + 2*M_PI_F;
    }

    t *= step(angleSt, a) * step(a, angleEnd);
    return t;
}

float filledArc(float2 p, float r, float a1, float a2) {
    float a = atan2(p.y,p.x);
    if (a < 0) {
        a = a + 2*M_PI_F;
    }
    float semi1 = step(length(p), r);
    semi1 = semi1 * step(a1, a)
    * step(a, a2)
    ;
    return semi1;
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


float sdVesica(float2 p, float r, float d)
{
    p = abs(p);
    float b = sqrt(r*r-d*d);
    return ((p.y-b)*d>p.x*b) ? length(p-float2(0.0,b))
    : length(p-float2(-d,0.0))-r;
}

float sdEgg(float2 p, float ra, float rb )
{
    const float k = sqrt(3.0);
    p.x = abs(p.x);
    float r = ra - rb;
    return ((p.y<0.0)       ? length(float2(p.x,  p.y    )) - r :
            (k*(p.x+r)<p.y) ? length(float2(p.x,  p.y-k*r)) :
            length(float2(p.x+r,p.y    )) - 2.0*r) - rb;
}
