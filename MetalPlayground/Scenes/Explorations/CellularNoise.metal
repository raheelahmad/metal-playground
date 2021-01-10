//
//  CellularNoise.metal
//  MetalPlayground
//
//  Created by Raheel Ahmad on 5/16/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

//float randomized(float x) {
//    return fract(sin(x) * 10.0);
//}
//

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

vertex VertexOut cellularVertexShader(const device VertexIn *vertexArray [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexIn in = vertexArray[vid];
    VertexOut out;
    out.pos = float4(in.pos, 0, 1);
    return out;
}


vector_float2 random2(vector_float2 p ) {
    return fract(sin(vector_float2(dot(p,vector_float2(127.1,311.7)),dot(p,vector_float2(269.5,183.3))))*43758.5453);
}

fragment float4 tileFragmentShader(VertexOut pixel [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
    float2 st = {pixel.pos.x / uniforms.screen_width, 1 - pixel.pos.y / uniforms.screen_height};
    st *= 5;
    float2 ist = floor(st);
    float2 fst = fract(st);

    float min_dist = 1;

    for(int i=-1; i<=1; i++) {
        for(int j=-1; j<=1; j++) {
            float2 neighbor_origin = {float(i), float(j)};
            float2 neighbor_point = random2(ist + neighbor_origin);
            neighbor_point = 0.5 + 0.5*sin(uniforms.time + 6.2831*neighbor_point);
            float neighbor_point_distance = length(neighbor_origin + neighbor_point - fst);
            min_dist = min(min_dist, neighbor_point_distance * min_dist);
        }
    }

    float3 color = float3(0) + step(0.06, min_dist);
    if (length(color) != 0) {
        color = float3(0.8, 0.7, 0.68);
    }
//    color[1] = min_dist;

    return float4(color, 1);
}

fragment float4 tileFragmentShader2(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
    float x = interpolated.pos.x / uniforms.screen_width;
    float y = 1 - interpolated.pos.y / uniforms.screen_height;
    float2 st = {x,y};
    float scale = 3;
    st *= scale;

    float2 ist = floor(st);
    float2 fst = fract(st);

    float min_dist = 100;

    for (int y= -1; y <= 1; y++) {
        for (int x= -1; x <= 1; x++) {
            // Neighbor place in the grid
            vector_float2 neighborOffset = vector_float2(float(x),float(y));

            // Random position from current + neighbor place in the grid
            vector_float2 pointInNeighbor = random2(ist + neighborOffset);

            // Animate the point
            pointInNeighbor = 0.5 + 0.5*sin(uniforms.time + 6.2831*pointInNeighbor);

            // Vector between the pixel and the point
            vector_float2 diff = neighborOffset + pointInNeighbor - fst;

            // Distance to the point
            float dist = length(diff);

            // Keep the closer distance
            min_dist = min(min_dist, dist);
        }
    }

    vector_float3 color = 0;
    // Draw the min distance (distance field)
    color += min_dist;

    // Draw cell center
    color += 1.-step(.02, min_dist);

    // Draw grid
    color.r += step(.98, fst.x) + step(.98, fst.y);

    return float4(float3(min_dist), 1);
}

fragment float4 cellularFragmentShader(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
    unsigned int pointsCounts = int(uniforms.time) % 5 + 1;
    float x = interpolated.pos.x / uniforms.screen_width;
    float y = 1 - interpolated.pos.y / uniforms.screen_height;
    float2 st = { x, y };

    float2 points[6];
    points[0] = {
        0.1,
        0.4
    };
    points[1] = {
        0.3,
        0.8
    };
    points[2] = {
        0.7,
        0.5
    };
    points[3] = {
        0.9,
        0.32
    };
    points[4] = {
        0.81,
        0.72
    };
    points[5] = {
        0.51,
        0.1
    };

    float min_dist = 100;
    float variation_max = 0.1;
    for (unsigned int i = 0; i < pointsCounts; i++) {
        float2 center = points[i];
        float variation = (0 + sin(uniforms.time)) * variation_max;
        if (i % 2 == 0) {
            center[0] += variation;
        } else {
            center[1] += variation;
        }

        float dist = distance(st, center);
        if (dist < 0.005) {
            return float4(0.3, 0.4, 0.6, 1);
        }
        min_dist = min(dist, min_dist);
    }

    if (pointsCounts > 3) {
        min_dist -= step(.7,abs(sin(50.0*min_dist)))*.3;
    }

    return float4(float3(min_dist), 1);
}
