//
//  SimonCloudyDay.metal
//  MetalPlayground
//
//  Created by Raheel Ahmad on 12/16/24.
//  Copyright © 2024 Raheel Ahmad. All rights reserved.
//

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
    float2 mousePos;
};

struct VertexOut {
    float4 pos [[position]];
    float4 color;
};

vertex VertexOut simon_cloudy_day_vertex(const device VertexIn *vertexArray [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexIn in = vertexArray[vid];
    VertexOut out;
    out.pos = float4(in.pos, 0, 1);
    return out;
}

float hash(float2 v) {
    return sin(dot(v, float2(3)));
}

// -- Fragment

float dayLength() {
    return 20;
}

float dayTime(float time) {
    return fmod(time, dayLength());
}

float3 backgroundColor(float2 st, float time) {
    float3 morning = mix(
                         float3(0.44, 0.65, 0.81),
                         float3(0.36, 0.53, 0.91),
                         smoothstep(0, 1, pow(st.x * st.y, 0.7))
                         );

    float3 midday = mix(
                         float3(0.71, 0.75, 0.81),
                         float3(0.56, 0.53, 0.81),
                         smoothstep(0, 1, pow(st.x * st.y, 0.7))
                         );
    float3 evening = mix(
                         float3(0.61, 0.55, 0.25),
                         float3(0.66, 0.33, 0.31),
                         smoothstep(0, 1, pow(st.x * st.y, 0.7))
                         );
    float3 night = mix(
                         float3(0.11, 0.35, 0.41),
                         float3(0.05, 0.04, 0.07),
                         smoothstep(0, 1, pow(st.x * st.y, 0.7))
                         );
    float3 color;
    float dt = dayTime(time);
    float dl = dayLength();
    if (dt < dl * 0.25) {
        color = mix(morning, midday, smoothstep(0, dl * 0.25, dt));
    } else if (dt < dl * 0.5) {
        color = mix(midday, evening, smoothstep(dl * 0.25, dl * 0.50, dt));
    } else if (dt < dl * 0.75) {
        color = mix(evening, night, smoothstep(dl * 0.5, dl * 0.75, dt));
    } else {
        color = mix(night, morning, smoothstep(dl * 0.75, dl, dt));
    }

    return color;
}

float sdfCloud(float2 st) {
    float puff = sdfCircle(st, 0.1);
    float puffLeft = sdfCircle(st - float2(-0.1, 0), 0.07);
    float puffRight = sdfCircle(st + float2(-0.1, 0), 0.07);
    return unionSDFs(puff, unionSDFs(puffLeft, puffRight));
}

fragment float4 simon_cloudy_day_fragment(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
    float2 st  = {interpolated.pos.x / uniforms.screen_width, 1 - interpolated.pos.y / uniforms.screen_height};
    st = st - 0.5;

    // Background
    float3 color = backgroundColor(st, uniforms.time);

    // Sun
    float _dayTime = dayTime(uniforms.time);
    float timePassed;
    if (_dayTime > 0.75 * dayLength()) {
        timePassed = lerp(_dayTime, 0, dayLength() * 0.4, 0.0, 0.99);
    } else {
        timePassed = lerp(_dayTime, dayLength() * 0.2, dayLength() * 0.4, 0.9, 0.0);
    }
    float2 sunPos = st - float2(-0.3, 0.3 * timePassed);
    float sun = sdfCircle(sunPos, 0.1);
    color = mix(yellow() * 0.92, color, smoothstep(0.0, 0.001, sun));

    // additive blending:
    float s = max(0.01, sun);
    float p = saturate(exp(-200.0 * s * s));
    color += 0.45 * mix(float(0.0),float3(0.8, 0.85, 0.37), p);

    float numClouds = 6;
    for(float i = numClouds; i >= 0; i--) {
//        float size = (i + 4.4)/4;
        float size = mix(2, 1, (i/numClouds) + 0.1 * hash(float2(i)));
        float2 stCloud = st * float(size) + float2(i * 0.4 + uniforms.time/12, 0);
        stCloud.x = fract(stCloud.x + 1) - 0.5;
        stCloud.y -= -0.1 + hash(float2(i) * 0.08);
        // cloud shadow
        float cloudOffset = 0.04;
        float cloudShadow = sdfCloud(stCloud * float2(2.2) - float2(-cloudOffset, -cloudOffset/2));
        // cloud
        float cloud = sdfCloud(stCloud);

        color = mix(float3(0.3), color, smoothstep(0, 0.22, cloudShadow));
        color = mix(float3(1), color, smoothstep(0, 0.001, cloud));
    }


    return vector_float4(color, 1.0);
}


