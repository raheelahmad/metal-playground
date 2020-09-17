//
//  Raymarching.metal
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

vertex VertexOut raymarching_vertex(const device VertexIn *vertices [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexOut v;
    v.pos = float4(vertices[vid].pos, 0, 1);
    return v;
}

/*
 Camera:
 - uv: position on screen
 - pos: camera's position in 3d space
 - lookat, zoom: direction

 view-ray: given above, the ray from camera to the screen, and then in to the scene

 ray-intersection: given view-ray and objects, returns distance from camera to where it's intersecting

 materials&lighting: given distance & light, gives pixel color
 */

float rayMarch(float3 r0, float3 rd) {
    float d0 = 0;
    
}

// ---
fragment float4 raymarching_fragment(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
    float2 st = {
        interpolated.pos.x / uniforms.screen_width,
        1 - interpolated.pos.y / uniforms.screen_height
    };
    st -= 0.5;

    float3 col = {0.7, 0.5, 0.1};

    // camera
    float3 r0 = {0,1,0};
    float3 rd = normalize(float3(st.x, st.y, 1));

    return float4(col, 1);
}
