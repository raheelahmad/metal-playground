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

// is the point on the screen going to hit something in the scenery:
float map(float3 pos) {
    // sphere equation: distance from sampling point (pos) to
    // the center of the sphere, minus the radius. Distance of 0 == hit
    float radius = 0.25;
    float d = length(pos) - radius;
    return d;
}

float3 calcNormal(float3 pos) {
    // the orientation (ie. the normal in this case) is an orientation
    // which we can approximate via a derivative

    // evaluate the SDF at different points which will give us the orientation.
    // e.g. if on my right the distance is large vs. my left ⇒ object is to my left
    // ⇒ the object is facing me

    float2 e = float2(0.0001, 0.0);
    return normalize(float3(map(pos + e.xyy) - map(pos - e.xyy),
                           map(pos + e.yxy) - map(pos - e.yxy),
                           map(pos + e.yyx) - map(pos - e.yyx)
                           ));
}

fragment float4 truchetFragment(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
    // p is (0,0) in the middle of the screen
    float2 p = (2.0 * interpolated.pos.xy - float2(uniforms.screen_width, uniforms.screen_height))/uniforms.screen_height;
    p.y = -p.y;

    float3 col = 0;

    // +z is out of the screen
    
    // camera on z axis:
    float3 r0 = float3(0, 0, 1);
    // rd is the direction to the pixel
    // the z is the FoV of the camera lens
    float3 rd = normalize(float3(p, -1.5));

    // Ray marching algorithm
    float t = 0;
    for(int i = 0; i < 100; i++) {
        // position along the ray.
        float3 pos = r0 + t * rd;
        float h = map(pos);
        // we are inside the shape, don't go in.
        if (h < 0.001) break;
        t += h;
        // we are too far, break
        if (t > 20.0) break;
    }

    // we hit something:
    if (t < 20.0) {
        // position of hit:
        float3 pos = r0 + t * rd;
        float3 norm = calcNormal(pos);
        // to the sun:
        float3 sun_dir = normalize(float3(0.8, 0.4, 0.2));
        float diffusion = clamp(dot(norm, sun_dir), 0.0, 1.0);
        float3 diffColor = float3(1.0, 0.7, 0.5);
        col = diffusion * diffColor;
    }

//    col = step(0.5, p.y);


    return vector_float4(col, 1);
}

