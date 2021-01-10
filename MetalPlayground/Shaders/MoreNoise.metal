//
//  MoreNoise.metal
//  MetalPlayground
//
//  Created by Raheel Ahmad on 5/14/20.
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

vertex VertexOut moreNoiseVertexShader(const device VertexIn *vertices [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexOut in;
    in.pos = {vertices[vid].pos.x, vertices[vid].pos.y, 0, 1};
    return in;
}

fragment float4 moreNoiseFragmentShader(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
    float x = interpolated.pos.x / uniforms.screen_width;
    float y = interpolated.pos.y / uniforms.screen_height;

    vector_float3 color = vector_float3(0);

    // Cell positions
    vector_float2 points[4];
    points[0] = {0.39 * clamp(sin(uniforms.time), 0.1, 1.0), 0.25  * clamp(sin(uniforms.time), 0.1, 0.9)};
//    points[1] = {0.51 * sin(uniforms.time), 0.85 * cos(uniforms.time)};
    points[1] = {0.43, 0.75};
    points[2] = {0.23, 0.95};
    points[3] = {0.32, 0.45};

    float min_dist = 1;
    for (int i = 0; i < 4; i++) {
        float dist = distance(vector_float2(x, y), points[i]);
        min_dist = min(min_dist, dist);
    }

    if (min_dist < 0.01) {
        color = vector_float3(0.7, 0.2, 0.3);
    } else {
        color += min_dist;
    }

//    color -= step(0.7, abs(sin(50 * min_dist))) * 0.3;

    //    y = randomize(i);
    return float4(color, 1);
}
