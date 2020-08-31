//
//  MetalByTutorials04.metal
//  MetalPlayground
//
//  Created by Raheel Ahmad on 8/8/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float4 position [[attribute(0)]];
};

struct VertexOut {
    float4 position [[position]];
    float point_size [[point_size]];
};

vertex VertexOut metalByTutorials04_vertex(constant float3 *vertices [[buffer(0)]], uint vid [[vertex_id]]) {
    VertexOut vertex_out {
        .position = float4(vertices[vid], 1),
        .point_size = 20.0
    };
    return vertex_out;
}

fragment float4 metalByTutorials04_fragment(constant float4 &color [[buffer(0)]]) {
    return color;
}
