//
//  06Colors.metal
//  MetalPlayground
//
//  Created by Raheel Ahmad on 7/9/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

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


typedef enum {
    RandomSquares = 0,
    Maze = 1,
    RowVariants = 2,
} SketchKind;

struct RandomUniforms {
    float kind;
};



vertex VertexOut bos_random_vertex(const device VertexIn *vertexArray [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexIn in = vertexArray[vid];
    VertexOut out;
    out.pos = float4(in.pos, 0, 1);
    return out;
}

float rand_bos(float2 st) {
    return fract(sin(dot(st.xy,
                         float2(12.9898,78.233)))*
                 43758.5453123);
}

float3 random_squares(float2 st, float time) {
    st = float2(0.5) - st;

    float minSquares = 10;
    float maxSquares = 20;
    float speed = 0.6;

    st *= mix(minSquares, maxSquares, (1 + sin(time * speed))/4);

    st = floor(st);

    float3 col = float3(0.2, 0.7, 0.8) * rand_bos(st);
    return col;
}

float3 maze(float2 st, float time) {
    float3 color = float3(0.3, 0.5, 0.7);
    float thickness = 0.1;

    // subtract it first so we always zoom in/out from center.
    // this makes it so that the one big pixel (before scaling it below) is centered (0,0) in middle
    // of the screen.
    st -= 0.5;

    // zoom in/out
    st *= mix(10, 20, (1 + sin(time / 3)));

    // work in the pixel
    // t is the 0 -> 1 space in the pixel
    float2 t = fract(st);
    // st represents each box. So when we take its rand, we are deciding to diverge for what
    // happens in the box.
    st = floor(st);
    float determinant = rand_bos(st) > 0.5;
    float c = 0;
    if (determinant) {
        c = smoothstep(thickness - 0.01, thickness, abs(t.x - t.y));
    } else {
        c = smoothstep(thickness - 0.01, thickness, abs(1 - (t.y + t.x)));
    }
    return (1 - c) * color;
}

float3 rowVariants(float2 st, float time) {
    // Base color that all pixels will be tinted by
    float3 color = float3(0.7, 0.5, 0.85);
    
    // -----------------------
    // Grid setup
    // -----------------------
    
    // Number of horizontal strips (rows) on screen
    float numRows = 100.0;
    
    // Base number of columns each row can be divided into
    float baseColumnWidth = 10.0;
    
    // Scale the y coordinate into "row space"
    // st.y in [0,1] → [0,numRows] so we can assign each pixel to a row
    st.y *= numRows;
    
    // For each row, compute how many columns to split into.
    // The base width is varied by a random value per row
    float numColumnsForRow = baseColumnWidth 
    + baseColumnWidth * rand_bos(floor(st.y));
    
    // Scale x coordinate into "column space" for this row
    st.x *= numColumnsForRow;

    // -----------------------
    // Row-based variation
    // -----------------------

    // Stable random value for the current row (same across the row)
    float rowVariant = rand_bos(floor(st.y));

    // Horizontal movement speed: varies per row
    // Rows with larger rowVariant move slower
    float speedVariant = 0.3 / (0.08 + rowVariant);

    // Add horizontal offset over time
    // → makes the columns "scroll" horizontally at row-specific speeds
    st.x += time * speedVariant;

    // -----------------------
    // Pixel variation
    // -----------------------

    // Add random variation per pixel-cell
    // This breaks up the uniformity so bars don’t look solid
    float pixelVariant = 0.4 * rand_bos(floor(st));

    // fract() keeps only the fractional part of st
    // → confines us to [0,1] within each grid cell
    st = fract(st);

    // Smoothly fade pixels based on pixelVariant
    // → determines how strongly each pixel contributes to the bar
    float t = smoothstep(0.0, 0.2, pixelVariant);

    // Multiply base color by this fade
    color *= t;
    color = mix(color, float3(0.2, 0.9, 0.7), rowVariant);

    // -----------------------
    // Return final pixel color
    // -----------------------
    return color;
}


fragment float4 bos_random_fragment(
                                    VertexOut interpolated [[stage_in]],
                                    constant FragmentUniforms &uniforms [[buffer(0)]],
                                    constant RandomUniforms &kindUniforms [[buffer(1)]]
                                    ) {
    float2 st  = {interpolated.pos.x / uniforms.screen_width, 1 - interpolated.pos.y / uniforms.screen_height};
    float time = uniforms.time;

    float kind = kindUniforms.kind;
    float3 col = 0;
    if (kind == RandomSquares) {
        col = random_squares(st, time);
    } else if (kind == Maze) {
        col = maze(st, time);
    } else if (kind == RowVariants) {
        col = rowVariants(st, time);
    }

    float4 color = float4(col, 1);
    return color;
}
