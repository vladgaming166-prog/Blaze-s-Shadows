/*
====================================================================================
  Blaze's Shadows  -  lib/atmosphere/common.glsl
------------------------------------------------------------------------------------
  Time-of-day driven light colours and a few shared atmosphere helpers. Everything
  is derived from the sun's world-space elevation so the transitions (dawn, noon,
  dusk, night) are continuous and physically motivated rather than keyed to
  worldTime buckets.

  Requires the caller to provide:
    worldSunDir   - normalized sun direction in world space
    worldMoonDir  - normalized moon direction in world space
  These are cheap to compute from sunPosition/moonPosition (see spaces helpers).
====================================================================================
*/
#ifndef BLAZE_ATMOS_COMMON_GLSL
#define BLAZE_ATMOS_COMMON_GLSL

#include "/lib/settings.glsl"
#include "/lib/util/math.glsl"
#include "/lib/util/blackbody.glsl"

// Henyey-Greenstein phase function (forward scattering, used by sky + clouds + VL).
float phaseHG(float cosTheta, float g) {
    float g2 = g * g;
    return (1.0 - g2) / (4.0 * PI * pow(max(1.0 + g2 - 2.0 * g * cosTheta, 1e-4), 1.5));
}

// Rayleigh phase for the clear-sky blue.
float phaseRayleigh(float cosTheta) {
    return 0.75 * (1.0 + cosTheta * cosTheta) * (3.0 / (16.0 * PI));
}

// Named colours (linear space) that we blend between over the day.
const vec3 KCOLOR_NOON    = vec3(1.00, 0.96, 0.88);
const vec3 KCOLOR_GOLDEN  = vec3(1.00, 0.62, 0.32); // low sun, warm
const vec3 KCOLOR_SUNSET  = vec3(1.00, 0.42, 0.18); // horizon
const vec3 KCOLOR_MOON    = vec3(0.30, 0.44, 0.78); // cool moonlight
const vec3 KSKY_DAY       = vec3(0.36, 0.58, 1.00);
const vec3 KSKY_HORIZON   = vec3(0.72, 0.82, 1.00);
const vec3 KSKY_SUNSET    = vec3(0.92, 0.52, 0.34);
const vec3 KSKY_NIGHT     = vec3(0.03, 0.055, 0.12);

// Smooth 0..1 factors describing which part of the day we are in.
struct DayPhase {
    float sunHeight;   // worldSunDir.y  (-1..1)
    float day;         // 1 while sun clearly up
    float night;       // 1 while sun clearly down
    float twilight;    // peaks at the horizon crossing
    float noon;        // 1 near the zenith
};

DayPhase getDayPhase(float sunHeight) {
    DayPhase p;
    p.sunHeight = sunHeight;
    p.day       = linearStep(-0.02, 0.14, sunHeight);
    p.night     = linearStep(-0.02, -0.14, sunHeight);
    // Twilight is the narrow band around the horizon.
    p.twilight  = (1.0 - abs(linearStep(-0.18, 0.18, sunHeight) * 2.0 - 1.0));
    p.noon      = linearStep(0.35, 0.75, sunHeight);
    return p;
}

// Direct sunlight colour (used to light the world when the sun is the shadow caster).
vec3 getSunlightColor(DayPhase p, float rain) {
    // Warm at the horizon, neutral overhead.
    vec3 c = mix(KCOLOR_SUNSET, KCOLOR_NOON, linearStep(0.02, 0.55, p.sunHeight));
    c = mix(KCOLOR_GOLDEN, c, linearStep(0.06, 0.22, p.sunHeight));
    // Rain desaturates and dims the sun.
    c = mix(c, vec3(luminance(c)) * vec3(0.85, 0.88, 0.95), rain * 0.7);
    return c * SUNLIGHT_INTENSITY;
}

// Direct moonlight colour.
vec3 getMoonlightColor(float rain) {
    vec3 c = KCOLOR_MOON;
    c = mix(c, vec3(luminance(c)), rain * 0.5);
    return c * MOONLIGHT_INTENSITY * 0.08; // moon is far dimmer than the sun
}

// The colour of whichever body is currently the shadow caster.
vec3 getShadowLightColor(DayPhase p, float rain) {
    return mix(getMoonlightColor(rain), getSunlightColor(p, rain), p.day);
}

// Ambient sky illumination colour (fills shadowed areas).
vec3 getSkyAmbientColor(DayPhase p, float rain) {
    vec3 day   = mix(KSKY_HORIZON, KSKY_DAY, p.noon);
    vec3 dusk  = KSKY_SUNSET;
    vec3 night = KSKY_NIGHT;
    vec3 c = mix(night, day, p.day);
    c = mix(c, dusk, p.twilight * (1.0 - p.night) * 0.6);
    c = mix(c, vec3(luminance(c)) * vec3(0.7, 0.75, 0.85), rain * 0.6);
    return c * AMBIENT_INTENSITY;
}

// Bounced/indirect "bottom" ambient (ground colour), slightly warmer.
vec3 getGroundAmbientColor(DayPhase p, float rain) {
    return getSkyAmbientColor(p, rain) * vec3(0.55, 0.52, 0.48);
}

#endif // BLAZE_ATMOS_COMMON_GLSL
