/*
====================================================================================
  Blaze's Shadows  -  lib/atmosphere/fog.glsl
------------------------------------------------------------------------------------
  Analytic fog: exponential distance haze tinted by the sky, plus a height term for
  low-lying mist, a cave-darkness term and a border fog that hides the render edge.
  Underwater / lava / powder-snow media are handled separately with their own
  absorption tints.
====================================================================================
*/
#ifndef BLAZE_FOG_GLSL
#define BLAZE_FOG_GLSL

#include "/lib/atmosphere/common.glsl"

// Exponential-squared falloff - softer near the camera, firmer far away.
float fogFactorExp2(float dist, float density) {
    float d = dist * density;
    return 1.0 - saturate(exp(-d * d));
}

float fogFactorExp(float dist, float density) {
    return 1.0 - saturate(exp(-dist * density));
}

/*
  Atmospheric distance fog for the overworld.
    color     - scene colour so far
    scenePos  - player-space position of the fragment
    skyCol    - sky colour in this view direction (so distant fog matches the sky)
    skyLight  - fragment sky-light (0..1); low values => cave, gets cave fog instead
*/
vec3 applyOverworldFog(vec3 color, vec3 scenePos, vec3 skyCol, DayPhase p,
                       float rain, float skyLight, float far) {
    float dist = length(scenePos);

#ifdef ATMOSPHERIC_FOG
    // Base density grows with rain; tuned so it is subtle in clear weather.
    float density = (0.0009 + rain * 0.0016) * FOG_DENSITY;
    float fog = fogFactorExp2(dist, density);

#ifdef VOLUMETRIC_FOG
    // Height fog: denser near sea level, thinning with altitude.
    float worldY = scenePos.y + cameraPosition.y;
    float heightFog = exp(-max(worldY - 62.0, 0.0) * 0.02);
    fog = saturate(fog + heightFog * fogFactorExp(dist, 0.004)
                   * (0.15 + rain * 0.35) * VL_FOG_DENSITY);
#endif

    color = mix(color, skyCol, fog * saturate(skyLight * 1.5 + 0.15));
#endif

#ifdef CAVE_FOG
    // In caves (low sky light) fade to a dim ambient instead of the bright sky.
    vec3 caveCol = getSkyAmbientColor(p, rain) * 0.05 + vec3(0.004);
    float caveFog = fogFactorExp2(dist, 0.006 * FOG_DENSITY) * (1.0 - saturate(skyLight * 2.0));
    color = mix(color, caveCol, caveFog);
#endif

#ifdef BORDER_FOG
    // Hide the hard render-distance cut-off with a ring of sky-coloured fog.
    float border = smoothstep(far * 0.7, far * 0.98, dist);
    color = mix(color, skyCol, border);
#endif

    return color;
}

// Underwater / lava / powder-snow media applied when the eye is submerged.
vec3 applyMediumFog(vec3 color, vec3 scenePos, int medium, DayPhase p, float rain) {
    float dist = length(scenePos);
    if (medium == 1) {
        // Water: strong wavelength-dependent absorption.
        vec3 absorb = vec3(WATER_ABSORPTION_R, WATER_ABSORPTION_G, WATER_ABSORPTION_B);
        vec3 t = exp(-absorb * dist * (0.35 * WATER_FOG_DENSITY));
        vec3 waterCol = getSkyAmbientColor(p, rain) * vec3(0.1, 0.35, 0.5);
        color = color * t + waterCol * (1.0 - t) * 0.6;
    } else if (medium == 2) {
        // Lava: near-opaque orange.
        float fog = fogFactorExp(dist, 0.7);
        color = mix(color, vec3(0.9, 0.28, 0.05), fog);
    } else if (medium == 3) {
        // Powder snow: bright white-out.
        float fog = fogFactorExp(dist, 0.5);
        color = mix(color, vec3(0.9, 0.93, 0.98), fog);
    }
    return color;
}

#endif // BLAZE_FOG_GLSL
