//
//  ShaderToyStarField.metal
//  MetalPlayground
//
//  Created by Raheel Ahmad on 7/16/20.
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

struct StarfieldUniforms {
    bool rotating;
    bool flying;
    float num_layers;
    float num_density;
};

#define S(a, b, t) smoothstep(a, b, t)

float map(float a, float b, float c, float d, float t) {
    float val = (t - a) / (b - a) * (d - c) + c;
    return clamp(val, 0.0, 1.0);
}

/// Normalize st within the box: if st.x == 0, it will be on left side; if st.y == 0, it will be on bottom side;
float2 withinRect(float2 st, float4 rect) {
    return (st - rect.xy) / (rect.zw - rect.xy);
}

float2x2 Rot(float a) {
    float s = sin(a), c = cos(a);
    return float2x2(c, -s, s, c);
}

float Star(float2 st, float flare) {
    float d = length(st);

    float m = 0;

    float star = .05/d;
    m += star;

    // 2 rays:
    //  1st
    float rays = max(0., 1. - abs(st.y * st.x * 1000));
    m += rays * flare;
    //  2nd rotated
    st *= Rot(3.1415/4);
    rays = max(0., 1. - abs(st.y * st.x * 1000));
    m += rays * .3 * flare;

    // don't project indefinitely outside the grid
    // (just in the next neighbor, but not the neighbor's neighbor)
    m *= smoothstep(0.9, .2, d);

    return m;
}

float Hash12(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float3 starField(float2 st) {
    float3 color = 0;
    float2 id = floor(st);
    float2 gv = fract(st)
    - 0.5 // move the coordinate-system so star is expected in the center
    ;

    for (int x=-1; x<=1; x++) {
        for (int y=-1; y<=1; y++) {
            float2 offset = float2(x, y);
            float contributingStarId = Hash12(id + offset);
            float2 gvPos = gv // place in the unit box for which we are asking for pixel value if star is centered in the grid
            - offset // consider the star to be in a different grid if we have an offset
            - (float2(
                      contributingStarId, // add a random offset for x inside the grid
                      fract(contributingStarId * 12) // same for y, but make it a different random
                      )
               - .5
               ) ;

            float size = fract(contributingStarId * 219.34);
            float flare = smoothstep(0.4, .8, size); // only for bigger stars
            float star = Star(gvPos, flare);
            float3 col = sin(float3(0.6, 0.4, 0.8) * fract(contributingStarId * 210) * 212.) * .5 + .5;
            color += star * size * col;
        }
    }
    return color;
}

fragment float4 shaderToyStarfield(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]],
                                   constant StarfieldUniforms &uniforms2 [[buffer(1)]]                                   ) {
    float t = uniforms.time * 0.1;
    if (!uniforms2.flying) {
        t = 0;
    }
    float2 st  = {interpolated.pos.x / uniforms.screen_width, 1 - interpolated.pos.y / uniforms.screen_height};
    st -= 0.5;

    if (uniforms2.rotating) {
        st *= Rot(t);
    }
    st *= uniforms2.num_density; // divides the screen in to a grid (rather, repeats the

    float numLayers = uniforms2.num_layers;

    float3 color = 0;
    for (float i = 0; i < 1; i+=1/numLayers) {
        float depth = fract(i + t); // increading depth, b/w 0 and 1
        float scale = mix(20, .5, depth); // smaller in the back
        float fade = depth; // don't count the color much if it's in the back (depth ~= 0)
        float layerOffset =  
        floor(i + t);
//        i * 453.2;
        color += starField(st * scale + layerOffset) * fade;
    }

//    if (abs(gv.x) > 0.49 || abs(gv.y) > 0.49) color.r = 1;

    return float4(color, 1);
}
