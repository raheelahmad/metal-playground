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

struct VertexOut {
    float4 pos [[position]];
    float4 color;
};

float3 palette(float t) {
    float3 a = float3(0.738, 0.870, 0.870);
    float3 b = float3(0.228, 0.500, 0.500);
    float3 c = float3(1.0, 1.0, 1.0);
    float3 d = float3(0.000, 0.333, 0.667);

    return a + b * cos(6.28318 * (c * t + d));
}

vertex VertexOut liveCodeVertexShader(const device VertexIn *vertices [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexOut in;
    in.pos = {vertices[vid].pos.x, vertices[vid].pos.y, 0, 1};
    return in;
}

struct LiveCodeUniforms {
    uint samplesCount;
};

float sin01(float v)
{
    return 0.5 + 0.5 * sin(v);
}

float drawCircle(float r, float polarRadius, float thickness)
{
    return     smoothstep(r, r + thickness, polarRadius) -
            smoothstep(r + thickness, r + 2.0 * thickness, polarRadius);
}


fragment float4 liveCodeFragmentShader(
                                       VertexOut interpolated [[stage_in]],
                                       constant FragmentUniforms &uniforms [[buffer(0)]],
                                       const constant float *loudnessBuffer [[buffer(1)]],
                                       const constant float *frequenciesBuffer [[buffer(2)]]
) {
    float2 uv = {interpolated.pos.x / uniforms.screen_width, 1 - interpolated.pos.y/uniforms.screen_height};

//    float2 st = 2 * (uv - 0.5);

    float3 color = float3(0);
    int index = int(lerp(uv.x, 0.0, 1.0, 0, 360));
    float freq = frequenciesBuffer[index];
    float p = freq;

    color = float3(p, 0, p/2);

    return float4(color, 1);
}

