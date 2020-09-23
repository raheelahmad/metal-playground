//
//  MetalByTutorials01.metal
//  MetalPlayground
//
//  Created by Raheel Ahmad on 8/5/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float4 position [[attribute(0)]];
};

vertex float4 models_vertex(const VertexIn vIn [[stage_in]]) {
    return vIn.position;
}

fragment float4 models_fragment() {
    return float4(1, 0,0,1);
}
