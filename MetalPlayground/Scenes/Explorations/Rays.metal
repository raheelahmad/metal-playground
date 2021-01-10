//
//  Rays.metal
//  MetalPlayground
//
//  Created by Raheel Ahmad on 9/2/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


#import <simd/simd.h>

typedef struct {
    matrix_float4x4 modelMatrix;
    matrix_float4x4 viewMatrix;
    matrix_float4x4 projectionMatrix;
} Uniforms;

struct VertexIn {
    float4 position [[attribute(0)]];
};

vertex float4 rays_vertex(
                                        const VertexIn vIn [[stage_in]],
                                        constant Uniforms &uniforms [[buffer(1)]]) {
    float4 pos = uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.modelMatrix * vIn.position;
    return pos;
}

fragment float4 rays_fragment() {
    return float4(1, 0,0,1);
}
