//
//  01ShaderToy.metal
//  MetalPlayground
//
//  Created by Raheel Ahmad on 7/13/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

#include <metal_stdlib>

using namespace metal;

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

float circleToy(float2 st, float2 pos, float r, float blur) {
    float color = smoothstep(r, r - blur, length(st - pos));
    return color;
}

vertex VertexOut shape_vertex(const device VertexIn *vertexArray [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexIn in = vertexArray[vid];
    VertexOut out;
    out.pos = float4(in.pos, 0, 1);
    return out;
}

float smiley(float2 st, float2 pos, float size) {
    st -= pos; // translating the coordinate system
    st /= size; // scale the coordinate system
    float faceBackground = circleToy(st, {0, 0}, 0.4, 0.01);
    float eye1 = circleToy(st, {-0.13, 0.1}, 0.05, 0.01);
    float eye2 = circleToy(st, {0.13, 0.1}, 0.05, 0.01);

    float mask = faceBackground - eye1 - eye2; // remove from big circle

    float mouth = circleToy(st, {0.0, -0.15}, 0.2, 0.014);
    mouth -= circleToy(st, {0.0, -0.10}, 0.2, 0.014);
    mouth = max(0.0, mouth);

    mask -= mouth;

    return mask;
}

float band(float t, float start, float end, float blur) {
    return
    smoothstep(start - blur, start + blur, t)
    *
    (1 - smoothstep(end - blur,  end + blur, t))
    ;
}

float rect(float2 st, float left, float right, float bottom, float top, float blur) {
    return
    band(st.x, left, right, blur)
    *
    band(st.y, bottom, top, blur)
    ;
}

float lerp(float t, float a, float b, float c, float d) {
    return c + (t - a) / (b - a) * (d - c);
}

float snake(float2 st, float time) {
    float x = st.x;
    float y = st.y;

    float m = sin(x*18 + time) * 0.3 * (0.5 + x);
    y -= m;
    float blur = lerp(x, -0.5, 0.5, 0.01, 0.25);
    blur = pow(blur * 3, 3);
    st = {x, y};
    float mask = rect(st, -0.5, 0.5, -0.1, 0.1, blur);
    return mask;
}

fragment float4 shadertoy01(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
    float t = uniforms.time;
    float2 st  = {interpolated.pos.x / uniforms.screen_width, 1 - interpolated.pos.y / uniforms.screen_height};
    st -= 0.5;
    st.x *= uniforms.screen_width / uniforms.screen_height;


    float3 mainColor = float3(0.9, 0.9, 0.0);
    float mask = snake(st, t);
    float3 color = float3(1) * mask;
    color *= mainColor;

    return vector_float4(color, 1.0);
}
