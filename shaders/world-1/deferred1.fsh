#version 330 compatibility
/*
====================================================================================
  Blaze's Shadows  -  world-1/deferred1.fsh   (NETHER lighting)
------------------------------------------------------------------------------------
  The Nether has no sun, so lighting is dominated by warm block light, emission and
  a hot ambient tinted by the biome fog colour. There is no shadow map term here.
====================================================================================
*/
#include "/lib/framebuffer.glsl"
#include "/lib/settings.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/util/encoding.glsl"
#include "/lib/util/spaces.glsl"
#include "/lib/util/blackbody.glsl"
#include "/lib/material/ids.glsl"

in vec2 uv;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 outColor;

void main() {
    float depth = texture(depthtex0, uv).r;
    vec3 fog = srgbToLinear(fogColor) * 1.2;

    // The "sky" of the Nether is just fog.
    if (depth >= 1.0) { outColor = vec4(fog, 1.0); return; }

    vec4 geo = texture(colortex1, uv);
    float matID = geo.a;
    vec3 albedoSrgb = texture(colortex0, uv).rgb;
    if (isMat(matID, MATID_UNLIT)) { outColor = vec4(albedoSrgb, 1.0); return; }

    vec3 albedo = srgbToLinear(albedoSrgb);
    vec3 N = decodeNormal(geo.rg);
    vec2 lm = decodeLightmap(geo.b);
    vec4 material = texture(colortex2, uv);
    vec4 aogi = texture(colortex3, uv);
    float ao = aogi.a;

    // Hot ambient: warm, driven by the fog colour, slightly stronger from below
    // (lava glow rising up).
    vec3 ambientCol = mix(vec3(0.35, 0.14, 0.08), fog, 0.5) * AMBIENT_INTENSITY;
    float downFactor = saturate(-N.y * 0.5 + 0.6); // faces looking down catch lava glow
    vec3 ambient = albedo * ambientCol * (0.5 + downFactor) * ao;

    // Warm block light.
    vec3 blockLightColor = blackbody(float(BLOCKLIGHT_TEMPERATURE)) * vec3(1.0, 0.8, 0.6);
    float blockBright = pow(saturate(lm.x), 2.6) * BLOCKLIGHT_INTENSITY;
    vec3 blockLight = albedo * blockLightColor * blockBright;

    vec3 emissive = albedo * material.b * 4.0;
    vec3 minBright = albedo * (nightVision * 0.4 + 0.01);

    outColor = vec4(max(ambient + blockLight + emissive + minBright, vec3(0.0)), 1.0);
}
