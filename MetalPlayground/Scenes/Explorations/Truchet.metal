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
};

struct VertexOut {
    float4 pos [[position]];
    float4 color;
};

float Hash21(float2 p) {
    p = fract(p * float2(131.21, 389.34));
    p += dot(p, p + 24.23);
    return fract(p.x * p.y);
}

vertex VertexOut truchetVertex(const device VertexIn *vertexArray [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexIn in = vertexArray[vid];
    VertexOut out;
    out.pos = float4(in.pos, 0, 1);
    return out;
}

fragment float4 truchetFragment(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
    float2 st = (interpolated.pos.xy - 0.5 * float2(uniforms.screen_width, uniforms.screen_height)) / uniforms.screen_height;
    vector_float3 col = float3(0);

//    st += (cos(uniforms.time) + sin(uniforms.time))/12.0;

    st *= 8.0;
    float2 gv = fract(st) - 0.5;
    float2 id = floor(st);

    float n = Hash21(id); // random between 0 and 1.
    gv.x *= mix(-1, 1, step(0.5, n));

//    col = (step(0.48, gv.x) + step(0.48, gv.y))  * float3(1,0,0);
    float d = abs(gv.x) - gv.y;
    col += 1 - step(0.082, abs(d) - 0.25);

//    col.rg += n;

    return vector_float4(col, 1);
}

