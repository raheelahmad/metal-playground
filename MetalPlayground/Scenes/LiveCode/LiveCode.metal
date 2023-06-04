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
    float loudness = loudnessBuffer[0];
    float2 uv = {interpolated.pos.x / uniforms.screen_width, 1 - interpolated.pos.y/uniforms.screen_height};
    uv = 2 * (uv - 0.5);

    float p = length(uv);
    float pa = atan2(uv.y, uv.x);

    // Frequency:
   // map -1 → 1 to 0 → 361
    // int index = int(lerp(uv.x, -1.0, 1.0, 0, 361));
    float indexRad = (pa / 3.1415 + 1) / 2.0; // 0 → 1

    int index = lerp(indexRad, 0, 1, 0, 361);

    float freq = frequenciesBuffer[index];
    freq = sin(indexRad * 3.1415) * freq;
    float o = 0;
    float inc = 0;
    for (float i = 0; i < 8; i += 1.0) {
        float baseR = 0.5 * (0.3 + (0.5 + 0.5 * sin(freq + uniforms.time * 0.1)));
        float r = baseR + inc;

        r += 0.01 * (0.5 + 0.5 * sin(pa * i + uniforms.time * (i - 0.0)));
        r += loudness/3;
        o += drawCircle(r, p, 0.008 * (1.0 + freq * (i - 1.0)));

        inc += 0.008;
    }

//    p = 1.0 - length(uv)*freq;
//    p = step(0.0, p);
    float3 bcol = float3(1.0, 0.22, 0.5 - 0.4 * uv.y) * (1.0 - 0.1 * p * freq/2);
    float3 col = mix(bcol, float3(1, 1, 0.7), o);

    return float4(col, 1);
}

