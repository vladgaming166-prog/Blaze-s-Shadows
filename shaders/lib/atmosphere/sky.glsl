/*
====================================================================================
  Blaze's Shadows  -  lib/atmosphere/sky.glsl
------------------------------------------------------------------------------------
  A stylised-but-physically-motivated analytic sky. Rather than a full multi-scatter
  raymarch (expensive) we combine:
    * a Rayleigh-tinted vertical gradient (blue up, bright toward the horizon),
    * a Mie forward-scatter lobe for the warm glow around the sun,
    * a soft sun/moon disc,
    * night-sky tint.
  The result is cheap, temporally stable, and reads well from horizon to zenith.
====================================================================================
*/
#ifndef BLAZE_SKY_GLSL
#define BLAZE_SKY_GLSL

#include "/lib/atmosphere/common.glsl"

/*
  Core sky evaluation.
    worldDir  - view ray direction in world space (normalized)
    sunDir    - sun direction (world)
    moonDir   - moon direction (world)
*/
vec3 getSkyColor(vec3 worldDir, vec3 sunDir, vec3 moonDir, DayPhase p, float rain) {
    float up   = saturate(worldDir.y * 0.5 + 0.5);
    float hori = 1.0 - abs(worldDir.y);          // 1 at horizon, 0 at poles
    float cosSun  = dot(worldDir, sunDir);
    float cosMoon = dot(worldDir, moonDir);

    // --- Base gradient -------------------------------------------------------
    vec3 zenith  = mix(KSKY_NIGHT, KSKY_DAY, p.day);
    vec3 horizon = mix(KSKY_NIGHT * 1.4, KSKY_HORIZON, p.day);

    // Warm the horizon toward the sun during twilight.
    float sunHori = saturate(cosSun) * pow(hori, 3.0);
    horizon = mix(horizon, KSKY_SUNSET, p.twilight * (0.35 + 0.65 * sunHori));

    vec3 sky = mix(horizon, zenith, pow(up, 0.55));

    // --- Mie glow around the sun/moon ---------------------------------------
    float sunGlow  = phaseHG(cosSun, 0.76) * 6.0;
    sky += getSunlightColor(p, rain) * sunGlow * (0.25 + p.twilight * 0.9);

    float moonGlow = phaseHG(cosMoon, 0.6) * 2.0 * p.night;
    sky += getMoonlightColor(rain) * moonGlow * 4.0;

    // --- Rayleigh brightening toward horizon --------------------------------
    sky += KSKY_DAY * phaseRayleigh(cosSun) * p.day * (0.2 + 0.8 * hori);

    // --- Rain: flatten to a grey overcast dome ------------------------------
    vec3 overcast = mix(vec3(0.30, 0.33, 0.38), vec3(0.05, 0.06, 0.08), p.night);
    sky = mix(sky, overcast, rain * 0.85);

    // --- User grading --------------------------------------------------------
    sky *= SKY_BRIGHTNESS;
    sky = mix(vec3(luminance(sky)), sky, SKY_SATURATION);

    return max0(sky);
}

// Sharp sun/moon discs added on top of the gradient (only where geometry is sky).
vec3 getSunMoonDiscs(vec3 worldDir, vec3 sunDir, vec3 moonDir, DayPhase p, float rain) {
    vec3 result = vec3(0.0);

    float sunCos  = dot(worldDir, sunDir);
    float sunDisc = smoothstep(0.9993, 0.99965, sunCos);
    result += getSunlightColor(p, rain) * sunDisc * 20.0 * (1.0 - rain);

    float moonCos  = dot(worldDir, moonDir);
    float moonDisc = smoothstep(0.9990, 0.99955, moonCos);
    // Fake a phase by carving a shadow across the moon.
    vec3 moonTint = vec3(0.9, 0.92, 1.0);
    result += moonTint * moonDisc * 6.0 * p.night * (1.0 - rain);

    return result;
}

#endif // BLAZE_SKY_GLSL
