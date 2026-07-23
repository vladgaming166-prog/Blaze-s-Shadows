/*
====================================================================================
  Blaze's Shadows  -  lib/util/blackbody.glsl
------------------------------------------------------------------------------------
  Planckian black-body colour approximation. Converts a colour temperature in Kelvin
  to a linear RGB tint. Used for torch/block light colour and white-balance grading.

  Based on the well-known polynomial fit by Neil Bartlett / Tanner Helland, adapted
  to return values in linear space and normalised to a peak of 1.
====================================================================================
*/
#ifndef BLAZE_BLACKBODY_GLSL
#define BLAZE_BLACKBODY_GLSL

#include "/lib/util/math.glsl"
#include "/lib/util/encoding.glsl"

vec3 blackbody(float kelvin) {
    kelvin = clamp(kelvin, 1000.0, 15000.0) / 100.0;

    float r, g, b;

    // Red
    if (kelvin <= 66.0) {
        r = 1.0;
    } else {
        r = 1.29293618606274509804 * pow(kelvin - 60.0, -0.1332047592);
    }

    // Green
    if (kelvin <= 66.0) {
        g = 0.39008157876901960784 * log(kelvin) - 0.63184144378862745098;
    } else {
        g = 1.12989086089529411765 * pow(kelvin - 60.0, -0.0755148492);
    }

    // Blue
    if (kelvin >= 66.0) {
        b = 1.0;
    } else if (kelvin <= 19.0) {
        b = 0.0;
    } else {
        b = 0.54320678911019607843 * log(kelvin - 10.0) - 1.19625408914;
    }

    vec3 srgb = saturate(vec3(r, g, b));
    // Convert the sRGB fit to linear light for use in the lighting equations.
    return srgbToLinear(srgb);
}

#endif // BLAZE_BLACKBODY_GLSL
