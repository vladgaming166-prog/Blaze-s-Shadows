/*
====================================================================================
  Blaze's Shadows  -  lib/util/noise.glsl
------------------------------------------------------------------------------------
  Hash based value noise + fractal Brownian motion, plus helpers for sampling the
  bundled blue-noise-ish `noisetex`. Used by clouds, water, aurora, grain, etc.
====================================================================================
*/
#ifndef BLAZE_NOISE_GLSL
#define BLAZE_NOISE_GLSL

#include "/lib/util/math.glsl"

// The pack ships a 256x256 tiling noise texture bound as `noisetex`.
uniform sampler2D noisetex;
const int noiseTextureResolution = 256; // OptiFine reads this const to size noisetex.

/* ---------- cheap integer hashes ---------- */
float hash11(float p) {
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

float hash13(vec3 p) {
    p = fract(p * 0.1031);
    p += dot(p, p.zyx + 31.32);
    return fract((p.x + p.y) * p.z);
}

/* ---------- value noise ---------- */
float valueNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f); // smoothstep interpolation
    float a = hash12(i + vec2(0.0, 0.0));
    float b = hash12(i + vec2(1.0, 0.0));
    float c = hash12(i + vec2(0.0, 1.0));
    float d = hash12(i + vec2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float valueNoise(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    vec3 u = f * f * (3.0 - 2.0 * f);
    float n000 = hash13(i + vec3(0, 0, 0));
    float n100 = hash13(i + vec3(1, 0, 0));
    float n010 = hash13(i + vec3(0, 1, 0));
    float n110 = hash13(i + vec3(1, 1, 0));
    float n001 = hash13(i + vec3(0, 0, 1));
    float n101 = hash13(i + vec3(1, 0, 1));
    float n011 = hash13(i + vec3(0, 1, 1));
    float n111 = hash13(i + vec3(1, 1, 1));
    return mix(mix(mix(n000, n100, u.x), mix(n010, n110, u.x), u.y),
               mix(mix(n001, n101, u.x), mix(n011, n111, u.x), u.y), u.z);
}

// Sample the bundled noise texture with smooth (bilinear) filtering.
float textureNoise(vec2 p) {
    return texture(noisetex, p / float(noiseTextureResolution)).r;
}

/* ---------- fractal Brownian motion ---------- */
float fbm(vec2 p, int octaves, float lacunarity, float gain) {
    float sum = 0.0, amp = 0.5, freq = 1.0;
    for (int i = 0; i < octaves; i++) {
        sum += amp * valueNoise(p * freq);
        freq *= lacunarity;
        amp *= gain;
    }
    return sum;
}

float fbm(vec3 p, int octaves, float lacunarity, float gain) {
    float sum = 0.0, amp = 0.5, freq = 1.0;
    for (int i = 0; i < octaves; i++) {
        sum += amp * valueNoise(p * freq);
        freq *= lacunarity;
        amp *= gain;
    }
    return sum;
}

// Convenience overloads with sensible defaults.
float fbm(vec2 p) { return fbm(p, 5, 2.0, 0.5); }
float fbm(vec3 p) { return fbm(p, 5, 2.0, 0.5); }

// Interleaved gradient noise - excellent low-discrepancy dither for a given pixel.
float interleavedGradient(vec2 pixel) {
    return fract(52.9829189 * fract(dot(pixel, vec2(0.06711056, 0.00583715))));
}
float interleavedGradient(vec2 pixel, float frame) {
    pixel += 5.588238 * fract(frame * 0.6180339887);
    return interleavedGradient(pixel);
}

#endif // BLAZE_NOISE_GLSL
