//
//  QuizlesHappyJumping.metal
//  MetalPlayground
//
//  Created by Raheel Ahmad on 9/15/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 pos [[position]];
    float4 color;
};

typedef struct {
    float time;
    float3 appResolution;
} CustomUniforms;

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

vertex VertexOut raymarching_scratch_vertex(const device VertexIn *vertexArray [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexIn in = vertexArray[vid];
    VertexOut out;
    out.pos = float4(in.pos, 0, 1);
    return out;
}

fragment float4 raymarching_scratch_fragment( VertexOut in [[stage_in]],
                                         texture2d<float> baseColorTexture [[texture(10)]],
                                             texture2d<float> overlayColorTexture [[texture(11)]],
                               constant FragmentUniforms &uniforms [[buffer( 0 )]] )
{
    float2 resolution = float2(uniforms.screen_width, uniforms.screen_height);
    float2 p = in.pos.xy / resolution;
    p.y = 1 - p.y;

    float3 finalCol = 0.0;

    // --- Step, etc.
    float3 red = float3(0.42, 0.12, 0.1);
    float3 blue = float3(0.12, 0.21, 0.6);
//    finalCol = mix(red, blue, p.x);
    float t = step(0.5, p.y);
    float3 top = mix(red, blue, smoothstep(0, 1, p.x));
    float3 bottom = mix(red, blue, p.x);
//    finalCol = mix(top, bottom, t);

    // fract & friends
    float2 pf = p;
    pf = (pf - 0.5);
    float cellPixelWidth = 100;
    float2 cell = fract(pf * resolution / cellPixelWidth);
    cell = abs(cell - 0.5);
    float distToCell = 1.0 - 2 * max(cell.x, cell.y);
    float cellLine = smoothstep(0, 0.03, distToCell);

    float xAxis = smoothstep(0.0, 0.002, abs(pf.y - 0.0));
    float yAxis = smoothstep(0.0, 0.002, abs(pf.x - 0.0));
    float yEqualX = smoothstep(0.0, 0.005, abs(pf.x - pf.y));
    finalCol = float(1);
    finalCol = mix(red, finalCol, cellLine);
    finalCol = mix(blue, finalCol, xAxis);
    finalCol = mix(blue, finalCol, yAxis);
    finalCol = mix(blue, finalCol, yEqualX);

    // --- Texture sampling with two images:
    float2 uv = p;
    constexpr sampler textureSampler(filter::nearest, mip_filter::linear, max_anisotropy(8), address::repeat);
    float3 baseColor = baseColorTexture.sample(textureSampler, uv).rgb;
    float4 overlayColor = overlayColorTexture.sample(textureSampler, uv);
//    finalCol = mix(baseColor, overlayColor.rgb, overlayColor.w);


    return float4(finalCol, 1.0 );
}
