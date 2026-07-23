/*
====================================================================================
  Blaze's Shadows  -  lib/post/tonemap.glsl
------------------------------------------------------------------------------------
  A small library of HDR->LDR tonemapping operators, selectable via TONEMAP_OPERATOR.
  Each maps unbounded linear radiance into the displayable [0,1] range with a
  different contrast/roll-off character.
====================================================================================
*/
#ifndef BLAZE_TONEMAP_GLSL
#define BLAZE_TONEMAP_GLSL

#include "/lib/settings.glsl"
#include "/lib/util/math.glsl"

// Simple extended Reinhard.
vec3 tonemapReinhard(vec3 x) {
    return x / (1.0 + luminance(x));
}

// ACES filmic (Narkowicz fit) - punchy, saturated highlights.
vec3 tonemapACES(vec3 x) {
    const float a = 2.51, b = 0.03, c = 2.43, d = 0.59, e = 0.14;
    return saturate((x * (a * x + b)) / (x * (c * x + d) + e));
}

// Uchimura "Gran Turismo" curve - controllable linear midtones + smooth shoulder.
vec3 tonemapUchimura(vec3 x) {
    const float P = 1.0;   // max display brightness
    const float a = 1.0;   // contrast
    const float m = 0.22;  // linear section start
    const float l = 0.4;   // linear section length
    const float c = 1.33;  // black tightness
    const float b = 0.0;

    float l0 = ((P - m) * l) / a;
    float S0 = m + l0;
    float S1 = m + a * l0;
    float C2 = (a * P) / (P - S1);
    float CP = -C2 / P;

    vec3 w0 = 1.0 - smoothstep(vec3(0.0), vec3(m), x);
    vec3 w2 = step(vec3(m + l0), x);
    vec3 w1 = 1.0 - w0 - w2;

    vec3 T = m * pow(x / m, vec3(c)) + b;
    vec3 S = P - (P - S1) * exp(CP * (x - S0));
    vec3 L = m + a * (x - m);

    return T * w0 + L * w1 + S * w2;
}

// Lottes curve.
vec3 tonemapLottes(vec3 x) {
    const float a = 1.6, d = 0.977, hdrMax = 8.0, midIn = 0.18, midOut = 0.267;
    float b = (-pow(midIn, a) + pow(hdrMax, a) * midOut) /
              ((pow(hdrMax, a * d) - pow(midIn, a * d)) * midOut);
    float c = (pow(hdrMax, a * d) * pow(midIn, a) - pow(hdrMax, a) * pow(midIn, a * d) * midOut) /
              ((pow(hdrMax, a * d) - pow(midIn, a * d)) * midOut);
    return pow(x, vec3(a)) / (pow(x, vec3(a * d)) * b + c);
}

// AgX-inspired minimal operator: desaturates highlights for a modern filmic look.
vec3 tonemapAgX(vec3 x) {
    // Log-encode, apply a sigmoid, then a gentle power.
    const mat3 agxIn = mat3(
        0.842, 0.042, 0.042,
        0.079, 0.878, 0.079,
        0.079, 0.079, 0.879);
    x = agxIn * x;
    x = clamp((log2(x + 1e-6) + 12.47) / 16.5, 0.0, 1.0);
    // Polynomial sigmoid approximation.
    vec3 x2 = x * x;
    x = 0.5 + (x - 0.5) * (1.0 + 0.6 * (1.0 - x2)); // soft s-curve
    x = saturate(x);
    return pow(x, vec3(1.15));
}

vec3 tonemap(vec3 x) {
#if   TONEMAP_OPERATOR == 0
    return tonemapReinhard(x);
#elif TONEMAP_OPERATOR == 1
    return tonemapACES(x);
#elif TONEMAP_OPERATOR == 2
    return tonemapUchimura(x);
#elif TONEMAP_OPERATOR == 3
    return tonemapAgX(x);
#else
    return tonemapLottes(x);
#endif
}

#endif // BLAZE_TONEMAP_GLSL
