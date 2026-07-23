#version 330 compatibility
/*
====================================================================================
  Blaze's Shadows  -  gbuffers_water.fsh
------------------------------------------------------------------------------------
  Forward-shaded translucents. Water gets the full treatment: animated wave normals,
  Fresnel sky reflection, sun/moon specular, wavelength-dependent absorption of the
  refracted background, shoreline/crest foam and rain ripples. Other translucents
  (stained glass, ice, slime) get a tinted, lightly-reflective look.

  This program runs with blending disabled (see shaders.properties); we composite the
  background ourselves by sampling colortex0, which lets us do per-channel absorption
  and screen-space refraction that alpha blending cannot express.
====================================================================================
*/
#include "/lib/framebuffer.glsl"
#include "/lib/settings.glsl"
#include "/lib/util/encoding.glsl"
#include "/lib/util/spaces.glsl"
#include "/lib/atmosphere/sky.glsl"
#include "/lib/water/water.glsl"
#include "/lib/lighting/brdf.glsl"
#include "/lib/material/ids.glsl"

uniform sampler2D gtexture;
uniform sampler2D colortex0; // opaque-lit scene (for refraction / glass background)
uniform sampler2D depthtex1; // opaque-only depth
uniform float alphaTestRef;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform vec3 cameraPosition;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform float wetness;
uniform float viewWidth;
uniform float viewHeight;
uniform float near;
uniform float far;
uniform int isEyeInWater;

in vec4 glcolor;
in vec2 texcoord;
in vec2 lmcoord;
in vec3 worldNormal;
in vec3 viewPos;
in vec3 worldPos;
flat in int blockId;

#define ID_WATER 10008

/* DRAWBUFFERS:012 */
layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outGeometry;
layout(location = 2) out vec4 outMaterial;

void main() {
    vec2 screenUV = gl_FragCoord.xy / vec2(viewWidth, viewHeight);

    // World-space sun/moon directions and the day phase.
    vec3 sunDir  = normalize(mat3(gbufferModelViewInverse) * sunPosition);
    vec3 moonDir = normalize(mat3(gbufferModelViewInverse) * moonPosition);
    DayPhase phase = getDayPhase(sunDir.y);
    vec3 shadowLightDir = phase.day > 0.5 ? sunDir : moonDir;

    vec3 V = normalize(cameraPosition - worldPos); // surface -> eye (world)

    if (blockId == ID_WATER) {
        // ---- Water --------------------------------------------------------
        vec3 N = getWaterNormal(worldPos, normalize(worldNormal), 1.0);
        N = getRainRipples(worldPos, N, rainStrength * (1.0 - float(isEyeInWater)));

        float NdotV = max(dot(N, V), 0.0);
        float fresnel = fresnelSchlick(NdotV, 0.02);

        // Depth of the water column (surface -> opaque behind).
        float od = texture(depthtex1, screenUV).r;
        vec3 opaqueView = screenToView(vec3(screenUV, od), gbufferProjectionInverse);
        float waterColumn = max(length(opaqueView) - length(viewPos), 0.0);

        // Screen-space refraction: offset by the surface normal, guarded so we
        // never pull in geometry that is actually in front of the water.
        vec2 refr = N.xz * 0.06 / (1.0 + length(viewPos) * 0.05);
        vec2 refrUV = clamp(screenUV + refr, vec2(1e-3), vec2(1.0 - 1e-3));
        if (texture(depthtex1, refrUV).r < gl_FragCoord.z) refrUV = screenUV;
        vec3 background = texture(colortex0, refrUV).rgb;

        // Wavelength-dependent absorption through the water column.
        vec3 absorb = vec3(WATER_ABSORPTION_R, WATER_ABSORPTION_G, WATER_ABSORPTION_B);
        vec3 trans = exp(-absorb * waterColumn * (0.4 * WATER_FOG_DENSITY));
        vec3 scatterCol = getSkyAmbientColor(phase, rainStrength) * vec3(0.08, 0.32, 0.42);
        vec3 refracted = background * trans + scatterCol * (1.0 - trans);

        // Caustics brighten shallow refracted areas.
#ifdef WATER_CAUSTICS
        refracted *= mix(1.0, getCaustics(worldPos - V * waterColumn), saturate(1.0 - waterColumn * 0.1));
#endif

        // Sky reflection + sun/moon specular.
        vec3 R = reflect(-V, N);
        R.y = abs(R.y); // avoid sampling below the horizon for the sky
        vec3 reflection = getSkyColor(R, sunDir, moonDir, phase, rainStrength);
        reflection += getSunMoonDiscs(R, sunDir, moonDir, phase, rainStrength);

        vec3 lightCol = getShadowLightColor(phase, rainStrength);
        vec3 spec = evalBRDF(N, V, shadowLightDir, vec3(0.0), vec3(0.02), 0.03, 0.0)
                    * lightCol * max(dot(N, shadowLightDir), 0.0) * 8.0;

        vec3 color = mix(refracted, reflection, fresnel) + spec;

        // Foam.
#ifdef WATER_FOAM
        float foam = getFoam(worldPos, waterColumn);
        color = mix(color, vec3(0.9, 0.95, 1.0), foam * 0.6);
#endif

        outColor    = vec4(color, 1.0);
        outGeometry = vec4(encodeNormal(N), encodeLightmap(lmcoord), MATID_WATER);
        outMaterial = vec4(0.96, 0.02, 0.0, 0.0); // very smooth dielectric
    } else {
        // ---- Other translucents (glass, ice, slime) ------------------------
        vec4 tex = texture(gtexture, texcoord) * glcolor;
        if (tex.a < alphaTestRef) discard;

        vec3 N = normalize(worldNormal);
        float NdotV = max(dot(N, V), 0.0);
        float fresnel = fresnelSchlick(NdotV, 0.04);

        vec3 background = texture(colortex0, screenUV).rgb;
        vec3 R = reflect(-V, N); R.y = abs(R.y);
        vec3 reflection = getSkyColor(R, sunDir, moonDir, phase, rainStrength);

        // Tint the background by the glass colour, then add a faint reflection.
        vec3 color = mix(background, background * tex.rgb, tex.a);
        color = mix(color, reflection, fresnel * 0.25);

        outColor    = vec4(color, 1.0);
        outGeometry = vec4(encodeNormal(N), encodeLightmap(lmcoord), MATID_TRANSLUC);
        outMaterial = vec4(0.6, 0.04, 0.0, 0.0);
    }
}
