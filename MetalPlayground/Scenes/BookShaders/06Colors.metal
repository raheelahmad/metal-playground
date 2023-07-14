//
//  06Colors.metal
//  MetalPlayground
//
//  Created by Raheel Ahmad on 7/9/20.
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
    float2 mousePos;
};

struct VertexOut {
    float4 pos [[position]];
    float4 color;
};
//  Function from Iñigo Quiles
//  https://www.shadertoy.com/view/MsS3Wc
vector_float3 hsb2rgbf(vector_float3 c ){
    vector_float3 rgb = clamp(
                              abs(
                                  fmod(
                                      c.x*6.0+vector_float3(0.0,4.0,2.0), 6.0
                                  )
                                  -3.0)-1.0,
                     0.0,
                     1.0 );
    rgb = rgb*rgb*(3.0-2.0*rgb);
    return c.z * mix(vector_float3(1.0), rgb, c.y);
}



vertex VertexOut bos_colors_vertex(const device VertexIn *vertexArray [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexIn in = vertexArray[vid];
    VertexOut out;
    out.pos = float4(in.pos, 0, 1);
    return out;
}

fragment float4 bos_colors_fragment(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
    float2 st  = {interpolated.pos.x / uniforms.screen_width, 1 - interpolated.pos.y / uniforms.screen_height};

    st = float2(0.5) - st;
    st.x *= uniforms.screen_width/uniforms.screen_height;
//    st.y /= 2;
    float2 toCenter = st;

    float angleTimeOffset = float(int(uniforms.time * 100) % 360);
    angleTimeOffset = (angleTimeOffset / 360) * 2 * 3.14;

    float angle = atan2(toCenter.y, toCenter.x); // between -pi → +pi

    float angle2PI = (angle + angleTimeOffset)/(2 * 3.141);

    float hue = angle2PI;
    float saturation = length(toCenter) * 2.0; // extend length from max 0.5 to max 1.0

    hue = smoothstep(0.4, 0.8, hue);

    vector_float3 hsb = {hue, saturation, 1.0};
    vector_float3 col = hsb2rgbf(hsb);

    float4 color = float4(col, 1);
    return color;
}
