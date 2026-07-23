/*
====================================================================================
  Blaze's Shadows  -  lib/post/bloom.glsl
------------------------------------------------------------------------------------
  Helpers for the separable Gaussian bloom chain. A soft-knee bright pass extracts
  HDR highlights; two ping-ponged H/V blur iterations widen them into a smooth glow.
====================================================================================
*/
#ifndef BLAZE_BLOOM_GLSL
#define BLAZE_BLOOM_GLSL

#include "/lib/settings.glsl"
#include "/lib/util/math.glsl"

// Soft-knee highlight extraction (keeps a little of everything so HDR bloom is smooth).
vec3 bloomBrightPass(vec3 color) {
    float l = luminance(color);
    // Weight that ramps up above ~0.8 but never fully kills the mids.
    float knee = smoothstep(0.5, 1.4, l);
    return color * (0.15 + 0.85 * knee);
}

// 9-tap Gaussian along `dir` (in texels). Weights sum to 1.
vec3 gaussianBlur(sampler2D tex, vec2 uv, vec2 dir, vec2 texelSize) {
    const float w[5] = float[5](0.227027, 0.194595, 0.121622, 0.054054, 0.016216);
    vec2 stepv = dir * texelSize * BLOOM_RADIUS * 2.0;
    vec3 result = texture(tex, uv).rgb * w[0];
    for (int i = 1; i < 5; i++) {
        result += texture(tex, uv + stepv * float(i)).rgb * w[i];
        result += texture(tex, uv - stepv * float(i)).rgb * w[i];
    }
    return result;
}

#endif // BLAZE_BLOOM_GLSL
