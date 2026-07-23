/*
====================================================================================
  Blaze's Shadows  -  lib/water/water.glsl
------------------------------------------------------------------------------------
  Fragment-side water helpers: high-frequency wave normals (from the analytic height
  field's gradient), animated caustics for submerged surfaces, shoreline/crest foam,
  and rain ripple normals shared with wet opaque surfaces.
====================================================================================
*/
#ifndef BLAZE_WATER_GLSL
#define BLAZE_WATER_GLSL

#include "/lib/settings.glsl"
#include "/lib/util/noise.glsl"
#include "/lib/vertex/waving.glsl" // reuse getWaterWaveHeight for a consistent surface

// Sample the wave height field (matches the vertex displacement for continuity).
float waveHeightDetail(vec2 p, float t) {
    float h = 0.0;
    h += sin(dot(p, vec2( 0.9,  0.4)) * 1.3 + t * 1.7);
    h += sin(dot(p, vec2(-0.5,  0.9)) * 1.9 + t * 2.1) * 0.6;
    h += sin(dot(p, vec2( 0.3, -1.0)) * 2.7 + t * 2.7) * 0.35;
    h += (fbm(p * 1.5 + t * 0.6, 3, 2.0, 0.5) - 0.5) * 1.4;
    return h;
}

// Reconstruct a detailed surface normal for the water plane via finite differences.
vec3 getWaterNormal(vec3 worldPos, vec3 geoNormal, float strength) {
#ifndef WATER_WAVES
    return geoNormal;
#endif
    // Only apply full wave normals to roughly horizontal surfaces.
    float flat = saturate(geoNormal.y);
    if (flat < 0.05) return geoNormal;

    float t = frameTimeCounter * WIND_SPEED;
    vec2 p = worldPos.xz;
    float e = 0.15; // finite-difference epsilon

    float h  = waveHeightDetail(p, t);
    float hx = waveHeightDetail(p + vec2(e, 0.0), t);
    float hz = waveHeightDetail(p + vec2(0.0, e), t);

    float scale = 0.09 * strength * WATER_WAVE_HEIGHT;
    vec3 n = normalize(vec3(-(hx - h) / e * scale, 1.0, -(hz - h) / e * scale));
    // Blend toward the geometric normal for near-vertical faces.
    return normalize(mix(geoNormal, n, flat));
}

// Voronoi-ish caustics: distance to the nearest of a few animated feature points.
float getCaustics(vec3 worldPos) {
#ifndef WATER_CAUSTICS
    return 1.0;
#endif
    vec2 p = worldPos.xz * 0.6;
    float t = frameTimeCounter * WIND_SPEED * 0.8;
    vec2 i = floor(p);
    vec2 f = fract(p);
    float md = 1.0;
    for (int y = -1; y <= 1; y++)
    for (int x = -1; x <= 1; x++) {
        vec2 g = vec2(x, y);
        vec2 o = hash22(i + g);
        o = 0.5 + 0.5 * sin(t + TAU * o); // animate feature points
        float d = length(g + o - f);
        md = min(md, d);
    }
    // Sharpen the ridges into caustic lines.
    float c = pow(1.0 - md, 4.0);
    return 1.0 + c * 2.2; // >1 brightens lit patches
}

// Foam factor from wave crests and shallow water (0..1).
float getFoam(vec3 worldPos, float waterDepth) {
#ifndef WATER_FOAM
    return 0.0;
#endif
    float t = frameTimeCounter * WIND_SPEED;
    // Shoreline foam where water is shallow.
    float shore = smoothstep(1.2, 0.0, waterDepth);
    // Crest foam on the tops of waves.
    float crest = smoothstep(0.55, 0.9, fbm(worldPos.xz * 1.2 + t * 0.7, 3, 2.0, 0.5));
    float foam = max(shore * 0.9, crest * shore);
    // Add a moving band pattern near the shore.
    foam *= 0.6 + 0.4 * sin(waterDepth * 12.0 - t * 3.0);
    return saturate(foam);
}

// Rain ripple normal perturbation on flat surfaces (water + wet ground).
vec3 getRainRipples(vec3 worldPos, vec3 normal, float rain) {
#ifndef RAIN_RIPPLES
    return normal;
#endif
    if (rain < 0.01 || normal.y < 0.5) return normal;
    float t = frameTimeCounter * 4.0;
    vec2 p = worldPos.xz * 6.0;
    // Expanding concentric rings from random impact points.
    vec2 i = floor(p);
    vec2 f = fract(p) - 0.5;
    float ripple = 0.0;
    for (int k = 0; k < 2; k++) {
        vec2 rnd = hash22(i + float(k) * 17.0);
        float phase = fract(t * 0.7 + rnd.x);
        float r = length(f - (rnd - 0.5) * 0.6);
        float ring = sin((r - phase) * 30.0) * exp(-r * 6.0) * (1.0 - phase);
        ripple += ring;
    }
    ripple *= rain * 0.15;
    vec3 n = normalize(normal + vec3(ripple, 0.0, ripple));
    return n;
}

#endif // BLAZE_WATER_GLSL
