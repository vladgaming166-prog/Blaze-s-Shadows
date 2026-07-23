/*
====================================================================================
  Blaze's Shadows  -  lib/atmosphere/celestial.glsl
------------------------------------------------------------------------------------
  Night-sky decorations: procedural star field, Milky Way band, shooting stars,
  aurora borealis and a post-rain rainbow. All are additive contributions layered
  on top of the base sky, gated by the appropriate day phase so they fade in/out.
====================================================================================
*/
#ifndef BLAZE_CELESTIAL_GLSL
#define BLAZE_CELESTIAL_GLSL

#include "/lib/atmosphere/common.glsl"
#include "/lib/util/noise.glsl"

/* ---------------------------------------------------------------- STARS ----- */
vec3 renderStars(vec3 worldDir, DayPhase p) {
#ifndef STARS
    return vec3(0.0);
#else
    // Project the direction onto a stable grid so stars don't swim with the camera.
    vec3 dir = worldDir;
    vec2 uv = dir.xz / (abs(dir.y) + 0.35);
    uv *= 90.0;

    vec2 cell = floor(uv);
    vec2 f = fract(uv);
    vec3 star = vec3(0.0);

    // Look at the 3x3 neighbourhood so stars near cell edges still render.
    for (int y = -1; y <= 1; y++)
    for (int x = -1; x <= 1; x++) {
        vec2 c = cell + vec2(x, y);
        vec2 rnd = hash22(c);
        // Only a fraction of cells contain a star.
        if (rnd.x > 0.965) {
            vec2 pos = vec2(x, y) + hash22(c + 7.3) - f;
            float d = dot(pos, pos);
            float bright = smoothstep(0.02, 0.0, d);
            // Twinkle over time.
            float tw = 0.6 + 0.4 * sin(frameTimeCounter * (1.5 + rnd.y * 3.0) + rnd.x * 40.0);
            // Slight colour variety (blue/white/warm giants).
            vec3 tint = mix(vec3(0.7, 0.8, 1.0), vec3(1.0, 0.85, 0.7), rnd.y);
            star += bright * tw * tint;
        }
    }

    star *= saturate(worldDir.y + 0.1); // hide below horizon
    return star * p.night * STAR_BRIGHTNESS * 1.4;
#endif
}

/* ------------------------------------------------------------ MILKY WAY ----- */
vec3 renderMilkyWay(vec3 worldDir, DayPhase p) {
#if !defined(MILKY_WAY) || !defined(STARS)
    return vec3(0.0);
#else
    // A tilted band of denser, dustier noise.
    vec3 dir = normalize(worldDir + vec3(0.0, 0.05, 0.0));
    float band = dir.x * 0.6 + dir.y * 0.5 + dir.z * 0.62;
    float mask = exp(-band * band * 14.0);

    vec2 uv = dir.xz / (abs(dir.y) + 0.4) * 4.0;
    float dust = fbm(uv * 2.0 + 13.0, 5, 2.1, 0.55);
    float bright = fbm(uv * 6.0, 4, 2.0, 0.5);

    vec3 col = mix(vec3(0.35, 0.30, 0.55), vec3(0.55, 0.60, 0.85), bright);
    col *= mask * saturate(dust - 0.25) * 1.8;
    col *= saturate(worldDir.y + 0.05);
    return col * p.night * STAR_BRIGHTNESS;
#endif
}

/* -------------------------------------------------------- SHOOTING STARS ---- */
vec3 renderShootingStars(vec3 worldDir, DayPhase p) {
#ifndef SHOOTING_STARS
    return vec3(0.0);
#else
    // One meteor every ~12 seconds, deterministic per interval.
    float t = frameTimeCounter / 12.0;
    float seed = floor(t);
    float local = fract(t);
    vec2 r = hash22(vec2(seed, 3.1));
    // Random start point and travel direction across the sky.
    vec2 sky = worldDir.xz / (abs(worldDir.y) + 0.35);
    vec2 start = (r - 0.5) * 4.0;
    vec2 vel = normalize(hash22(vec2(seed, 7.7)) - 0.5);
    vec2 head = start + vel * local * 3.0;
    vec2 d = sky - head;
    // Distance to the trailing line segment.
    float along = clamp(dot(-d, vel), 0.0, 0.5);
    float dist = length(d + vel * along);
    float streak = smoothstep(0.03, 0.0, dist) * smoothstep(0.5, 0.0, along);
    float life = smoothstep(0.0, 0.1, local) * smoothstep(1.0, 0.7, local);
    return vec3(1.0, 0.95, 0.85) * streak * life * saturate(worldDir.y) * p.night * 2.0;
#endif
}

/* ------------------------------------------------------------- AURORA ------- */
vec3 renderAurora(vec3 worldDir, DayPhase p, float rain) {
#ifndef AURORA
    return vec3(0.0);
#else
    // Aurora only on clear, cold nights.
    float gate = p.night * (1.0 - rain);
    if (gate < 0.01 || worldDir.y < 0.02) return vec3(0.0);

    vec3 acc = vec3(0.0);
    // March a few horizontal sheets high in the sky.
    for (int i = 0; i < 4; i++) {
        float h = 0.25 + float(i) * 0.12;
        float t = (h - 0.0) / max(worldDir.y, 0.05);
        vec2 pos = worldDir.xz * t;
        float n = fbm(pos * 0.6 + vec2(frameTimeCounter * 0.05, 0.0), 4, 2.0, 0.5);
        float curtain = smoothstep(0.45, 0.9, n);
        // Vertical striations.
        curtain *= 0.5 + 0.5 * sin(pos.x * 3.0 + n * 6.0 + frameTimeCounter * 0.5);
        vec3 col = mix(vec3(0.1, 0.9, 0.4), vec3(0.3, 0.4, 1.0), float(i) / 3.0);
        acc += col * curtain * (1.0 - float(i) / 5.0);
    }
    acc *= smoothstep(0.02, 0.3, worldDir.y) * 0.15;
    return acc * gate;
#endif
}

/* ------------------------------------------------------------ RAINBOW ------- */
vec3 renderRainbow(vec3 worldDir, vec3 sunDir, DayPhase p, float rain, float wet) {
#ifndef RAINBOW
    return vec3(0.0);
#else
    // Appears as rain clears while the sun is fairly low. Centred opposite the sun.
    float gate = (1.0 - rain) * saturate(wet * 2.0) * p.day
               * smoothstep(0.02, 0.25, sunDir.y) * smoothstep(0.6, 0.25, sunDir.y);
    if (gate < 0.01) return vec3(0.0);

    float ang = degrees(acos(clamp(dot(worldDir, -sunDir), -1.0, 1.0)));
    // Primary bow around 42 degrees.
    float band = smoothstep(40.0, 42.0, ang) * smoothstep(44.0, 42.0, ang);
    // Map the 40-44 degree window to a hue sweep.
    float hue = saturate((ang - 40.0) / 4.0);
    vec3 col = clamp(vec3(
        abs(hue * 6.0 - 3.0) - 1.0,
        2.0 - abs(hue * 6.0 - 2.0),
        2.0 - abs(hue * 6.0 - 4.0)), 0.0, 1.0);
    return col * band * gate * 0.25 * saturate(worldDir.y + 0.1);
#endif
}

// Convenience: everything additive that lives "in the sky dome".
vec3 renderNightSkyExtras(vec3 worldDir, vec3 sunDir, DayPhase p, float rain, float wet) {
    vec3 c = vec3(0.0);
    c += renderStars(worldDir, p);
    c += renderMilkyWay(worldDir, p);
    c += renderShootingStars(worldDir, p);
    c += renderAurora(worldDir, p, rain);
    c += renderRainbow(worldDir, sunDir, p, rain, wet);
    return c;
}

#endif // BLAZE_CELESTIAL_GLSL
