//
//  07FuturisticUI.metal
//  MetalPlayground
//
//  Created by Raheel Ahmad on 12/31/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#include "../ShaderHeaders.h"

struct VertexOut {
    float4 pos [[position]];
    float4 color;
};

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

// --- Primitives

// box: left, top, right, bottom
float3 rectangle(float2 uv, float4 box, float3 color) {
    float d = 0.001;
    float left = smoothstep(box.x, box.x+d, uv.x);
    float top = smoothstep(box.y+d, box.y, uv.y);
    float right = smoothstep(box.z+d, box.z, uv.x);
    float bottom = smoothstep(box.w, box.w+d, uv.y);

    return
    (left*top * right*bottom) * color;
}

float circleSmooth(float2 uv, float r) {
    return smoothstep(r+0.01, r, length(uv));
}

float triangle(float2 uv) {
    // Number of sides of your shape
    int N = 3;

    // angle progress for this pixel
    float a = atan2(uv.x,uv.y);
    // Angle / polygon's side
    float r = (M_PI_F*2.0)/float(N);

    // Shaping function that modulate the distance
    float d = cos(
                  floor(.5 + a/r)
                  *r
                  -a
                  )*
    length(uv);

    return 1.0-smoothstep(.4,.4001,d);
    // color = vec3(d);
}


// --- Transformation

// --- Shapes

float circleOutline(float2 uv, float r, float th) {
    return circleSmooth(uv, r) - circleSmooth(uv, r - th);
}

float wedge(float2 uv, float r, float s, float e) {
    float angle = atan2(uv.y, uv.x);
    float modulate = smoothstep(s, e, angle) * (1. - step(e, angle)) * 0.6;
    return circleSmooth(uv, r) * modulate;
}

float arc(float2 uv, float r, float angleSt, float angleEnd, float th) {
    uv = rotate(M_PI_F) * uv;
    float angle = atan2(uv.y, uv.x);
    angle = lerp(angle, -M_PI_F, M_PI_F, 0, M_PI_F * 2.);
    if (angle < angleSt || angle > angleEnd) { return 0.; }
    return circleOutline(uv, r, th);
}

float animatedArc(float2 uv, float r, float time) {
    uv = rotate(M_PI_F/2.) * uv;
    return arc(uv, r, -M_PI_F, lerp(sin(time), -1.,1., -M_PI_F, M_PI_F ), 0.01);
}

// --- Scene

float3 fui(float2 uv, float time) {
    float anim = sin(time);
    float3 dark = 0.4;
    float3 light = 0.9;
    float originalR = 0.8;
    float r = originalR;
    float d = 0.07;
    d = d/2.;
    float arcSpan = M_PI_F/4.0;
    float outerTH = 0.01;
    float outerLightArc =
    arc(rotate(-M_PI_F/4.0-0.0)*uv, r, d, arcSpan - d, outerTH)
    +
    arc(uv, r, d, arcSpan - d, outerTH)
    +
    arc(rotate(M_PI_F*0.75)*uv, r, d, arcSpan - d, outerTH)
    +
    arc(rotate(M_PI_F*1.0)*uv, r, d, arcSpan - d, outerTH)
    ;
    float outerDarkArc =
    arc(rotate(M_PI_F*0.25)*uv, r, d, arcSpan - d, outerTH)
    +
    arc(rotate(M_PI_F*0.5)*uv, r, d, arcSpan - d, outerTH)
    +
    arc(rotate(M_PI_F*1.25)*uv, r, d, arcSpan - d, outerTH)
    +
    arc(rotate(M_PI_F*1.5)*uv, r, d, arcSpan - d, outerTH)
    ;
    float3 outerArc = outerLightArc * light
    + outerDarkArc * dark
    ;

    r -= 0.1;
    float smallArcAnimD = lerp(anim, -1., 1., 0., 0.4);
    float outerSmallArcs = 0;
    for (int i=0; i<2; i++) {
        float rotateAngle = M_PI_F * (i+0.25);
        outerSmallArcs +=
        arc(rotate(rotateAngle - smallArcAnimD)*uv,
            r,
            d - smallArcAnimD/2.0,
            arcSpan*2.0 - d + 2.*smallArcAnimD,
            outerTH/2.0
            );
    }
    // +
    // arc(rotate(M_PI_F*1.25)*uv, r, d + smallArcAnimD, arcSpan*2 - d, outerTH/2.0);
    float3 outerSmallArc = outerSmallArcs * dark;

    r -= 0.07;
    float3 middleCircle =
    circleOutline(uv, r, outerTH*0.8) * light;

    float grid =
    // smoothstep(0.0031, 0.003, abs(uv.y))
    // +
    // smoothstep(0.0031, 0.003, abs(uv.x))
    // +
    smoothstep(0.0031, 0.003, abs(uv.x - uv.y))
    +
    smoothstep(0.0031, 0.003, abs(uv.y + uv.x))
    ;
    grid *= 1.0 - step(r, length(uv));

    float3 innerCircles =
    (circleOutline(uv, r-0.2, outerTH*0.8)
     +
     circleOutline(uv, r-0.4, outerTH*0.8))
    * dark;

    float triOffset = originalR + lerp(anim, -1.,1., 0.06,-0.06);
    float2 triUV = abs(uv);
    triUV.y -= triOffset;

    triUV = scale(.021)*triUV;
    float triTop = triangle(triUV);
    triUV = abs(uv);
    triUV.x -= triOffset;
    triUV = rotate(-M_PI_F/2.) * scale(.021)*triUV;
    float triRight = triangle(triUV);

    // move in elliptical angles
    float redOffsetAngle = lerp(fract(time/42.), -1., 1., 0, -4.*M_PI_F);
    float redOffsetRad = -0.01 * redOffsetAngle + sin(redOffsetAngle)*cos(redOffsetAngle);
    float redOffsetY = redOffsetRad*sin(redOffsetAngle);
    float redOffsetX = redOffsetRad*cos(redOffsetAngle);
    float2 redOffset = {redOffsetX, redOffsetY};
    float redBigCircleRad = 0.2 * fract(time*1.2);
    float redBigCircleTH = 0.04;
    float2 redBigCircleUV = uv - redOffset;
    float redBigCircleT = circleOutline(redBigCircleUV, redBigCircleRad, redBigCircleTH);
    redBigCircleT *= smoothstep(redBigCircleRad - redBigCircleTH, redBigCircleRad, length(redBigCircleUV));
    float3 pulseColor = float3(0.76,0.34,0.03);
    float3 redBigCircle = redBigCircleT * pulseColor;

    float3 pulseSmallStaticCircle = circleOutline(redBigCircleUV, 0.015, 0.005) * pulseColor;
    float smallPulseDuration = step(0.0, (sin(anim*40.))/4.0);
    float3 pulseSmallPulsingCircle = circleSmooth(redBigCircleUV, 0.007) * smallPulseDuration * pulseColor;

    // float radarAngle = lerp(anim, -1.0, 1.0, 0, 2*M_PI_F);
    float radarSpan = 0.5;
    float radarRotate = time*4.2/(2*M_PI_F);
    float2 radarUV = rotate(radarRotate)*uv;
    float radarArcT = wedge(radarUV, r, 0.0, radarSpan);
    float3 radarArc = radarArcT * light;

    return outerArc + outerSmallArc + middleCircle + innerCircles
    + triTop
    + triRight

    + grid * dark/3.0
    + redBigCircle
    + pulseSmallStaticCircle
    + pulseSmallPulsingCircle
    + radarArc
    ;
}

float3 scene(float2 uv, float time) {
    return fui(uv, time);

    // return wedge(uv, 0.3, 0.0, 0.9);
}


vertex VertexOut futuristic_UI_vertex(const device VertexIn *vertices [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexOut v;
    v.pos = float4(vertices[vid].pos, 0, 1);
    return v;
}

fragment float4 futuristic_UI_fragment(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
    float2 uv = {interpolated.pos.x / uniforms.screen_width, 1 - interpolated.pos.y/uniforms.screen_height};
    uv -= 0.5;
    uv *= 2;
    uv.x *= uniforms.screen_width / uniforms.screen_height;
    float time = uniforms.time;
    float3 col = scene(uv, time);
    return float4( col, 1.0 );
}
