//
//  ShaderToySmiley.metal
//  MetalPlayground
//
//  Created by Raheel Ahmad on 7/14/20.
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

#define S(a, b, t) smoothstep(a, b, t)

float remap(float a, float b, float c, float d, float t) {
    float val = (t - a) / (b - a) * (d - c) + c;
    return clamp(val, 0.0, 1.0);
}

/// Normalize st within the box: if st.x == 0, it will be on left side; if st.y == 0, it will be on bottom side;
float2 within(float2 st, float4 rect) {
    return (st - rect.xy) / (rect.zw - rect.xy);
}

float4 head(float2 st) {
    // the color
    float4 col = float4(0.9, 0.65, 0.1, 1.0);
    // a light blur boundary before going to black
    float d = length(st);
    col.a = S(0.5, 0.49, d);

    // Give a blended edge before it fades to black
    // 1st map from 0.35 → 0.5 to 0 → 1
    float edgeShade = remap(0.35, 0.5, 0, 1, d);
    // we want a nice fall off, not a linear one
    edgeShade *= edgeShade;
    // invert and attenuate
    col.rgb *= 1 - edgeShade * 0.5;
    col.rgb = mix(col.rgb, float3(.6, .3, .1), S(.47, 0.48, d));

    // Upper highlight
    // ends at 0.41 (1 inside, 0 outside)
    float highlight = S(.41, .40, d) * .75;
    // fade it from 0 y to 0.41
    highlight = remap(0, 0.46, 0, highlight, st.y);
    // make it highlight(almost white) inside, and col.rgb outside
    col.rgb = mix(col.rgb, float3(1), highlight);

    // Something I was trying
//    d = length(st - float2(.1, .1));
//    float maxD = length(float2(.1,.1));
//    col.rgb = mix(float3(0.6, .0, .0), col.rgb, remap(0, maxD, 0, 1, d));

    d = length(st - float2(.25, -.2));
    float cheek = S(.18, .01, d) * .4;

    col.rgb = mix(col.rgb, float3(1, .1,.1), cheek);

    return col;
}

float4 eye(float2 st) {
    float d = length(st);

    float4 irisCol = float4(.3, .5, 1, .1);
    float4 col = mix(float4(1), irisCol, S(.1, .7, d) * .5);

    col.rgb *= 1 - S(.45, .5, d) * 0.5 * clamp(0., 1., -st.y - st.x);
    col.rgb = mix(col.rgb, 0, S(.3, .28, d));
    irisCol.rgb *= 1 + S(.3, .05, d);
    col.rgb = mix(col.rgb, irisCol.rgb, S(.28, .25, d));
    col.rgb = mix(col.rgb, 0, S(.15, .145, d));

    col.a = S(.5, .48, d);
    return col;
}

float4 mouth(float2 st) {
    st.y *= 1.4; // makes thinner; since y < 1
    st.y -= st.x * st.x * 2;
    float d = length(st);

    float4 col = {.8, .02, .05, 1};
    col.rgb *= mix(col.rgb, 0.3, S(0.5, 0.3, d));
    col.a = S(0.5, 0.49, d);
    return col;
}

float4 smiley(float2 st) {
    float4 col = 0;
    float4 hd = head(st);

    // Eye will be drawn in a box; subtract 0.5 to again go to -.5→.5 coordinates
    float2 eyeSt = within(st, float4(.03, -.1, .37, .25)) - 0.5;
    float4 ey = eye(eyeSt);
    // Mouth also will be drawn in a box
    float2 mouthSt = within(st, float4(-.3, -.3, .3, -.1)) - 0.5;
    float4 mth = mouth(mouthSt + float2(0, .4));

    // blend: if alpha is 1 will pick head, otherwise col (background)
    col = mix(col, hd, hd.a);
    col = mix(col, ey, ey.a);
    col = mix(col, mth, mth.a);
    return col;
}

fragment float4 shaderToySmiley(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
//    float t = uniforms.time;
    float2 st  = {interpolated.pos.x / uniforms.screen_width, 1 - interpolated.pos.y / uniforms.screen_height};
    st -= 0.5;
    st.x *= uniforms.screen_width / uniforms.screen_height;

    // draw what's on right, also on the left
    st.x = abs(st.x);

    float4 color = smiley(st);

    return color;
}
