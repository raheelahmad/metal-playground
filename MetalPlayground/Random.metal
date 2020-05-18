//
//  Random.metal
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

float randomish(vector_float2 pos) {
    return fract(sin(dot(pos, vector_float2(122.9128, 79.212))) * 43292.574888129);
}

vector_float2 truchetPattern(vector_float2 _st, float _index) {
    _index = fract(((_index-0.5)*2.0));
    if (_index > 0.75) {
        _st = vector_float2(1.0) - _st;
    } else if (_index > 0.5) {
        _st = vector_float2(1.0-_st.x,_st.y);
    } else if (_index > 0.25) {
        _st = 1.0-vector_float2(1.0-_st.x,_st.y);
    }
    return _st;
}

vertex VertexOut vertexRandomShader(const device VertexIn *vertexArray [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexIn in = vertexArray[vid];
    VertexOut out;
    out.pos = float4(in.pos, 0, 1);
    return out;
}

fragment float4 fragmentRandomShader(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
    float x = interpolated.pos.x / uniforms.screen_width;
    float y = interpolated.pos.y / uniforms.screen_height;
    vector_float2 pos = vector_float2(x, y) ;
    pos *= 10;
    pos.x += uniforms.time * 3.0;
    vector_float2 ipos = floor(pos);
    vector_float2 fpos = fract(pos);
    float rand = randomish(ipos);
    vector_float2 val = truchetPattern(fpos, rand);
    float color = 0.0;
    color = smoothstep(val.x - 0.3, val.x, val.y) -
            smoothstep(val.x, val.x + 0.3, val.y);

//    vector_float3 col = vector_float3(rand);
//    vector_float3 col = vector_float3(fpos, 0);

    return vector_float4(vector_float3(color), 1);
}


