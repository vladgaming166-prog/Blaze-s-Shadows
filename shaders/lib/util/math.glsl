/*
====================================================================================
  Blaze's Shadows  -  lib/util/math.glsl
------------------------------------------------------------------------------------
  Small, branch-light math helpers. All functions are pure and side-effect free so
  the compiler is free to inline and reorder them.
====================================================================================
*/
#ifndef BLAZE_MATH_GLSL
#define BLAZE_MATH_GLSL

#include "/lib/util/constants.glsl"

// Squared helpers - cheaper and clearer than pow(x, 2.0).
float sqr(float x)  { return x * x; }
vec2  sqr(vec2 x)   { return x * x; }
vec3  sqr(vec3 x)   { return x * x; }
float cube(float x) { return x * x * x; }

// Dot of a vector with itself (squared length). Handy for attenuation.
float lengthSq(vec2 v) { return dot(v, v); }
float lengthSq(vec3 v) { return dot(v, v); }

// Max/min of vector components.
float maxOf(vec2 v) { return max(v.x, v.y); }
float maxOf(vec3 v) { return max(v.x, max(v.y, v.z)); }
float minOf(vec3 v) { return min(v.x, min(v.y, v.z)); }

// Rec.709 luminance (perceptual brightness of a linear RGB colour).
float luminance(vec3 c) { return dot(c, vec3(0.2126, 0.7152, 0.0722)); }

// Remap x from [a,b] to [0,1] with clamping.
float linearStep(float a, float b, float x) {
    return clamp((x - a) / (b - a), 0.0, 1.0);
}

// Remap from one range to another.
float remap(float x, float inLo, float inHi, float outLo, float outHi) {
    return outLo + (outHi - outLo) * linearStep(inLo, inHi, x);
}

// Saturate shortcuts.
float saturate(float x) { return clamp(x, 0.0, 1.0); }
vec2  saturate(vec2 x)  { return clamp(x, 0.0, 1.0); }
vec3  saturate(vec3 x)  { return clamp(x, 0.0, 1.0); }
vec4  saturate(vec4 x)  { return clamp(x, 0.0, 1.0); }

// max against zero - common for clamping dot products.
float max0(float x) { return max(x, 0.0); }
vec3  max0(vec3 x)  { return max(x, vec3(0.0)); }

// Build an orthonormal basis around a unit normal (Duff et al. 2017, branchless).
mat3 orthoBasis(vec3 n) {
    float s = n.z >= 0.0 ? 1.0 : -1.0;
    float a = -1.0 / (s + n.z);
    float b = n.x * n.y * a;
    vec3 t = vec3(1.0 + s * n.x * n.x * a, s * b, -s * n.x);
    vec3 bt = vec3(b, s + n.y * n.y * a, -n.y);
    return mat3(t, bt, n);
}

// Fast approximate ACES-like exponent-free rotation of a 2D vector.
vec2 rotate2D(vec2 v, float a) {
    float s = sin(a), c = cos(a);
    return vec2(v.x * c - v.y * s, v.x * s + v.y * c);
}

// Smooth minimum (polynomial) - useful for blending SDF-ish quantities.
float smoothMin(float a, float b, float k) {
    float h = saturate(0.5 + 0.5 * (b - a) / k);
    return mix(b, a, h) - k * h * (1.0 - h);
}

#endif // BLAZE_MATH_GLSL
