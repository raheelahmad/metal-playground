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

struct StampUniforms {
    float kind;
    float hourOfDay;
    float fullDurationMinutes;
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

typedef struct {
    float3 bgCols[2];
    float3 petalCols[2];
    float petalR;
    int petalCount;
} Palette;

constant int palettesCount = 10;
constant Palette palettes[palettesCount] = {
    Palette {
        .bgCols = {float3(0.7,0.7,0.8), float3(0.7,0.8,0.5)},
        .petalCols = {float3(0.92,90./255., 60/255), float3(67./255.,100./255., 131./255.)},
        .petalR = 0.3,
    },
    Palette {
        .bgCols = {float3(0.72,0.10,0.34), float3(0.12,0.5,0.34)},
        .petalCols = {float3(0.62,0.5,0.34), float3(0.43,0.5,0.34)},
        .petalR = 0.3,
    },
    Palette {
        .bgCols = {float3(0.42,0.24,0.14), float3(0.32,0.5,0.34)},
        .petalCols = {float3(0.42,0.5,0.34), float3(0.83,0.5,0.34)},
        .petalR = 0.3,
    },
    Palette {
        .bgCols = {float3(0.42,0.31,0.24), float3(0.32,0.5,0.34)},
        .petalCols = {float3(0.92,0.5,0.34), float3(0.83,0.5,0.54)},
        .petalR = 0.3,
    },
    Palette {
        .bgCols = {float3(0.42,0.29,0.24), float3(0.32,0.5,0.34)},
        .petalCols = {float3(0.32,0.5,0.34), float3(0.012,0.5,0.34)},
        .petalR = 0.3,
    },
    Palette {
        .bgCols = {float3(0.42,0.91,0.24), float3(0.32,0.5,0.34)},
        .petalCols = {float3(0.32,0.5,0.34), float3(0.41,0.5,0.34)},
        .petalR = 0.3,
    },
    Palette {
        .bgCols = {float3(0.42,0.84,0.24), float3(0.32,0.5,0.34)},
        .petalCols = {float3(0.32,0.5,0.34), float3(0.82,0.31,0.34)},
        .petalR = 0.3,
    },
    Palette {
        .bgCols = {float3(0.42,0.84,0.24), float3(0.32,0.5,0.34)},
        .petalCols = {float3(0.32,0.5,0.34), float3(0.62,0.51,0.34)},
        .petalR = 0.3,
    },
    Palette {
        .bgCols = {float3(0.42,0.54,0.24), float3(0.32,0.5,0.34)},
        .petalCols = {float3(0.32,0.5,0.34), float3(0.92,0.5,0.34)},
        .petalR = 0.3,
    },
    Palette {
        .bgCols = {float3(0.42,0.29,0.24), float3(0.12,0.5,0.34)},
        .petalCols = {float3(0.32,0.5,0.34), float3(0.22,0.5,0.34)},
        .petalR = 0.3,
    },
};

// --

Palette palette_for_stamp_uniform(StampUniforms uniforms) {
    float randIndexBase = random(uniforms.hourOfDay * uniforms.fullDurationMinutes)  * 10;
    int idx = floor(randIndexBase);

    Palette palette = palettes[idx];

    float randBase = random(uniforms.hourOfDay + uniforms.fullDurationMinutes);
    palette.petalCount = ceil(randBase * 8)+1;
    randBase = lerp(randBase, 0, 1, 0.5, 1.0);
    palette.petalR *= randBase*1.5;

    return palette;
}

// ---

float petal(float2 st, float r1, float r2) {
    float t = sdVesica(st, r1, r2);
    t = 0. - sign(t);
    return t;
}

float halfPetal(float2 st, float r1, float r2) {
    float t = sdVesica(st, r1, r2) * step(0, st.x);
    t = 0. - sign(t);
    return t;
}

float progressDF(float2 p, float progress) {
    float2 st = p * (100 + noise(progress)*1000);
    st = rotate(progress*2) * st;
    float df = noise(st) * (1.-progress);
    return df;
}

float tulipPetal(float2 p, float r, int flipped, float progress) {
    float t = 0;

    r += progressDF(p, progress)*2.5;

    float2 semi1P = p;
    float semi1Angle1 = flipped ? M_PI_F/2 : 0;
    float semi1Angle2 = flipped ? M_PI_F : M_PI_F/2;
    float semi1 = filledArc(semi1P, r, semi1Angle1, semi1Angle2);
    float semi2Angle1 = flipped ? 3*M_PI_F/2 : 0;
    float semi2Angle2 = flipped ? 2*M_PI_F : M_PI_F/2;
    float rotateAngle = flipped ? 0 : M_PI_F;
    float2 semi2P = flipped ? p + float2(r, 0) : p - float2(r, 0);
    semi2P = rotate(rotateAngle)*semi2P;

    float semi2 = filledArc(semi2P, r, semi2Angle1, semi2Angle2);
    t = semi1 + semi2;



    // Shimmer effect
    //    float nf = noise(p * 1000);
//    t *= nf;

    return t;
}

float4 leaf(float2 leafSt, float r1, float r2, float3 topCol, float3 bottomCol, int useBottom, float progress)  {
    r1 += progressDF(leafSt, progress)/4;
    leafSt -= float2(0.,sqrt(r1*r1 - r2*r2)); // position in the center-x of stem
    float t = petal(leafSt, r1, r2);
    float4 color = 0;
    color = mix(color, float4(topCol, 1), step(1., t));
    if (useBottom) {
        color = mix(color, float4(bottomCol, 1), step(1., halfPetal(leafSt, r1, r2)));
    }
    return color;
}

float4 hemiSpheresFlower(float2 st, float progress, StampUniforms stampUniforms) {
    Palette palette = palette_for_stamp_uniform(stampUniforms);
    float t = 0;

    float4 color = 0;

    float petalR = palette.petalR;

    // TEST circle
    color = mix(color, float4(0.7,0.9,0.8,1), 1.-step(0.015, length(st)));

    // move up
    float2 petalSt = st;
    petalSt.y -= petalR;


    // triangle above petals
    t = sdTriangleIsosceles(petalSt-float2(0,0.3), {0.22,-0.3});
    t = 1.-smoothstep(0., 0.001, t+progressDF(petalSt, progress));
    color = mix(color, float4(float3(0.1), 1.), t);


    // TEST:
//    palette.petalCount = 2;
    float petalCount = palette.petalCount;

    // petals
    float maxRotation = palette.petalCount * M_PI_F/16;
    for (int petalIdx=0; petalIdx < petalCount; petalIdx++) {
        float rotation = petalCount > 1 ? 1.0 - float(petalIdx) / (petalCount - 1) : 0;
        rotation *= maxRotation * progress;
        float colVar = float(petalIdx+0.1)/float(palette.petalCount);
        colVar = lerp(colVar, 0, 1, 0.6, 0.8);

        t = tulipPetal(rotate(rotation) * petalSt + float2(petalR,-0.0), petalR, 0, progress);
        color = mix(color, float4(palette.petalCols[0]/colVar, 1), t);

        t = tulipPetal(rotate(-rotation) * petalSt - float2(petalR,-0.0), petalR, 1, progress);
        color = mix(color, float4(palette.petalCols[1]/colVar, 1), t);
    }

    float3 green = {0.23, 0.39, 0.11};
    float3 black = {0.02, 0.09, 0.00};

    float stalkTH = 0.02;
    float2 stalkSt = petalSt-float2(0,-petalR);

    // thorns
    int thornsCount = 12*progress;
    float thornsSeparation = 0.08;
    for(int i=0; i<thornsCount; i++) {
        float thornY = thornsSeparation + thornsSeparation*i;
        float mod = 1. - fmod(float(i), 2);
        float rotation =  M_PI_F*2.5-mod;
        float thornX = mod == 0 ? stalkTH : -stalkTH;
        float2 thornSt = rotate(rotation) * scale(0.014)*(stalkSt + float2(thornX, thornY));
        color = mix(color, float4(green, 1), 1. - step(0.2, sdEquilateralTriangle(thornSt)));
    }

    float r1 = 0.11;
    float r2 = 0.07;
    float rotateSmallLeaf = 1.5 * M_PI_F/2;

    // --- Small leaves on top
    float2 smallLeafSt = stalkSt;
    // leaf 1
    float2 leafSt = rotate(rotateSmallLeaf) * smallLeafSt; // position it down and rotate
    float4 leftSmallLeafCol = leaf(leafSt, r1, r2, green, black, 1, progress);
    color = mix(color, leftSmallLeafCol, leftSmallLeafCol.a);
    // leaf 2
    float4 rightSmallLeafCol = leaf(rotate(-rotateSmallLeaf) * smallLeafSt, r1, r2, green, black, 1, progress);
    color = mix(color, rightSmallLeafCol, rightSmallLeafCol.a);

    float bigR1 = r1 * 2.1;
    float bigR2 =  0.16;
    float rotateBigLeaf = M_PI_F/4;
    float2 bigLeafSt = stalkSt + float2(0, 0.6);
    // leaf 1
    float4 leftBigLeafCol = leaf(rotate(rotateBigLeaf) * bigLeafSt, bigR1, bigR2, green, 0, 0, progress);
    color = mix(color, leftBigLeafCol, leftBigLeafCol.a);
    // leaf 2
    float4 rightBigLeafCol = leaf(rotate(-rotateBigLeaf) * bigLeafSt, bigR1, bigR2, black, 0, 0, progress);
    color = mix(color, rightBigLeafCol, rightBigLeafCol.a);

    // stalk
    t = rectangle(stalkSt, {-stalkTH/2+progressDF(stalkSt, progress)/4,0,stalkTH/2+progressDF(stalkSt, progress)/4,-1.});
    color = mix(color, float4(0.12,0.24,0.1,1), step(1., t));


    // vein lines
    float veinTH = 0.002;
    float4 lineBox = {-veinTH,0.,veinTH,-0.33*progress};
    float2 veinSt = rotate(-rotateBigLeaf+M_PI_F*1.5) * bigLeafSt;
    //    veinSt.x += sin(veinSt.y*310)/330;
    color = mix(color, float4(black, 1), rectangle(veinSt, lineBox));

    veinSt = rotate(rotateBigLeaf-M_PI_F*1.5) * bigLeafSt;
    color = mix(color, float4(green, 1), rectangle(veinSt, lineBox));
    return color;
}

// ---

float noiseF(float2 st) {
    return noise(st);
}

fragment float4 liveCodeFragmentShader(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]], constant StampUniforms &stampUniforms [[buffer(1)]]) {
    float yOverX = uniforms.screen_height / uniforms.screen_width;
    float2 uv = {interpolated.pos.x / uniforms.screen_width, 1 - interpolated.pos.y/uniforms.screen_height};
    float2 st = uv;

    Palette palette = palette_for_stamp_uniform(stampUniforms);

    float progress = fract(uniforms.time/10);
    progress = clamp(lerp(progress, 0, 1, 0, 1.2), 0., 1.);
    // TEST
//    progress = clamp(lerp(progress, 0, 1, 0, 1.9), 0., 1.);

    float4 color = mix(float4(palette.bgCols[0], 1), float4(palette.bgCols[1], 1), pow(st.y, .5));

//    st *= 10;
//    st = fract(st);
    st -= 0.5;
    st *= 2;
    st.x /= yOverX;

    float4 flower2 = hemiSpheresFlower(st, progress, stampUniforms);
    color = mix(color, flower2, flower2.a);

    return color;
}
