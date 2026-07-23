/*
====================================================================================
  Blaze's Shadows  -  lib/lighting/shadow_distort.glsl
------------------------------------------------------------------------------------
  Shadow-clip distortion, split out so both the shadow vertex program (which warps
  geometry into the map) and the deferred sampler (which warps lookups) agree
  perfectly. Any mismatch here produces peter-panning or acne.
====================================================================================
*/
#ifndef BLAZE_SHADOW_DISTORT_GLSL
#define BLAZE_SHADOW_DISTORT_GLSL

const float SHADOW_DISTORTION = 0.85;

// Bunch texels toward the centre (near the player) - a single-map cascade emulation.
vec3 distortShadowClip(vec3 clip) {
    float dist = length(clip.xy);
    float factor = dist * SHADOW_DISTORTION + (1.0 - SHADOW_DISTORTION);
    clip.xy /= factor;
    clip.z *= 0.5; // compress depth for precision
    return clip;
}

float distortFactor(vec2 clipXY) {
    float dist = length(clipXY);
    return dist * SHADOW_DISTORTION + (1.0 - SHADOW_DISTORTION);
}

#endif // BLAZE_SHADOW_DISTORT_GLSL
