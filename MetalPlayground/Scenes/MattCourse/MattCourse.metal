//
//  MattCourse.metal
//  MetalPlayground
//
//  Created by Raheel Ahmad on 8/2/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
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

typedef enum {
    Sketch1 = 0,
    Sketch2 = 1
} SketchKind;

struct FragmentUniforms {
    float time;
    float screen_width;
    float screen_height;
    float screen_scale;
    float2 mousePos;
};

struct MattCourseUniforms {
    float kind;
};

vertex VertexOut matt_course_vertex(const device VertexIn *vertexArray [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexIn in = vertexArray[vid];
    VertexOut out;
    out.pos = float4(in.pos, 0, 1);
    return out;
}

fragment float4 matt_course_fragment(
                               VertexOut interpolated [[stage_in]],
                               constant FragmentUniforms &uniforms [[buffer(0)]],
                               constant MattCourseUniforms &repeating_uniforms [[buffer(1)]]
                               ) {
    float t = uniforms.time;
//    float2 st  = {interpolated.pos.x / uniforms.screen_width, 1 - interpolated.pos.y / uniforms.screen_height};
//
    float3 color = 0.5;

    if (repeating_uniforms.kind == Sketch1) {
        color = float3(sin(t),.1, .9);
    } else if (repeating_uniforms.kind == Sketch2) {
        color = float3(.9,.1, .9);
    }

    return vector_float4(color, 1.0);
}
