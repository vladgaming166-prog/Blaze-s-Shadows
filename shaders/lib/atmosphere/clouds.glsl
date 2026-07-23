/*
====================================================================================
  Blaze's Shadows  -  lib/atmosphere/clouds.glsl
------------------------------------------------------------------------------------
  Ray-marched volumetric clouds confined to a horizontal slab. The density field is
  a couple of octaves of animated fbm, shaped by a coverage threshold and a soft
  vertical falloff so the tops and bottoms round off.

  Lighting uses a cheap two-tap "light energy" march toward the sun plus Beer-Powder
  for the silver-lining look. Returns premultiplied colour in .rgb and the through
  transmittance in .a (1 = fully see-through).
====================================================================================
*/
#ifndef BLAZE_CLOUDS_GLSL
#define BLAZE_CLOUDS_GLSL

#include "/lib/atmosphere/common.glsl"
#include "/lib/util/noise.glsl"

const float CLOUD_BOTTOM = CLOUD_HEIGHT;
const float CLOUD_TOP    = CLOUD_HEIGHT + CLOUD_THICKNESS;

// Sample the cloud density field at a world position.
float cloudDensity(vec3 wp, float rain) {
    // Animate along the wind direction.
    vec3 wind = vec3(1.0, 0.0, 0.35) * frameTimeCounter * 12.0 * WIND_SPEED;
    vec3 p = (wp + wind) * 0.0016;

    float base = fbm(p, 4, 2.1, 0.55);
    // Coverage rises with rain for storm build-up.
    float cov = mix(CLOUD_COVERAGE, 0.82, rain);
    float d = saturate((base - (1.0 - cov)) / cov);

    // Erode edges with higher frequency detail.
    float detail = fbm(p * 4.0 + 5.0, 3, 2.2, 0.5);
    d = saturate(d - detail * 0.25 * (1.0 - d));

    // Vertical rounding inside the slab.
    float h = saturate((wp.y - CLOUD_BOTTOM) / CLOUD_THICKNESS);
    float shape = smoothstep(0.0, 0.15, h) * smoothstep(1.0, 0.55, h);
    return d * shape;
}

// Beer-Powder term gives clouds their bright, fluffy edges.
float beerPowder(float density) {
    return exp(-density) * (1.0 - exp(-2.0 * density));
}

vec4 renderClouds(vec3 worldDir, vec3 sunDir, DayPhase p, float rain, float dither) {
#ifndef CLOUDS
    return vec4(0.0, 0.0, 0.0, 1.0);
#else
    // Only march when the ray actually rises into the slab (from below it).
    if (worldDir.y <= 0.02) return vec4(0.0, 0.0, 0.0, 1.0);

    // Slab entry/exit distances relative to the camera's altitude.
    float tBottom = (CLOUD_BOTTOM - cameraPosition.y) / worldDir.y;
    float tTop    = (CLOUD_TOP - cameraPosition.y) / worldDir.y;
    tBottom = max(tBottom, 0.0);
    float marchLen = tTop - tBottom;
    if (marchLen <= 0.0) return vec4(0.0, 0.0, 0.0, 1.0);

#ifdef CLOUDS_VOLUMETRIC
    int steps = CLOUD_SAMPLES;
#else
    int steps = 6; // cheap single-layer fallback
#endif
    float stepLen = marchLen / float(steps);

    vec3 lightCol = getSunlightColor(p, rain) + getMoonlightColor(rain) * p.night * 6.0;
    vec3 ambient  = getSkyAmbientColor(p, rain) * 1.2;

    float transmittance = 1.0;
    vec3  scatter = vec3(0.0);

    float cosSun = dot(worldDir, sunDir);
    float phase = mix(phaseHG(cosSun, 0.35), phaseHG(cosSun, 0.7), 0.5);

    float t = tBottom + stepLen * dither;
    for (int i = 0; i < steps; i++) {
        vec3 wp = cameraPosition + worldDir * t;
        float density = cloudDensity(wp, rain);
        if (density > 0.001) {
            // Light march: two taps toward the sun estimate self-shadowing.
            float ld = 0.0;
            vec3 ls = sunDir * (CLOUD_THICKNESS * 0.15);
            ld += cloudDensity(wp + ls, rain);
            ld += cloudDensity(wp + ls * 2.5, rain) * 0.5;
            float lightEnergy = beerPowder(ld * 1.6);

            vec3 stepCol = lightCol * lightEnergy * phase + ambient * 0.5;
            float stepTrans = exp(-density * stepLen * 0.06);
            // Energy-conserving accumulation.
            scatter += transmittance * (1.0 - stepTrans) * stepCol;
            transmittance *= stepTrans;
            if (transmittance < 0.02) break;
        }
        t += stepLen;
    }

    // Fade clouds out near the horizon so the slab edge is invisible.
    float horizonFade = smoothstep(0.02, 0.14, worldDir.y);
    float alpha = (1.0 - transmittance) * horizonFade;
    return vec4(scatter * horizonFade, 1.0 - alpha);
#endif
}

#endif // BLAZE_CLOUDS_GLSL
