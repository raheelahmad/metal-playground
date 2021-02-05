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

float petal(float2 st, float r1, float r2, float thinness) {
    float t = sdVesica(st, r1, thinness/10);
    t = 1. - step(r2, t);
    return t;
}

float tulipPetal(float2 p, float r, int flipped, float progress) {
    progress = lerp(progress, 0, 1, 0.0, 1.3);
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
//    arc(semi2P, r, semi2Angle1, semi2Angle2, 0.01);
    t = semi1 + semi2;
    return t > 0 ? 1 : 0;
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

    // move up
    st.y -= 0.3;

    float progress = fract(uniforms.time/4);
    float petalR = 0.18;

    // triangle above petals
    float t = sdTriangleIsosceles(st-float2(0,0.2), {0.12,-0.2});
    t = 1.-smoothstep(0., 0.001, t);
    color = mix(color, float4(float3(0.1), 1.), t);


    // petals

    t = tulipPetal(st + float2(petalR,-0.0), petalR, 0, progress);
    color = mix(color, float4(0.92,90./255., 60/255., 1), t);
    t = tulipPetal(st - float2(petalR,-0.0), petalR, 1, progress);
    color = mix(color, float4(247/255,150./255., 181/255., 1), t);

    return color;
}
