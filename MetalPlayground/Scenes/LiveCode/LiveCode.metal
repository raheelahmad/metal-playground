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
    float noise;
} Palette;

constant int palettesCount = 4;
constant Palette palettes[palettesCount] = {
    Palette {
        .bgCols = {float3(0.7,0.7,0.8), float3(0.7,0.8,0.5)},
        .petalCols = {float3(0.92,90./255., 60/255), float3(67./255.,100./255., 131./255.)},
    },
    Palette {
        .bgCols = {float3(0.78,0.835,0.745), float3(0.549019607843137,0.603,0.5)},
        .petalCols = {float3(154.0/255.0,74.0/255,69/255.0), float3(110.0/255,152.0/255.0,61.0/255.0)},
    },
    Palette {
        .bgCols = {float3(0.62,0.64,0.94), float3(0.32,0.31,0.44)},
        .petalCols = {float3(0.18,0.25,0.25), float3(0.38,0.25,0.13)},
    },
    Palette {
        .bgCols = {float3(0.33,0.30,0.46), float3(0.50,0.498,0.52)},
        .petalCols = {float3(0.92,0.5,0.34), float3(0.83,0.5,0.54)},
    },
};

// --

Palette palette_for_stamp_uniform(StampUniforms uniforms) {
    float randIndexBase = random(uniforms.hourOfDay * uniforms.fullDurationMinutes)  * palettesCount;
    int idx = floor(randIndexBase);

    idx = 2;
    Palette palette = palettes[idx];

    float randBase = random(uniforms.hourOfDay + uniforms.fullDurationMinutes);
    palette.petalCount = ceil(randBase * 3)+1;
    randBase = lerp(randBase, 0, 1, 0.5, 1.0);
    palette.petalR = randBase*.49;

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

float posNoise(float2 p, StampUniforms uniforms) {
    float progress = uniforms.progress;
    float noiseF = noise(uniforms.fullDurationMinutes*uniforms.hourOfDay);
    float2 st = fract(p * random(noiseF) * 300);
    st = st * (100*noiseF + noise(progress)*noiseF*100);
    float angle = atan2(p.y, p.x);
    st = rotate(progress*p.x)*rotate(progress* random(p.y)) * st;
    st = rotate(noise(angle*20)) * st;
    float df = fract(noise(st))  * (1.-progress);
    return df;
}

float tulipPetal(float2 p, float r, int flipped, float noise) {
    float t = 0;

    r += noise*2.5;

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

float4 leaf(float2 leafSt, float r1, float r2, float3 topCol, float3 bottomCol, int useBottom, float noise)  {
    r1 += noise*abs(leafSt.x)*5;
    r2 += noise*5;

    leafSt -= float2(0.,sqrt(r1*r1 - r2*r2)); // position in the center-x of stem
    float t = petal(leafSt, r1, r2);
    float4 color = 0;
    color = mix(color, float4(topCol, 1), step(1., t));
    if (useBottom) {
        color = mix(color, float4(bottomCol, 1), step(1., halfPetal(leafSt, r1, r2)));
    }
    return color;
}

float4 openingFlower(float2 st, StampUniforms uniforms) {
    float progress = uniforms.progress;
    progress = 1.; // TODO; remove
    uniforms.progress = 1.; // TODO; remove
    Palette palette = palette_for_stamp_uniform(uniforms);
    float t = 0;

    float4 color = 0;

    float petalR = palette.petalR;

    // move up
    float2 petalSt = st;
    petalSt.y -= petalR;

    float noise = posNoise(st, uniforms);

    // triangle above petals
    t = sdTriangleIsosceles(petalSt*scale(1-noise*2)-float2(0,0.15), {0.28,-0.3});
    t = 1.-smoothstep(0., 0.001, t+noise);
    color = mix(color, float4(float3(0.1), 1.), t);


    // petals
    float colVar = 1.;
    float petalTH = 0.2;
    float petalL = 0.35;
    float2 displace = float2(petalTH/2.1,petalL/1.45);
    float2 topPetalSt = rotate(0.9 - noise) * (petalSt + displace) - displace;
    float leftSmallLeafCol = petal(topPetalSt, petalL, petalTH);
    color = mix(color, float4(palette.petalCols[0]/colVar, 1), step(1., leftSmallLeafCol));

    displace = float2(-petalTH/2.1,petalL/1.45);
    topPetalSt = rotate(-0.9 + noise) * (petalSt + displace) - displace;
    float rightSmallLeafCol = petal(topPetalSt, petalL, petalTH);
    color = mix(color, float4(palette.petalCols[1]/colVar, 1), step(1, rightSmallLeafCol));

    float3 green = {0.23, 0.39, 0.11};
    float3 black = {0.02, 0.09, 0.00};

    float stalkTH = 0.02;
    float2 stalkSt = petalSt-float2(0,-petalL/1.8);

    float r1 = 0.11;

    float bigR1 = r1 * 1.6;
    float bigR2 =  0.15;
    float rotateBigLeaf = M_PI_F/4;
    float leavePairsCount = palette.petalCount * 1.5;
    float leavesSpacing = 0.01;
    float leavesOffset = 0.14;

    for(float idx=0; idx < leavePairsCount; idx += 1) {
        float2 bigLeafSt;
        float randRotate = lerp(random(idx), 0,1, 0.8,1.4);
        randRotate = 0.9;
        // leaf 1
        bigLeafSt = stalkSt + float2(0, 0.4 + idx * leavesOffset);
        float4 leftBigLeafCol = leaf(rotate(rotateBigLeaf * randRotate) * bigLeafSt, bigR1, bigR2, green, 0, 0, noise);
        color = mix(color, leftBigLeafCol, leftBigLeafCol.a);
        // leaf 2
        bigLeafSt += float2(0, leavesSpacing);
        float4 rightBigLeafCol = leaf(rotate(-rotateBigLeaf * randRotate) * bigLeafSt, bigR1, bigR2, black, 0, 0, noise);
        color = mix(color, rightBigLeafCol, rightBigLeafCol.a);
    }

    // stalk
    t = rectangle(stalkSt, {-stalkTH/2+noise/2,0,stalkTH/2-noise/2,-1.3});
    color = mix(color, float4(0.12,0.24,0.1,1), step(1., t));

    return color*progress;
}

float4 hemiSpheresFlower(float2 st, StampUniforms uniforms) {
    uniforms.progress = 1;
    float progress = uniforms.progress;
    Palette palette = palette_for_stamp_uniform(uniforms);
    float t = 0;

    float4 color = 0;

    float petalR = palette.petalR;

    // TEST circle
    color = mix(color, float4(0.7,0.9,0.8,1), 1.-step(0.015, length(st)));

    // move up
    float2 petalSt = st;
    petalSt.y -= petalR;


    float noise = posNoise(st, uniforms);

    // triangle above petals
    t = sdTriangleIsosceles(petalSt-float2(0,0.3), {0.22,-0.3});
    t = 1.-smoothstep(0., 0.001, t+noise);
    color = mix(color, float4(float3(0.1), 1.), t);


    float petalCount = palette.petalCount;

    // petals
    float maxRotation = palette.petalCount * M_PI_F/19;
    for (int petalIdx=0; petalIdx < petalCount; petalIdx++) {
        float rotation = petalCount > 1 ? 1.0 - float(petalIdx) / (petalCount - 1) : 0;
        rotation *= maxRotation * progress;
        float colVar = float(petalIdx+0.1)/float(palette.petalCount);
        colVar = lerp(colVar, 0, 1, 0.6, 0.8);

        t = tulipPetal(rotate(rotation) * petalSt + float2(petalR,-0.0), petalR, 0, noise);
        color = mix(color, float4(palette.petalCols[0]/colVar, 1), t);

        t = tulipPetal(rotate(-rotation) * petalSt - float2(petalR,-0.0), petalR, 1, noise);
        color = mix(color, float4(palette.petalCols[1]/colVar, 1), t);
    }

    float3 green = {0.23, 0.39, 0.11};
    float3 black = {0.02, 0.09, 0.00};

    float stalkTH = 0.02;
    float2 stalkSt = petalSt-float2(0,-petalR);

    float r1 = 0.11;
    float r2 = 0.07;
    float rotateSmallLeaf = 1.5 * M_PI_F/2;

    // --- Small leaves on top
    float2 smallLeafSt = stalkSt;
    // leaf 1
    float2 leafSt = rotate(rotateSmallLeaf) * smallLeafSt; // position it down and rotate
    float4 leftSmallLeafCol = leaf(leafSt, r1, r2, green, black, 1, noise);
    color = mix(color, leftSmallLeafCol, leftSmallLeafCol.a);
    // leaf 2
    float4 rightSmallLeafCol = leaf(rotate(-rotateSmallLeaf) * smallLeafSt, r1, r2, green, black, 1, noise);
    color = mix(color, rightSmallLeafCol, rightSmallLeafCol.a);

    float bigR1 = r1 * 2.1;
    float bigR2 =  0.16;
    float rotateBigLeaf = M_PI_F/4;
    float2 bigLeafSt = stalkSt + float2(0, 0.6);
    // leaf 1
    float4 leftBigLeafCol = leaf(rotate(rotateBigLeaf) * bigLeafSt, bigR1, bigR2, green, 0, 0, noise);
    color = mix(color, leftBigLeafCol, leftBigLeafCol.a);
    // leaf 2
    float4 rightBigLeafCol = leaf(rotate(-rotateBigLeaf) * bigLeafSt, bigR1, bigR2, black, 0, 0, noise);
    color = mix(color, rightBigLeafCol, rightBigLeafCol.a);

    // stalk
    t = rectangle(stalkSt, {-stalkTH/2+noise/2,0,stalkTH/2-noise/2,-1.});
    color = mix(color, float4(0.12,0.24,0.1,1), step(1., t));


    // vein lines
    float veinTH = 0.002;
    float4 lineBox = {-veinTH,0.,veinTH,-0.33*progress};
    float2 veinSt = rotate(-rotateBigLeaf+M_PI_F*1.5) * bigLeafSt;
    //    veinSt.x += sin(veinSt.y*310)/330;
    color = mix(color, float4(black, 1), rectangle(veinSt, lineBox));

    veinSt = rotate(rotateBigLeaf-M_PI_F*1.5) * bigLeafSt;
    color = mix(color, float4(green, 1), rectangle(veinSt, lineBox));

    return color*progress;
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

    StampUniforms redidUniforms = stampUniforms;
    redidUniforms.progress = clamp(lerp(stampUniforms.progress, 0, 1, 0, 1.1), 0., 1.);
//    redidUniforms.progress = 1;

    float4 color = mix(float4(palette.bgCols[1], 1), float4(palette.bgCols[0], 1), pow(st.y, .5));

//    st *= 3;
//    st = fract(st);
    st -= 0.5;
    st *= 2;
    st.x /= yOverX;

    float randomFlowerIndex = hash(redidUniforms.fullDurationMinutes + redidUniforms.hourOfDay);
    randomFlowerIndex = 0.2;
    if (randomFlowerIndex > 0.5) {
        float4 flower2 = hemiSpheresFlower(st, redidUniforms);
        color = mix(color, flower2, flower2.a);
    } else {
        float4 flower2 = openingFlower(st, redidUniforms);
        color = mix(color, flower2, flower2.a);
    }

    return color;
}
