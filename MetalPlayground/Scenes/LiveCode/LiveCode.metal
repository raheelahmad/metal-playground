#include <metal_stdlib>
using namespace metal;
#include "../ShaderHeaders.h"

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

vertex VertexOut liveCodeVertexShader(const device VertexIn *vertices [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexOut in;
    in.pos = {vertices[vid].pos.x, vertices[vid].pos.y, 0, 1};
    return in;
}

float3 stamp(float2 uv) {
    float stampInset = 0.02;
    float4 insets = {-1+stampInset,1-stampInset,1.-stampInset,-1+stampInset};

    // TODO: replace with SDFs
    float t = rectangle(uv, insets);

    float stampTH = 0.14;
    t -= rectangle(scale(1.-stampTH) * uv, insets);

    {
        float cutoutR = 0.06;
        float cutouts = 11;
        float cutoutWidth = 2.0/cutouts;

        for (int i=0;i<cutouts;i++) {
            float2 offset = {
                -1 + (cutoutWidth)*1.25*float(i),
                1-stampInset
            };
            float xcut = arc(abs(uv) - offset, cutoutR, M_PI_F, 2*M_PI_F-0, cutoutR+0.01); // TODO: shouldn't have to manipulate the TH with 0.01 here
            float2 yUV = rotate(-M_PI_F/2.) * (abs(uv) - offset.yx);
            float ycut = arc(yUV, cutoutR, M_PI_F, 2*M_PI_F-0, cutoutR+0.01); // TODO: shouldn't have to manipulate the TH with 0.01 here
            t -= xcut;
            t -= ycut;
        }
    }

    t += circle(uv, 0.01);

    return t * float3(0.1,0.5, 0.9);
}

fragment float4 liveCodeFragmentShader(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
    float2 uv = {interpolated.pos.x / uniforms.screen_width, 1 - interpolated.pos.y/uniforms.screen_height};
    uv -= 0.5;
    uv *= 2;

    float3 color = stamp(uv);

    return float4(color, 1);
}
