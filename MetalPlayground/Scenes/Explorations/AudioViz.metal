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

float3 palette01(float t) {
    float3 a = float3(0.738, 0.870, 0.870);
    float3 b = float3(0.228, 0.500, 0.500);
    float3 c = float3(1.0, 1.0, 1.0);
    float3 d = float3(0.000, 0.333, 0.667);

    return a + b * cos(6.28318 * (c * t + d));
}

vertex VertexOut audioVizVertexShader(const device VertexIn *vertices [[buffer(0)]], unsigned int vid [[vertex_id]]) {
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


fragment float4 audioVizFragmentShader(
                                    VertexOut interpolated [[stage_in]],
                                    constant FragmentUniforms &uniforms [[buffer(0)]],
                                    const constant float *loudnessBuffer [[buffer(1)]],
                                    const constant float *frequenciesBuffer [[buffer(2)]]
                                       ) {

    float loudness = loudnessBuffer[0];
    float2 uv = {interpolated.pos.x / uniforms.screen_width, 1 - interpolated.pos.y/uniforms.screen_height};
    uv = 2 * (uv - 0.5);
    if (uniforms.screen_width > uniforms.screen_height) {
       uv.x *= uniforms.screen_width/uniforms.screen_height;
    } else {
       uv.y *= uniforms.screen_height/uniforms.screen_width;
    }

    float p = length(uv);
    float pa = atan2(uv.y, uv.x);

    // Frequency:
    // map -1 → 1 to 0 → 361
    // int index = int(lerp(uv.x, -1.0, 1.0, 0, 361));
    float indexRad = (0.5 * pa / 3.1415 + 1) / 2.0; // 0 → 1

    int index = lerp(indexRad, 0, 1, 0, 361);

    float freq = frequenciesBuffer[index];
    freq = sin(indexRad ) * freq;
    float o = 0;
    float inc = 0;

    float numRings = 7;
    float ringSpacing = 0.01;
    float ringThickness = 0.10;
    float rotationDistortion = 0.3;
    for (float i = 0; i < numRings; i += 1.0) {
       float baseR;
       baseR = 0.2 * sin(freq * 0.8);
       float r = baseR + inc;

       r += rotationDistortion * (0.5 + 0.1 * sin(pa * i + 0.3 * uniforms.time * (i - 0.1)));
//       r += loudness/4;
       r = min(0.8, r);
       o += drawCircle(r, p, ringThickness * (1.0 + 0.12 * freq * (i - 1.0)));

       inc += ringSpacing;
    }

    float3 bgCol = float3(0.9 - cos(uniforms.time/2) * 0.2 * uv.y, 0.12, 0.3 - sin(uniforms.time/2) * 0.2 * uv.y);
    float3 col = mix(bgCol, float3(1, 0.7, 0.3), o);

    return float4(col, 1);

}

