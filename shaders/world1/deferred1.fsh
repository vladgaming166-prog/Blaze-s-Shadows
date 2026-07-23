#version 330 compatibility
/*
====================================================================================
  Blaze's Shadows  -  world1/deferred1.fsh   (THE END : lighting + sky)
------------------------------------------------------------------------------------
  A bespoke purple void sky (nebula + star dust) and a soft, directionless amethyst
  ambient with a gentle top-down key light. No sun shadows in the End.
====================================================================================
*/
#include "/lib/framebuffer.glsl"
#include "/lib/settings.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/util/encoding.glsl"
#include "/lib/util/spaces.glsl"
#include "/lib/util/noise.glsl"
#include "/lib/lighting/brdf.glsl"
#include "/lib/material/ids.glsl"

in vec2 uv;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 outColor;

// The signature End void sky.
vec3 endSky(vec3 dir) {
    float up = saturate(dir.y * 0.5 + 0.5);
    vec3 base = mix(vec3(0.015, 0.008, 0.035), vec3(0.05, 0.02, 0.11), up);

    // Nebula: layered fbm projected onto the sky dome.
    vec2 np = dir.xz / (abs(dir.y) + 0.35);
    float neb = fbm(np * 2.5 + frameTimeCounter * 0.01, 5, 2.1, 0.55);
    base += vec3(0.20, 0.06, 0.34) * smoothstep(0.45, 0.95, neb) * 0.7;
    base += vec3(0.05, 0.02, 0.12) * smoothstep(0.2, 0.7, neb);

    // Sparse cold star dust.
    vec2 sp = np * 60.0;
    vec2 cell = floor(sp);
    vec2 f = fract(sp);
    vec2 rnd = hash22(cell);
    if (rnd.x > 0.985) {
        float d = length(f - hash22(cell + 3.7));
        base += vec3(0.7, 0.6, 0.9) * smoothstep(0.08, 0.0, d);
    }
    return base;
}

void main() {
    float depth = texture(depthtex0, uv).r;
    vec3 viewPos = screenToView(vec3(uv, depth), gbufferProjectionInverse);
    vec3 worldDir = normalize(mat3(gbufferModelViewInverse) * viewPos);

    if (depth >= 1.0) { outColor = vec4(endSky(worldDir), 1.0); return; }

    vec4 geo = texture(colortex1, uv);
    float matID = geo.a;
    vec3 albedoSrgb = texture(colortex0, uv).rgb;
    if (isMat(matID, MATID_UNLIT)) { outColor = vec4(albedoSrgb, 1.0); return; }

    vec3 albedo = srgbToLinear(albedoSrgb);
    vec3 N = decodeNormal(geo.rg);
    vec2 lm = decodeLightmap(geo.b);
    vec4 material = texture(colortex2, uv);
    float ao = texture(colortex3, uv).a;

    // Amethyst ambient with a faint top-down key light.
    vec3 ambientCol = vec3(0.28, 0.18, 0.42) * AMBIENT_INTENSITY;
    vec3 keyDir = normalize(vec3(0.2, 1.0, 0.15));
    float key = saturate(dot(N, keyDir)) * 0.6 + 0.4;
    vec3 ambient = albedo * ambientCol * key * ao;

    vec3 blockLight = albedo * vec3(1.0, 0.75, 0.55) * pow(saturate(lm.x), 2.8) * BLOCKLIGHT_INTENSITY;
    vec3 emissive = albedo * material.b * 4.0;
    vec3 minBright = albedo * (nightVision * 0.4 + 0.015);

    outColor = vec4(max(ambient + blockLight + emissive + minBright, vec3(0.0)), 1.0);
}
