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

vertex VertexOut liveCodeVertexShader(const device VertexIn *vertices [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexOut in;
    in.pos = {vertices[vid].pos.x, vertices[vid].pos.y, 0, 1};
    return in;
}

// MARK: - Fragment Shader


fragment float4 liveCodeFragmentShader(
                                       VertexOut interpolated [[stage_in]],
                                       constant FragmentUniforms &uniforms [[buffer(0)]]
) {
    float2 uv = 2 * (float2(
       interpolated.pos.x / uniforms.screen_width,
       1 - interpolated.pos.y / uniforms.screen_height
    ) - 0.5);

    float3 color = float3(0);

    return float4(color, 1.0);
}

