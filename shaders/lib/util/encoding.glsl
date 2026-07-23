/*
====================================================================================
  Blaze's Shadows  -  lib/util/encoding.glsl
------------------------------------------------------------------------------------
  Packing / unpacking helpers for the G-buffer. We only have a handful of colour
  attachments, so several quantities are squeezed into single channels.

  Octahedral normal encoding maps a unit vector to two [0,1] numbers with very low
  error - far better than storing xy and reconstructing z (which loses the sign).
====================================================================================
*/
#ifndef BLAZE_ENCODING_GLSL
#define BLAZE_ENCODING_GLSL

#include "/lib/util/math.glsl"

/* ---------- Octahedral normal encoding ---------- */
vec2 octWrap(vec2 v) {
    return (1.0 - abs(v.yx)) * vec2(v.x >= 0.0 ? 1.0 : -1.0,
                                    v.y >= 0.0 ? 1.0 : -1.0);
}

vec2 encodeNormal(vec3 n) {
    n /= (abs(n.x) + abs(n.y) + abs(n.z));
    n.xy = n.z >= 0.0 ? n.xy : octWrap(n.xy);
    return n.xy * 0.5 + 0.5;
}

vec3 decodeNormal(vec2 f) {
    f = f * 2.0 - 1.0;
    vec3 n = vec3(f.x, f.y, 1.0 - abs(f.x) - abs(f.y));
    float t = saturate(-n.z);
    n.xy += vec2(n.x >= 0.0 ? -t : t, n.y >= 0.0 ? -t : t);
    return normalize(n);
}

/* ---------- Two 8-bit values in one float (for lightmap) ---------- */
// Pack two [0,1] values into a single 16-bit-friendly float.
float packUnorm2x8(vec2 v) {
    v = saturate(v) * 255.0 + 0.5;
    v = floor(v);
    return v.x + v.y * 256.0;
}

vec2 unpackUnorm2x8(float f) {
    float y = floor(f / 256.0);
    float x = f - y * 256.0;
    return vec2(x, y) / 255.0;
}

// Convenience: lightmap coords live in [0,1] and get packed together.
float encodeLightmap(vec2 lm) { return packUnorm2x8(saturate(lm)) / 65535.0; }
vec2  decodeLightmap(float f)  { return unpackUnorm2x8(f * 65535.0); }

/* ---------- sRGB <-> linear ---------- */
// Textures come in as sRGB; lighting must be done in linear space.
vec3 srgbToLinear(vec3 c) {
    return mix(c / 12.92,
               pow((c + 0.055) / 1.055, vec3(2.4)),
               step(0.04045, c));
}
vec3 linearToSrgb(vec3 c) {
    return mix(c * 12.92,
               1.055 * pow(c, vec3(1.0 / 2.4)) - 0.055,
               step(0.0031308, c));
}

#endif // BLAZE_ENCODING_GLSL
