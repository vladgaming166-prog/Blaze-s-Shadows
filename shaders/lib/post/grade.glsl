/*
====================================================================================
  Blaze's Shadows  -  lib/post/grade.glsl
------------------------------------------------------------------------------------
  Colour grading applied after tonemapping (operates in ~display space):
    exposure/brightness, contrast around 18% grey, saturation, vibrance (protects
    already-saturated colours and skin tones), white balance and per-channel tint,
    and a final gamma trim.
====================================================================================
*/
#ifndef BLAZE_GRADE_GLSL
#define BLAZE_GRADE_GLSL

#include "/lib/settings.glsl"
#include "/lib/util/math.glsl"
#include "/lib/util/blackbody.glsl"

// White-balance multiplier derived from a target colour temperature.
vec3 whiteBalanceTint(float kelvin) {
    // Normalise so 6500K is neutral.
    vec3 target = blackbody(kelvin);
    vec3 neutral = blackbody(6500.0);
    return neutral / max(target, vec3(1e-3));
}

vec3 colorGrade(vec3 c) {
    // Contrast around middle grey.
    const float grey = 0.18;
    c = (c - grey) * CONTRAST + grey;

    // Saturation.
    float l = luminance(c);
    c = mix(vec3(l), c, SATURATION);

    // Vibrance: boost muted colours more than already-vivid ones.
    float mx = maxOf(c);
    float mn = minOf(c);
    float sat = mx - mn;
    c = mix(vec3(l), c, 1.0 + (VIBRANCE - 1.0) * (1.0 - sat));

    // White balance + artistic tint.
    c *= whiteBalanceTint(float(WHITE_BALANCE));
    c *= vec3(TINT_R, TINT_G, TINT_B);

    // Brightness.
    c *= BRIGHTNESS;

    // Gamma trim.
    c = pow(max0(c), vec3(1.0 / GAMMA));

    return c;
}

#endif // BLAZE_GRADE_GLSL
