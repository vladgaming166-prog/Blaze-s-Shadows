/*
====================================================================================
  Blaze's Shadows  -  lib/material/labpbr.glsl
------------------------------------------------------------------------------------
  Decoders for the labPBR 1.3 resource-pack standard, with graceful fallbacks when
  no PBR textures are present (vanilla / non-PBR packs). This lets the same gbuffer
  code path serve both plain Minecraft and fancy PBR resource packs.

  labPBR channel layout:
    specular.r : perceptual smoothness           (0..1)
    specular.g : F0 / metalness  (0..229 = F0 %, 230..255 = predefined metals)
    specular.b : porosity (0..64) OR subsurface  (65..255)
    specular.a : emission (0..254 -> 0..1, 255 = no emission)
    normal.rg  : tangent-space normal XY
    normal.b   : ambient occlusion
    normal.a   : height map (for parallax)
====================================================================================
*/
#ifndef BLAZE_LABPBR_GLSL
#define BLAZE_LABPBR_GLSL

#include "/lib/settings.glsl"
#include "/lib/util/math.glsl"

struct Material {
    float smoothness; // perceptual (1 = mirror)
    float roughness;  // (1 - smoothness)^2 style, precomputed
    float f0;         // dielectric reflectance
    float metalness;  // 0..1
    float emission;   // 0..1
    float porosity;   // 0..1
    float sss;        // subsurface amount 0..1
    float ao;         // baked ambient occlusion
    vec3  metalTint;  // hardcoded metal albedo for the labPBR metal ids
};

Material defaultMaterial() {
    Material m;
    m.smoothness = 0.0;
    m.roughness  = 1.0;
    m.f0         = 0.04;
    m.metalness  = 0.0;
    m.emission   = 0.0;
    m.porosity   = 0.0;
    m.sss        = 0.0;
    m.ao         = 1.0;
    m.metalTint  = vec3(1.0);
    return m;
}

// Predefined labPBR hardware metals (indices 230..237). Values are their F0 colour.
vec3 labpbrMetalTint(int id) {
    if (id == 230) return vec3(2.9114, 2.9497, 2.5845) / 3.0; // iron
    if (id == 231) return vec3(2.0733, 1.5549, 1.0761) / 2.0; // gold
    if (id == 232) return vec3(1.4419, 1.5750, 1.5687) / 1.6; // aluminium
    if (id == 233) return vec3(3.1071, 3.1085, 3.1112) / 3.1; // chrome
    if (id == 234) return vec3(0.2712, 0.6763, 1.3160);       // copper
    if (id == 235) return vec3(1.9535, 1.9110, 1.4608) / 2.0; // lead
    if (id == 236) return vec3(2.8460, 2.8493, 2.7846) / 2.9; // platinum
    if (id == 237) return vec3(4.2470, 4.3684, 4.4741) / 4.4; // silver
    return vec3(1.0);
}

// Decode a labPBR specular texel into a Material (albedo is passed for metals).
Material decodeSpecular(vec4 specTex, vec3 albedo) {
    Material m = defaultMaterial();

#ifdef SPECULAR_MAPS
    m.smoothness = specTex.r;
    m.roughness  = sqr(1.0 - m.smoothness);

    float g = specTex.g;
    if (g * 255.0 < 229.5) {
        m.f0 = g;           // dielectric reflectance stored directly
        m.metalness = saturate((g - 0.02) * 4.0); // soft ramp for "shiny" dielectrics
        m.metalness = g > 0.9 ? 1.0 : m.metalness;
    } else {
        int id = int(g * 255.0 + 0.5);
        m.metalness = 1.0;
        m.f0 = 1.0;
        m.metalTint = labpbrMetalTint(id);
    }

    float b = specTex.b;
    if (b * 255.0 < 64.5) {
        m.porosity = b / 0.25;      // 0..64 -> 0..1
    } else {
        m.sss = (b - 0.25) / 0.75;  // 65..255 -> 0..1
    }

    // Emission: 255 means "no emission", everything else is 0..254 -> 0..1.
    m.emission = specTex.a < (254.5 / 255.0) ? specTex.a : 0.0;
#endif

    return m;
}

// Decode a labPBR normal texel into a tangent-space normal (+ AO, + height).
vec3 decodeNormalMap(vec4 normTex, out float ao, out float height) {
    ao = 1.0;
    height = 1.0;
#ifdef NORMAL_MAPS
    ao = normTex.b;
    height = normTex.a;
    vec2 xy = normTex.rg * 2.0 - 1.0;
    float z = sqrt(saturate(1.0 - dot(xy, xy)));
    return vec3(xy, z);
#else
    return vec3(0.0, 0.0, 1.0);
#endif
}

#endif // BLAZE_LABPBR_GLSL
