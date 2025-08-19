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

vertex VertexOut simon_noise_intro_vertex(const device VertexIn *vertexArray [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexIn in = vertexArray[vid];
    VertexOut out;
    out.pos = float4(in.pos, 0, 1);
    return out;
}

// -- Fragment

float3 hash( float3 p ) // replace this by something better
{
    p = float3( dot(p,float3(127.1,311.7, 74.7)),
             dot(p,float3(269.5,183.3,246.1)),
             dot(p,float3(113.5,271.9,124.6)));

    return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

float noise(float3 p )
{
    float3 i = floor( p );
    float3 f = fract( p );

    float3 u = f*f*(3.0-2.0*f);

    return mix( mix( mix( dot( hash( i + float3(0.0,0.0,0.0) ), f - float3(0.0,0.0,0.0) ),
                         dot( hash( i + float3(1.0,0.0,0.0) ), f - float3(1.0,0.0,0.0) ), u.x),
                    mix( dot( hash( i + float3(0.0,1.0,0.0) ), f - float3(0.0,1.0,0.0) ),
                        dot( hash( i + float3(1.0,1.0,0.0) ), f - float3(1.0,1.0,0.0) ), u.x), u.y),
               mix( mix( dot( hash( i + float3(0.0,0.0,1.0) ), f - float3(0.0,0.0,1.0) ),
                        dot( hash( i + float3(1.0,0.0,1.0) ), f - float3(1.0,0.0,1.0) ), u.x),
                   mix( dot( hash( i + float3(0.0,1.0,1.0) ), f - float3(0.0,1.0,1.0) ),
                       dot( hash( i + float3(1.0,1.0,1.0) ), f - float3(1.0,1.0,1.0) ), u.x), u.y), u.z );
}

float fbm(float3 st, int octaves, float persistence, float lacunarity) {
    float amplitude = 0.5;
    float frequency = 1.0;
    float total = 0.0;
    float normalization = 0.0;

    for(int i = 0; i < octaves; i++) {
        float noiseValue = noise(st * frequency);
        total += noiseValue * amplitude;
        normalization += amplitude;
        amplitude *= persistence;
        frequency *= lacunarity;
    }

    total /= normalization;
    return total;
}

float ridgedFbm(float3 st, int octaves, float persistence, float lacunarity) {
    float amplitude = 0.5;
    float frequency = 1.0;
    float total = 0.0;
    float normalization = 0.0;

    for(int i = 0; i < octaves; i++) {
        float noiseValue = noise(st * frequency);
        noiseValue = 1.0 - abs(noiseValue);

        total += noiseValue * amplitude;
        normalization += amplitude;
        amplitude *= persistence;
        frequency *= lacunarity;
    }

    total /= normalization;
    total *= total;
    return total;
}

float turbulenceFbm(float3 st, int octaves, float persistence, float lacunarity) {
    float amplitude = 0.5;
    float frequency = 1.0;
    float total = 0.0;
    float normalization = 0.0;

    for(int i = 0; i < octaves; i++) {
        float noiseValue = noise(st * frequency);
        noiseValue = abs(noiseValue);

        total += noiseValue * amplitude;
        normalization += amplitude;
        amplitude *= persistence;
        frequency *= lacunarity;
    }

    total /= normalization;
    total *= total;
    return total;
}

float cellularNoise(float3 coords) {
    float2 gridBasePos = floor(coords.xy);
    float2 gridCoordOffset = fract(coords.xy);
    float closest = 1.0;
    for(float y = -2.0; y <= 2.0; y += 1) {
        for(float x = -2.0; x <= 2.0; x += 1) {
            float2 neighboringCellPos = float2(x,y);
            float2 cellWorldPos = gridBasePos + neighboringCellPos;
            float2 cellOffset = float2(
                                       noise(float3(cellWorldPos, coords.z) + float3(243.432, 324.235, 0.0)),
                                             noise(float3(cellWorldPos, coords.z))
                                       );
            float distanceToNeighbor = length(neighboringCellPos + cellOffset - gridCoordOffset);
            closest = min(closest, distanceToNeighbor);
        }
    }
    return  closest;
}


/// Useful for creating wood or marble
float stepped(float noiseSample) {
    float steppedSample = floor(noiseSample * 10.0) / 10.0;
    float remainder = fract(noiseSample * 10);
    // darken darks, lighten lights; creates a halo like effect
    steppedSample = (steppedSample - remainder);
    return steppedSample;
}

float domainWarping(float3 coords) {
    // Use the first sample to get the next

    float3 slightOffset = float3(43.21, 32.122, 0.0);
    float3 offset = float3(
                           fbm(coords, 4, 0.5, 2.0),
                           fbm(coords + slightOffset, 4, 0.5, 2),
                           0.0
                           );
    // Do we need this?
    float noiseSample = fbm(coords + offset, 1, 0.5, 2);

    // second offset includes the 1st offset
    float3 slightOffset2 = float3(23.21, 12.122, 0.0);
    float3 offset2 = float3(
                            fbm(coords + offset * slightOffset2, 4, 0.5, 2.0),
                            fbm(coords + offset + slightOffset*1.1, 4, 0.5, 2),
                           0.0
                           );
    noiseSample = fbm(coords + 4.0 * offset2, 1, 0.5, 2);

    return noiseSample;

}

fragment float4 simon_noise_intro_fragment(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
    float2 st  = {interpolated.pos.x / uniforms.screen_width, 1 - interpolated.pos.y / uniforms.screen_height};

    float3 noiseCoords = float3(st * 2, uniforms.time * 0.1);

    float noiseSample = 0.0;

//    noiseSample = lerp(noise(noiseCoords), -1, 1, 0, 1);
//    noiseSample = lerp(ridgedFbm(noiseCoords, 10, 0.5, 2.0), -1, 1, 0, 1);
//    noiseSample = lerp(turbulenceFbm(noiseCoords, 10, 0.5, 2.0), -3.0, 0, 0, 1);
//    noiseSample = cellularNoise(noiseCoords);

    noiseSample = lerp(domainWarping(noiseCoords), -1,1, 0,1);

    // can reuse with above:
    noiseSample = stepped(noiseSample);


    float3 color = float3(noiseSample);


    return vector_float4(color, 1.0);
}


