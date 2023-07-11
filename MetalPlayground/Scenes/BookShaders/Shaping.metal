//
//  Shaping.metal
//  MetalPlayground
//
//  Created by Raheel Ahmad on 7/10/23.
//  Copyright © 2023 Raheel Ahmad. All rights reserved.
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

typedef enum {
    Bezier = 0,
    FlowingCurves = 1,
} SketchKind;

struct ShapingUniforms {
    float kind;
};


vertex VertexOut bos_shaping_vertex(const device VertexIn *vertexArray [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexIn in = vertexArray[vid];
    VertexOut out;
    out.pos = float4(in.pos, 0, 1);
    return out;
}

float bezier(float2 uv, float a, float b) {
    float epsilon = 0.00001;
    float x = uv.x;
    a = max(0.0, min(1.0, a));
    b = max(0.0, min(1.0, b));
    if (a == 0.5){
        a += epsilon;
    }

    // solve t from x (an inverse operation)
    float om2a = 1 - 2*a;
    float t = (sqrt(a*a + om2a*x) - a)/om2a;
    float y = (1.0-2*b)*(t*t) + (2*b)*t;
    return y;
    return 0.0;
}

fragment float4 bos_shaping_fragment(
                               VertexOut interpolated [[stage_in]],
                               constant FragmentUniforms &uniforms [[buffer(0)]],
                               constant ShapingUniforms &shapingUniforms [[buffer(1)]]
                               )
{
    float t = uniforms.time;
    float2 st  = {interpolated.pos.x / uniforms.screen_width, interpolated.pos.y / uniforms.screen_height};

    float3 color;
    float d = 0;
    if (shapingUniforms.kind == Bezier) {
        st.y = 1 - st.y;
        st.x *= uniforms.screen_width / uniforms.screen_height;
        st.x = fract(st.x * 12 + t);
        d = bezier(st, 0.082, 0.89);
        d = step(d, st.y);
        color = min(d, step(0.5, st.y));
    } else if (shapingUniforms.kind == FlowingCurves) {
        float l = 0.3 + 0.2 * (1. + sin(t))/4;
        for (int i=0; i<3; i++) {
            float2 uv = st;
            uv.x *= sin(uv.x + uv.y) + uv.y + sin(t * 1.1) / 15;
            uv.y *= sin(uv.y) + uv.x + cos(t * 1.4) / 4;
            l += sin(t * i) + 0.2 * length(uv);
            color[i] = l;
        }
    } else {
        color = 0.3;
    }

    return vector_float4(color, 1.0);
}
