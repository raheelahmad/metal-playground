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
    float2 mouse_pos;
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

float sdEllipsoid(float3 pos, float3 radius) {
    float k0 = length(pos / radius);
    float k1 = length(pos / radius / radius);
    return k0 * (k0 - 1.0) / k1;
}


float sdSphere(float3 pos, float radius) {

    float d = length(pos/radius) - 1.0;
    return d * radius;
}

float sdGuy(float3 pos, float time) {
    // sphere equation: distance from sampling point (pos) to
    // the center of the sphere, minus the radius. Distance of 0 == hit
    float radius = 0.25;

    float t = fract(time * 1);
    // the object moves up and down with a parabolic eqn:
    float y = 4.0 * t * (1.0 - t);
    // derivative of y-movement
    float dy = 2.0 * (1.0 - 2.0 * t);
    float3 center = float3(0, y, 0);

    float squashY = y * 0.5 + 0.5;
    float squashZ = 1 / squashY;
    return sdEllipsoid(pos - center, float3(radius, squashY * radius, squashZ * radius));
}

// is the point on the screen going to hit something in the scenery:
float map(float3 pos, float time) {
    float d1 = sdGuy(pos, time);

    float planeD = pos.y - (-0.25); // plane at -0.1

    float d = min(d1, planeD);

    return d;
}

float3 calcNormal(float3 pos, float time) {
    // the orientation (ie. the normal in this case) is an orientation
    // which we can approximate via a derivative

    // evaluate the SDF at different points which will give us the orientation.
    // e.g. if on my right the distance is large vs. my left ⇒ object is to my left
    // ⇒ the object is facing me

    float2 e = float2(0.0001, 0.0);
    return normalize(float3(map(pos + e.xyy, time) - map(pos - e.xyy, time),
                           map(pos + e.yxy, time) - map(pos - e.yxy, time),
                           map(pos + e.yyx, time) - map(pos - e.yyx, time)
                           ));
}

float castRay(float3 r0, float3 rd, float time) {
    float t = 0;
    for(int i = 0; i < 100; i++) {
        // position along the ray.
        float3 pos = r0 + t * rd;
        float h = map(pos, time);
        // we are inside the shape, don't go in.
        if (h < 0.001) break;
        t += h;
        // we are too far, break
        if (t > 20.0) break;
    }

    if (t > 20.0) return -1.0;
    return t;
}

fragment float4 truchetFragment(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
    // p is (0,0) in the middle of the screen
    float2 p = (2.0 * interpolated.pos.xy - float2(uniforms.screen_width, uniforms.screen_height))/uniforms.screen_height;
    p.y = -p.y;
    
    float time = uniforms.time/2;

    float3 col = 0;

    // +z is out of the screen
    
    float3 ta = float3(0, 0.5, 0); // target point camera is looking at

    float mousePosX = (uniforms.mouse_pos.x);
    float an = 4 * mousePosX;
    // camera on z axis:
    float3 r0 = ta + float3(1.5 * sin(an), 0, 2.5*cos(an));

    float3 ww = normalize(ta - r0); // z
    float3 uu = normalize(cross(ww, float3(0,1,0))); // right
    float3 vv = normalize(cross(uu, ww));

    // rd is the direction to the pixel
    float3 rd = normalize(p.x*uu + p.y*vv + 1.8*ww);

    // Ray marching algorithm
    float t = castRay(r0, rd, time);

    // we hit something:
    if (t > 0) {
        // position of hit:
        float3 pos = r0 + t * rd;
        float3 norm = calcNormal(pos, time);

        // general material color:
        float3 material = float3(0.18);

        // sun:
        float3 sun_dir = normalize(float3(0.8, 0.4, 0.2));
        float sun_diffusion = clamp(dot(norm, sun_dir), 0.0, 1.0);
        float sun_shadow = castRay(pos + norm * 0.001, sun_dir, time);
        // same as 1 - step(sun_shadow, 0). That is, if shadow is negative, then count as 1.
        // otherwise 0. So, for places where we do get a shadow above, sun's diffusion below will be 0.
        sun_shadow = step(sun_shadow, 0.0);

        float3 diffColor = float3(7.0, 4.5, 3.0);
        col = sun_diffusion * diffColor * sun_shadow * material;

        // sky:
        float3 sky_dir = normalize(float3(0, 1, 0));
        float sky_diffusion = clamp(0.5 + 0.5 * dot(norm, sky_dir), 0.0, 1.0);
        float3 skyColor = float3(0.5, 0.8, 0.9);
        col += sky_diffusion * skyColor * material;

        // bounce:
        float3 bounceColor = float3(0.7, 0.3, 0.2); // this is what the floor color is going to be
        // light that comes from below. so if the dot > 0 we are facing down and will get some floor color.
        float bounce_diffusion = clamp(0.5 + 0.5*dot(norm, float3(0, -1, 0)), 0.0, 1.0);
        col += material * bounce_diffusion * bounceColor;
    } else {
        col = float3(0.65, 0.75, 0.9) - 0.7 * rd.y; // bias the blue color with y, so it darknes on top
        col = mix(col, float3(0.7, 0.75, 0.8), exp(-10.0*rd.y));
    }

    // gamma correction
    col = pow(col, float3(0.4545));

//    col = step(0.4, mousePosX);


    return vector_float4(col, 1);
}

