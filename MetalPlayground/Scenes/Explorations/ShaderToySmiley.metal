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

float random1(float2 st) {
    return fract(sin(st.x * 0.122190) * 21001.);
}

float lerp2(float a, float b, float m, float n, float t) {
    return saturate(m + (t - a) / (b - a) * (n - m));
}

float2 within(float2 st, float4 rect) {
    // Like mapping but inside a rect
    return (st - rect.xy)/(rect.zw - rect.xy);
}

float Circle(float2 st, float2 pos, float r, float blur) {
    st -= pos;
    float c = smoothstep(r, r - blur, length(st));
    return c;
}

float4 Head(float2 st) {
    float d = length(st);

    float4 col = float4(0.9, 0.6, 0.1, 1.);

    // add shadow to the edge
    float edgeShadow = smoothstep(0.35, 0.5, d);
    edgeShadow *= edgeShadow;
    col.rgb *= 1.0 - edgeShadow * 0.2;

    // make everything go inside a circle of 0.5 radius
    col.a = smoothstep(0.5, 0.5 - 0.001, d);

    /// top highlight
    // white inner circle of r=0.41
    float highlight = smoothstep(0.41, 0.405, d);
    // circle is light white (0.75 at 0.41, vanishes at -0.1)
    highlight *= lerp2(0.41, -0.1, 0.75, 0., st.y);
    col.rgb = mix(col.rgb, float3(1), highlight);

    /// Cheek
    // on both sides
    st.x = abs(st.x);
    // new d for cheek position
    float2 cheekPos = {0.25, -0.2};
    d = length(st - cheekPos);
    // the gradient
    float cheek = smoothstep(0.2, 0.0, d);
    cheek *= cheek;
    col.rgb = mix(col.rgb, float3(1.0,0.3,0.1), cheek);

    return col;
}


float4 Eye(float2 st) {
    // receives in 0 → 1
    st -= 0.5;

    float d = length(st);
    float4 irisCol = float4(.3,.5,1,1);
    // goes from white at .1 to irisCol at .7 (whole effect is then halved)
    float4 col = mix(float4(1), irisCol, smoothstep(.1, .7, d) * 0.5);

    // inner shadow next to the nose
    col.rgb *= 1. - smoothstep(.45, .5, d) * saturate(-st.y-st.x);

    col.rgb = mix(float3(0), col.rgb, smoothstep(0.3, 0.31, d));
    col.rgb = mix(irisCol.rgb, col.rgb, smoothstep(0.25, 0.3, d));
    col.rgb = mix(float3(0), col.rgb, smoothstep(0.189, 0.19, d));

    /// small circles
    // positioned at .1,.1
    float highlight = smoothstep(0.1, 0.09, length(st - float2(0.14,0.1)));
    col.rgb = mix(col.rgb, float3(1), highlight);
    // positioned at -.1,-.1. Smaller (0.04)
    highlight += smoothstep(0.04, 0.03, length(st - float2(-0.1,-0.1)));
    col.rgb = mix(col.rgb, float3(1), highlight);

    // only have it go till half the length
    col.a = smoothstep(0.5, 0.48, d);

    return col;
}

float4 Mouth(float2 st) {
    st -= .5;
    st.y *= 1.5;
    st.y -= 2 * st.x * st.x;
    float4 col = float4(0.5, 0.18, 0.05, 1.);
    float d = length(st);
    col.a = smoothstep(0.5, 0.49, d);


    // teeth
    float td = length(st - float2(0, .6));
    float3 toothCol = float3(1) * smoothstep(0.6, 0.35, d);
    col.rgb = mix(toothCol, col.rgb, smoothstep(0.49, 0.5, td));

    return col;
}

float4 Smiley(float2 st) {
    float4 col = float4(0);

    // Duplicate the right to the left as well:
    st.x = abs(st.x);

    // the alpha of Eye, Head, etc. will be 0 outside their drawing,
    // so that doing the mix with col using the `alpha` would only draw "within"

    float4 eye = Eye(within(st, float4(0.03, -0.1, 0.37, 0.25)));
    float4 head = Head(st);
    float4 mouth = Mouth(within(st, float4(-.3,-.4,.3,-.1)));

    col = mix(col, head, head.a);
    col = mix(col, eye, eye.a);
    col = mix(col, mouth, mouth.a);

    return col;
}

vertex VertexOut shaderToySmileyVertex(const device VertexIn *vertexArray [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexIn in = vertexArray[vid];
    VertexOut out;
    out.pos = float4(in.pos, 0, 1);
    return out;
}


fragment float4 shaderToySmiley(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
//    float t = uniforms.time;
    float2 st  = {interpolated.pos.x / uniforms.screen_width, interpolated.pos.y / uniforms.screen_height};
    st.y = 1. - st.y; // make it go from bottom to top
    st -= 0.5; // center

    float4 smiley = Smiley(st);
    return smiley;
}
