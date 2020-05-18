//
//  Shaders.metal
//  MetalPlayground
//
//  Created by Raheel Ahmad on 5/12/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

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

float plot(float2 st, float pct) {
    return smoothstep(pct - 0.02, pct, st[1]) - smoothstep(pct, pct + 0.02, st[1]);
}

float3 rgb2hsb(float3 c ){
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 p = mix(float4(c.bg, K.wz),
                 float4(c.gb, K.xy),
                 step(c.b, c.g));
    float4 q = mix(float4(p.xyw, c.r),
                 float4(c.r, p.yzx),
                 step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)),
                d / (q.x + e),
                q.x);
}

//  Function from Iñigo Quiles
//  https://www.shadertoy.com/view/MsS3Wc
float3 hsb2rgb(float3 c ){
    float3 rgb = clamp(abs(fmod(c.x*6.0+float3(0.0,4.0,2.0),
                             6.0)-3.0)-1.0,
                     0.0,
                     1.0 );
    rgb = rgb*rgb*(3.0-2.0*rgb);
    return c.z * mix(float3(1.0), rgb, c.y);
}


// ---

vertex VertexOut vertexShader(const device VertexIn *vertexArray [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexIn in = vertexArray[vid];
    VertexOut out;
    out.pos = float4(in.pos, 0, 1);
    return out;
}

struct RectInfo {
    vector_float4 borders;
    float3 col;
};

// ---

vector_float3 rectangle(RectInfo info, float x, float y) {
    vector_float4 borders = info.borders;
    float left = step(borders[0], x);
    float bottom = step(1 - borders[1], y);

    float right = step(1 - borders[2], 1 - x);
    float top = step(borders[3], 1 - y);

    float pct1 = left * bottom * right * top;
    return pct1 > 0 ? info.col : 0;
}

fragment float4 fragmentShader(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
    float x = interpolated.pos.x / uniforms.screen_width;
    float y = 1 - interpolated.pos.y / uniforms.screen_height;

    RectInfo border1 = { {0.0, 0.18, 0.1, 0.0 }, {0.9, 0.0, 0.1}};
    RectInfo border2 = { {0.12, 0.18, 0.2, 0.0 }, {0.9, 0.0, 0.1}};
//    RectInfo border2 = { {0.8, 0.2, 0.1, 0.1}, {0.1, 0.8, 0.9}};
//    RectInfo border3 = { {0.8, 0.2, 0.1, 0.1}, {0.1, 0.8, 0.9}};
    vector_float3 pct1 = max( rectangle(border1, x, y), rectangle(border2, x, y));
//    vector_float3 color = vector_float3(left * bottom);
    return vector_float4(pct1, 1);
}

fragment float4 fragmentShaderRadialHSB(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
    float x = interpolated.pos.x / uniforms.screen_width;
    float y = 1 - interpolated.pos.y / uniforms.screen_height;
    float3 col = float3(0);

    vector_float2 toCenter = vector_float2(0.5) - vector_float2(x, y);
    float angle = atan2(toCenter.x, toCenter.y);
    float radius = length(toCenter) * 2.0;
    col = hsb2rgb(float3((angle/ (2 * 3.14)) + 0.5, radius, 1.0));

    return float4(col, 1);
}

fragment float4 fragmentShaderVerticalHSB(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
    float x = interpolated.pos.x / uniforms.screen_width;
    float y = interpolated.pos.y / uniforms.screen_height;
    float3 col = float3(x, 1, 1-y);
    return float4(hsb2rgb(col), 1);
}

fragment float4 fragmentShaderPlot(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
    float original_x = interpolated.pos.x / (uniforms.screen_width);
    float original_y = interpolated.pos.y / (uniforms.screen_height);
    float2 st = float2(original_x, original_y);

    float y = sin(original_x);

    float pct = plot(st, y);

    float3 color = float3(y);
    color = (1.0 - pct) * color + pct * float3(0,1,0);

    return float4(color, 1);
}
