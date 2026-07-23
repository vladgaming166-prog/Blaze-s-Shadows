/*
====================================================================================
  Blaze's Shadows  -  lib/vertex/waving.glsl
------------------------------------------------------------------------------------
  World-space vertex displacement for wind-affected geometry. Block identification
  is driven by block.properties, which tags blocks with the IDs referenced below.

  The `topOnly` weight makes anchored plants (grass, crops, saplings) pivot from
  their base while leaves/vines wobble more uniformly. Kelp and seagrass sway with
  a slower, deeper motion to read as underwater.
====================================================================================
*/
#ifndef BLAZE_WAVING_GLSL
#define BLAZE_WAVING_GLSL

#include "/lib/settings.glsl"
#include "/lib/util/noise.glsl"

// Block id ranges (see block.properties).
#define ID_PLANT_SMALL 10001 // grass, flowers, ferns, saplings
#define ID_PLANT_TALL  10002 // tall grass/fern upper + lower
#define ID_LEAVES      10003
#define ID_VINES       10004
#define ID_WATERPLANT  10005 // kelp, seagrass
#define ID_CROPS       10006
#define ID_LANTERN     10007 // hanging lanterns swing gently

// Multi-frequency 2D wind field sampled at a world position.
vec2 windField(vec2 xz, float t) {
    vec2 w = vec2(0.0);
    w.x += sin(xz.x * 0.14 + xz.y * 0.10 + t * 1.3);
    w.y += cos(xz.x * 0.11 - xz.y * 0.13 + t * 1.1);
    // A slower, larger gust component.
    w.x += 0.6 * sin(xz.x * 0.05 + t * 0.5);
    w.y += 0.6 * sin(xz.y * 0.045 - t * 0.45);
    // Break up the regularity with noise.
    w += (vec2(valueNoise(xz * 0.3 + t * 0.4),
               valueNoise(xz * 0.3 + 51.7 + t * 0.35)) - 0.5) * 1.2;
    return w;
}

/*
  Compute a world-space offset for a vertex.
    worldPos  - vertex world position (cameraPosition + relative)
    blockId   - mc_Entity.x
    topWeight - 0 at anchored base, 1 at free tip
    skyLight  - lightmap sky coordinate (0..1); indoor plants barely move
*/
vec3 getWavingOffset(vec3 worldPos, int blockId, float topWeight, float skyLight) {
    float strength = WIND_STRENGTH;
    float t = frameTimeCounter * WIND_SPEED;

    // Indoor foliage should be still.
    float indoor = smoothstep(0.05, 0.4, skyLight);
    strength *= mix(0.15, 1.0, indoor);

    vec2 wind = windField(worldPos.xz, t);
    vec3 offset = vec3(0.0);

    if (blockId == ID_PLANT_SMALL || blockId == ID_PLANT_TALL || blockId == ID_CROPS) {
#if !defined(WAVING_PLANTS)
        return vec3(0.0);
#endif
        float amp = 0.12 * strength * topWeight;
        offset.xz = wind * amp;
        offset.y  = -length(wind) * amp * 0.25; // slight droop as it bends
    }
    else if (blockId == ID_LEAVES) {
#if !defined(WAVING_LEAVES)
        return vec3(0.0);
#endif
        float amp = 0.06 * strength;
        offset.x = sin(worldPos.x * 0.5 + t * 1.4) * amp;
        offset.y = sin(worldPos.y * 0.5 + t * 1.7 + worldPos.x) * amp * 0.6;
        offset.z = cos(worldPos.z * 0.5 + t * 1.5) * amp;
    }
    else if (blockId == ID_VINES) {
#if !defined(WAVING_VINES)
        return vec3(0.0);
#endif
        float amp = 0.10 * strength;
        offset.xz = wind * amp * 0.5;
        offset.y  = sin(worldPos.y * 0.8 + t * 1.2) * amp * 0.4;
    }
    else if (blockId == ID_WATERPLANT) {
#if !defined(WAVING_WATER_PLANTS)
        return vec3(0.0);
#endif
        // Slower, deeper sway; anchored at the sea floor.
        float amp = 0.18 * topWeight;
        float st = t * 0.5;
        offset.x = sin(worldPos.y * 0.6 + st + worldPos.x * 0.1) * amp;
        offset.z = cos(worldPos.y * 0.6 + st + worldPos.z * 0.1) * amp;
    }
    else if (blockId == ID_LANTERN) {
        float amp = 0.03 * strength;
        offset.xz = wind * amp;
    }

    return offset;
}

// Vertical displacement for the water surface (used by gbuffers_water vertex).
float getWaterWaveHeight(vec3 worldPos) {
#ifndef WATER_WAVES
    return 0.0;
#else
    float t = frameTimeCounter * WIND_SPEED;
    vec2 p = worldPos.xz;
    float h = 0.0;
    // Sum of a few directional sine waves (cheap Gerstner-ish surface).
    h += sin(dot(p, vec2( 0.7,  0.3)) * 0.9 + t * 1.6);
    h += sin(dot(p, vec2(-0.4,  0.8)) * 1.1 + t * 1.9) * 0.7;
    h += sin(dot(p, vec2( 0.2, -0.9)) * 1.7 + t * 2.3) * 0.4;
    h += (valueNoise(p * 0.6 + t * 0.5) - 0.5) * 0.6;
    return h * 0.045 * WATER_WAVE_HEIGHT;
#endif
}

#endif // BLAZE_WAVING_GLSL
