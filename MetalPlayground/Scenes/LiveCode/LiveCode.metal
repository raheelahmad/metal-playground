#include <metal_stdlib>
using namespace metal;
#include "../ShaderHeaders.h"

struct VertexIn {
    vector_float2 pos;
};

struct FragmentUniforms {
    float time;
    float screen_width;
    float screen_height;
    float screen_scale;
};

struct StampUniforms {
    float progress;
};

struct VertexOut {
    float4 pos [[position]];
    float4 color;
};

vertex VertexOut liveCodeVertexShader(const device VertexIn *vertices [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexOut in;
    in.pos = {vertices[vid].pos.x, vertices[vid].pos.y, 0, 1};
    return in;
}

// ---

float petal(float2 st, float r1, float r2) {
    float t = sdVesica(st, r1, r2);
    t = 0. - sign(t);
    return t;
}

float halfPetal(float2 st, float r1, float r2) {
    float t = sdVesica(st, r1, r2) * step(0, st.x);
    t = 0. - sign(t);
    return t;
}

float tulipPetal(float2 p, float r, int flipped, float progress) {
    // not a super useful way to build progress
    progress = lerp(progress, 0, 1, -0.2, 1.3);
    progress = 1.;

    float t = 0;
    float2 semi1P = p;
    float semi1Angle1 = flipped ? M_PI_F/2 : 0;
    float semi1Angle2 = flipped ? M_PI_F : M_PI_F/2;
    float semi1 = filledArc(semi1P, r, semi1Angle1, semi1Angle2);
    semi1 -= filledArc(semi1P - float2(0.00,0.00), r*(1.-progress), semi1Angle1, semi1Angle2);
    float semi2Angle1 = flipped ? 3*M_PI_F/2 : 0;
    float semi2Angle2 = flipped ? 2*M_PI_F : M_PI_F/2;
    float rotateAngle = flipped ? 0 : M_PI_F;
    float2 semi2P = flipped ? p + float2(r, 0) : p - float2(r, 0);
    semi2P = rotate(rotateAngle)*semi2P;
    float semi2 = filledArc(semi2P, r, semi2Angle1, semi2Angle2);
    semi2 -= filledArc(semi2P - float2(0.00,0.00), r*(1.-progress), semi2Angle1, semi2Angle2);
    t = semi1 + semi2;
    return t > 0 ? 1 : 0;
}

float4 leaf(float2 leafSt, float r1, float r2, float3 topCol, float3 bottomCol, int useBottom)  {
    leafSt -= float2(0.,sqrt(r1*r1 - r2*r2)); // position in the center-x of stem
    float t = petal(leafSt, r1, r2);
    float4 color = 0;
    color = mix(color, float4(topCol, 1), step(1., t));
    if (useBottom) {
        color = mix(color, float4(bottomCol, 1), step(1., halfPetal(leafSt, r1, r2)));
    }
    return color;
}

// ---

fragment float4 liveCodeFragmentShader(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]], constant StampUniforms &stampUniforms [[buffer(1)]]) {
    float yOverX = uniforms.screen_height / uniforms.screen_width;
    float2 uv = {interpolated.pos.x / uniforms.screen_width, 1 - interpolated.pos.y/uniforms.screen_height};
    float2 st = uv;

    float4 color = mix({0.7,0.7, 0.8,1.0}, {0.7,0.8, 0.5,1.0}, pow(st.y, .5));

    st -= 0.5;
    st *= 2;
    st.x /= yOverX;

    float progress = fract(uniforms.time/4);
    float t = 0;

    float petalR = 0.24;

    // TEST circle
    color = mix(color, float4(0.7,0.9,0.8,1), 1.-step(0.015, length(st)));

    // move up
    float2 petalSt = st;
    petalSt.y -= petalR;


    // triangle above petals
    t = sdTriangleIsosceles(petalSt-float2(0,0.3), {0.22,-0.3});
    t = 1.-smoothstep(0., 0.001, t);
    color = mix(color, float4(float3(0.1), 1.), t);


    // petals
    t = tulipPetal(petalSt + float2(petalR,-0.0), petalR, 0, progress);
    color = mix(color, float4(0.92,90./255., 60/255., 1), t);
    t = tulipPetal(petalSt - float2(petalR,-0.0), petalR, 1, progress);
    color = mix(color, float4(247/255,150./255., 181/255., 1), t);

    float3 green = {0.23, 0.39, 0.11};
    float3 black = {0.02, 0.09, 0.00};

    float stalkTH = 0.02;
    float2 stalkSt = petalSt-float2(0,-petalR);
    // stalk
    t = rectangle(stalkSt, {-stalkTH/2,0,stalkTH/2,-1.});
    color = mix(color, float4(0.1,0.1,0.1,1), step(1., t));

    float r1 = 0.11;
    float r2 = 0.07;
    float rotateLeaf = 1.5 * M_PI_F/2;

    // --- Small leaves on top
    // leaf 1
    float2 leafSt = rotate(rotateLeaf) * stalkSt; // position it down and rotate
    float4 leftSmallLeafCol = leaf(leafSt, r1, r2, green, black, 1);
    color = mix(color, leftSmallLeafCol, leftSmallLeafCol.a);
    // leaf 2
    float4 rightSmallLeafCol = leaf(rotate(-rotateLeaf) * stalkSt, r1, r2, green, black, 1);
    color = mix(color, rightSmallLeafCol, rightSmallLeafCol.a);

    r1 *= 2.1;
    r2 = 0.16;
    rotateLeaf -= M_PI_F/2;
    stalkSt += float2(0, 0.6);
    // leaf 1
    leafSt = rotate(rotateLeaf) * stalkSt; // position it down and rotate
    leafSt -= float2(0.,sqrt(r1*r1 - r2*r2)); // position in the center-x of stem
    t = petal(leafSt, r1, r2);
    color = mix(color, float4(green, 1), step(1., t));
    // leaf 2
    leafSt = rotate(-rotateLeaf) * stalkSt;
    leafSt -= float2(0.,sqrt(r1*r1 - r2*r2)); // position in the center-x of stem
    t = petal(leafSt, r1, r2);
    color = mix(color, float4(black, 1), step(1., t));

    // squiggly lines
//    leafSt = rotate(-rotateLeaf+M_PI_F/2) * stalkSt;
//    leafSt.x += sin(leafSt.y*310)/330;
//    float4 lineBox = {-0.003,0.,0.003,-0.166*progress};
//    color = mix(color, float4(black, 1), rectangle(leafSt, lineBox));
//
//    leafSt = rotate(rotateLeaf-M_PI_F/2) * stalkSt;
//    leafSt.x += sin(leafSt.y*310)/330;
//    color = mix(color, float4(green, 1), rectangle(leafSt, lineBox));

//    color = step(0.001, sdEquilateralTriangle(rotate(M_PI_F/2) * scale(0.02)*stalkSt));

    return color;
}
