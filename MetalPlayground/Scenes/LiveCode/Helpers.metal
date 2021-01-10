//
//  Helpers.metal
//  MetalPlayground
//
//  Created by Raheel Ahmad on 1/9/21.
//  Copyright © 2021 Raheel Ahmad. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#include "../ShaderHeaders.h"

float lerpS(float x, float m, float n, float a, float b) {
    return a + (x-m)/(n-m) * (b - a);
}
