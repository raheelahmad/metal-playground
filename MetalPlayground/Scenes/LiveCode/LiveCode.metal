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
};

typedef enum {
    StampKindFlower = 1,
} StampKind;


struct StampUniforms {
    float kind;
    float progress;
};

struct VertexOut {
    float4 pos [[position]];
    float4 color;
};

vertex VertexOut liveCodeVertexShader(const device VertexIn *vertices [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexOut in;
    in.pos = {vertices[vid].pos.x, vertices[vid].pos.y, 0, 1};
    return in;
}

// ----- NOISE experiments

float noiseMove(float2 uv, float time) {
    float x = time * 3;

    // -- multiples
    //    uv *= 20;
    //    uv = fract(uv);

    float i = floor(x);
    float f = fract(x);
    float t = mix(random(i), random(i+1), smoothstep(0., 1., f));


    //    uv.x -= t - 0.0;
    //    uv.y -= t - 0.0;

    uv -= 0.5;
    uv = rotate(t) * uv;

    float rs = .2;
    float c = rectangle(uv, {-rs,rs,rs,-rs});

    return c;
}

float noiseCreature(float2 uv, float time) {
    float2 uvN = uv * 10;
    float m = uvN.x;
    float f = fract(m+time/10);
    float i = floor(m);

    float t = mix(random(i), random(i+1), smoothstep(0., 1., f));
    uv.y -= t/10;
    float rec = rectangle(uv-0.5, {-.2,.2,.2,-.2});
    return rec;
}


float noiseSmoothToSharpAnimated(float2 uv, float time) {
    float x = uv.x * 10;
    float i = floor(x);
    float f = fract(x);
    float y = random(i);
    f += 1-fract(time/12);
    y = mix(random(i), random(i+1), f);
    y = mix(random(i), random(i+1), smoothstep(0., 1., f));

    // Draw
    float t = smoothstep(y, y-0.001, uv.y + 0.98);
    return t;
}

// -END- NOISE experiments


float sdArc( float2 p, float2 sca, float2 scb, float ra, float rb ) {
    p *= float2x2(sca.x,sca.y,-sca.y,sca.x);
    p.x = abs(p.x);
    float k = (scb.y*p.x>scb.x*p.y) ? dot(p.xy,scb) : length(p.xy);
    return sqrt( dot(p,p) + ra*ra - 2.0*ra*k ) - rb;
}

float stampSide(float2 uv, float yOverX) {
    // Also, only works with even width
    float coW = 0.20;
    float fullSide = 2.0;

    if (yOverX < 1.) {
        coW *= (yOverX/1.0);
    }

    int coCount = float((fullSide) / coW) + 2;
    float coInsetFr = 0.5;

    float coInset = coW * coInsetFr;
    float circleR = (coW - coInset)/2.;

    float t = 0;

    for(int i=0; i < coCount; i++) {
        float2 coUV = abs(uv);
        float2 offset = {
            -1.0 + coW * i + coW/2.0 - coW/2,
            1.0
        };
        coUV -= offset;
        coUV.y *= yOverX;
        float circ = circle(coUV, circleR);
        t += circ;
    }

    return t;
}

float4 stamp(float2 uv, float yOverX) {
    float4 insets = {-1,1,1.,-1};

    float t = rectangle(uv, insets);
    //    uv = scale(0.99) * uv;

    t -= stampSide(uv, yOverX);
    t -= stampSide(scale(1.0) * rotate(-M_PI_F/2.) * uv, 1/yOverX);

    float4 col = {0.2, 0.1, 0.25, t};

    return col;
}

float4 frame(float2 st) {
    float4 color = 0;

    float inset = 0.1;
    float insetLen = 1. - inset;
    float innerOutline = rectangle(st, {-1.,1.,1.,-1.}) - rectangle(st, {-insetLen,insetLen,insetLen,-insetLen});
    return mix(color, {0.89,0.8,0.84, innerOutline}, innerOutline);
}

float leafF(float2 uv, float R, float r, float progress) {
    float leafR = r;
//    uv = rotate(M_PI_F/8) * uv;
    float2 left = uv;
    left.x += leafR;
    float2 right = uv;
    right.x -= leafR;
    float t = circle(left, R) * circle(right, R);
//    t = circleOutline(left, R, 0.01) * circle(right, R) + circleOutline(right, R, 0.01) * circle(left, R);
    return t;
}

float4 leaves(float2 uv, float a2, float stemArcR, float stemTH, float progress) {
    // a2 → how far down (angle) the stem do we place the leaf
    /// leaves are intersection of two circles (radius `R`) that are moved left and right by `r`.
    float R = 0.11; // circles
    float r = 0.09 * 1./lerp(progress, 0, 1, 0.8, 1.);
    // height of the intersection
    float a = 2 * sqrt(R*R - r*r);
    stemArcR -= stemTH/2; // move to center of stem's thickness

    float4 col = 0;

    float4 leafColor = {0.3, 0.7, 0.2, 1.};

    typedef struct {
        float offset;
        float rotation;
    } LeafVals;

    const LeafVals vals[6] = {
        LeafVals{.offset = 0,.rotation = M_PI_F/2.0},
        LeafVals{.offset = 0.03,.rotation = 0.3},
        LeafVals{.offset = 0.06,.rotation = M_PI_F/2.0},
        LeafVals{.offset = 0.01,.rotation = 0.0},
        LeafVals{.offset = 0.08,.rotation = M_PI_F/1.7},
        LeafVals{.offset = 0.02,.rotation = 0.5},
    };

    for(int i=0; i<6; i++) {
        LeafVals val = vals[i];
        a2 -= val.offset;
        float2 leafUV = uv-float2(stemArcR*cos(a2), stemArcR*sin(a2));
        leafUV = rotate(val.rotation) * leafUV;
        leafUV.y -= a/2.;
        float leafT = leafF(leafUV, R, r, progress);
        col = mix(col, leafColor, leafT);
    }

    return col;
}

float4 budAndPetals(float2 uv, float a2, float stemArcR, float stemTH, float progress) {
    // TEST
//    progress = 1.0;

    float4 budCenterCol = float4(0.9, 0.4, 0.02, 1);
    float4 col = 0;
    float circleR = 0.16;
    float2 budCenterUV = uv;

    stemArcR -= stemTH/2;

    budCenterUV = budCenterUV-float2(stemArcR*cos(a2), stemArcR*sin(a2));
    budCenterUV = rotate(progress) * budCenterUV; // keep rotating the flower with progress

    float count = 20;
    float leafOffsetAngle = (M_PI_F*2)/count;

    float petalColorsCount = 2;
    float4 petalColors[2] = {
        {0.2,0.4, 0.3, 1.},
        {0.2,0.3, 0.2, 1.}
    };

    for(int petalIdx=0; petalIdx<petalColorsCount; petalIdx++) {
        for (float i=leafOffsetAngle*petalIdx; i <= M_PI_F*2.0; i+=leafOffsetAngle*petalColorsCount) {
            float a = circleR;
            float2 leaf1UV = rotate(M_PI_F* 0.36 + i) * (budCenterUV);
            leaf1UV.y += a*progress;
            float leaf1 = leafF(scale(progress) * leaf1UV, 0.27, 0.240, progress);
            col = mix(col, petalColors[petalIdx], smoothstep(0.0, 1.0, leaf1));
        }
    }

    float tBud = circle(budCenterUV, 0.05*progress);
    col = mix(col, budCenterCol, tBud);

    return col;
}

float4 stemF(float2 uv, float progress) {
    // TEST
    progress = 1.00;
    float budsAndPetalsProgress = lerp(progress, 0, 1, 0.4, 1.); // don't start from zero
//    budsAndPetalsProgress = 1.0;
    float stemProgress = lerp(progress, 0, 1, 0.6, 1.); // don't start from zero
//    stemProgress = 1;

    float4 col = 0;
    float4 stemCol = float4(0.18,0.3, 0.11, 1);

    // Stem and the whole flower, is laid out on a giant circle's arc
    float stemArcR = 2.4;
    // stem is currently full grown (stemProgress is 1.0)
    float a2Variant = lerp(stemProgress, 0, 1, 0.25, 0.8);
    // a1 and a2 are start/end of the arc
    float a1 = 0.0;
//    a2Variant = 0;
    float a2 = M_PI_F/2.01 * a2Variant;
    // The arc is offset way to the left of the screen
    float2 arcCenterOffset = {-2.35,-.3};

    uv -= arcCenterOffset;
    // arc is rotated down (a1 is always 0) so it shoots from the bottom of the screen
    uv = rotate(-M_PI_F/3.0) * uv;

    // stem
    float stemTH = 0.013*stemProgress;
    float tStem = arc(uv, stemArcR, a1, a2, stemTH);
    col = mix(col, stemCol, tStem);

    // bud
    float4 budCol = budAndPetals(uv, a2, stemArcR, stemTH, budsAndPetalsProgress);
    col = mix(col, budCol, budCol.a);

    // leaves
    a2 -= 0.2;
    float4 leafCol = leaves(uv, a2, stemArcR, stemTH, budsAndPetalsProgress);
    col = mix(col, leafCol, leafCol.a);

    return col;
}

float4 flower(float2 uv, float yOverX, float progress) {
    uv.x /= yOverX;
    float4 bg = {0.8, 0.4, 0.51, 1};

    float4 col = bg;
    float4 stem = stemF(uv, progress);
    col = mix(col, stem, stem.a);


    return col;
}

fragment float4 liveCodeFragmentShader(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]], constant StampUniforms &stampUniforms [[buffer(1)]]) {
    float2 uv = {interpolated.pos.x / uniforms.screen_width, 1 - interpolated.pos.y/uniforms.screen_height};
    float2 st = uv;
    st -= 0.5;
    st *= 2;

    float yOverX = uniforms.screen_height / uniforms.screen_width;

    float4 color = 0;

    // TODO: adding a smoothstep to circle() will give borders

    if (stampUniforms.kind == StampKindFlower) {
        float progress = stampUniforms.progress;

        float4 flowerCol = flower(st, yOverX, progress);
        color = mix(color, flowerCol, flowerCol.a);

        float4 frameCol = frame(st);
        color = mix(color, frameCol, frameCol.a);

        float4 stampCol = stamp(st, yOverX);
        color = mix(color, stampCol, 1. - stampCol.a);

    }

    return color;
}
