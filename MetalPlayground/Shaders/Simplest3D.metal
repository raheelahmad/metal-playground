//
//  Simplest3D.metal
//  MetalPlayground
//
//  Created by Raheel Ahmad on 9/17/20.
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

vertex VertexOut simplest_3d_vertex(const device VertexIn *vertices [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexOut v;
    v.pos = float4(vertices[vid].pos, 0, 1);
    return v;
}

float rayDist(float3 r0, float3 rd, float3 p) {
    if (length(rd) == 0) {
        return 0.2;
    }
    return length(cross(p - r0, rd)) / length(rd);
}

float drawPoint(float3 r0, float3 rd, float3 p) {
    float d = rayDist(r0, rd, p);
    d = smoothstep(0.06, 0.05, d);
    return d;
}

// ---
fragment float4 simplest_3d_fragment(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
    float2 st = {
        interpolated.pos.x / uniforms.screen_width,
        1 - interpolated.pos.y / uniforms.screen_height
    };
    st -= 0.5;

    float3 rayOrigin = {2,0,-4}; // camera pos


    float zoom = 1;

    // ray from camera to the screen point (and then in to the screen to hit an object)
    float3 lookAt = {0.5};
    float3 forward = normalize(lookAt - rayOrigin);
    float3 right = cross( float3(0, 1, 0), forward);
    float3 up = cross(forward, right);

    float3 screenCenter = rayOrigin + forward * zoom;

    float3 screenPoint = screenCenter + st.x * right + st.y * up;
    float3 rayDirection = screenPoint - rayOrigin;

    float d = 0;
    for (int z=0; z<=1; z++) {
        for (int y=0; y<=1; y++) {
            for (int x=0; x<=1; x++) {
                float3 p = {float(x),float(y),float(z)};
                d += drawPoint(rayOrigin, rayDirection, p);
            }
        }
    }

    float3 col = d;

    return float4(col, 1);
}
