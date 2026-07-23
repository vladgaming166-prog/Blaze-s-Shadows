#version 330 compatibility
/*
====================================================================================
  Blaze's Shadows  -  deferred1.fsh   (pass 2: opaque lighting, sky, volumetrics)
------------------------------------------------------------------------------------
  The main lighting stage. For each opaque fragment it evaluates:
    * direct sun/moon light through the soft, contact-hardening, coloured shadow,
    * subsurface back-scatter for foliage,
    * sky + ground ambient modulated by AO and augmented by screen-space GI,
    * warm block light (colour-temperature tinted) + emission + held-item light,
  and for sky fragments it paints the full procedural sky, celestial bodies, night
  sky extras and volumetric clouds. Finally it adds screen-space volumetric light
  (god rays). Output is linear HDR in colortex0.
====================================================================================
*/
#include "/lib/framebuffer.glsl"
#include "/lib/settings.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/util/encoding.glsl"
#include "/lib/util/spaces.glsl"
#include "/lib/util/blackbody.glsl"
#include "/lib/atmosphere/sky.glsl"
#include "/lib/atmosphere/clouds.glsl"
#include "/lib/atmosphere/celestial.glsl"
#include "/lib/lighting/shadows.glsl"
#include "/lib/lighting/brdf.glsl"
#include "/lib/material/ids.glsl"

in vec2 uv;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 outColor;

// Lightweight single-tap shadow test for the volumetric-light march.
float shadowTestSimple(vec3 scenePos) {
    vec3 sv = (shadowModelView * vec4(scenePos, 1.0)).xyz;
    vec3 clip = (shadowProjection * vec4(sv, 1.0)).xyz;
    clip = distortShadowClip(clip) * 0.5 + 0.5;
    if (any(lessThan(clip.xy, vec2(0.0))) || any(greaterThan(clip.xy, vec2(1.0)))) return 1.0;
    float d = texture(shadowtex1, clip.xy).r;
    return step(clip.z - 0.0006, d);
}

// Screen-space god rays: march player-space along the view ray sampling the shadow map.
vec3 volumetricLight(vec3 worldDir, float maxDist, vec3 lightDir, vec3 lightColor,
                     float dither) {
#ifndef VOLUMETRIC_LIGHT
    return vec3(0.0);
#else
    float range = min(maxDist, SHADOW_DISTANCE);
    int steps = VL_SAMPLES;
    float stepLen = range / float(steps);
    float phase = phaseHG(dot(worldDir, lightDir), 0.6) + 0.25;

    float accum = 0.0;
    float t = stepLen * dither;
    for (int i = 0; i < steps; i++) {
        vec3 scenePos = worldDir * t;
        accum += shadowTestSimple(scenePos);
        t += stepLen;
    }
    accum /= float(steps);
    return lightColor * accum * phase * VL_INTENSITY * 0.6;
#endif
}

// Screen-space contact shadows: catch thin/small occluders the shadow map misses.
float contactShadow(vec3 viewPos, vec3 lightDirView, float dither) {
#ifndef CONTACT_SHADOWS
    return 1.0;
#else
    const int steps = 8;
    float stepSize = 0.12;
    vec3 rayStep = lightDirView * stepSize;
    vec3 rayPos = viewPos + rayStep * (0.5 + dither);
    for (int i = 0; i < steps; i++) {
        rayPos += rayStep;
        vec3 s = viewToScreen(rayPos, gbufferProjection);
        if (any(lessThan(s.xy, vec2(0.0))) || any(greaterThan(s.xy, vec2(1.0)))) break;
        float sd = texture(depthtex1, s.xy).r;
        vec3 sp = screenToView(vec3(s.xy, sd), gbufferProjectionInverse);
        float diff = sp.z - rayPos.z;
        if (diff > 0.02 && diff < 0.6) return 0.15; // occluded
    }
    return 1.0;
#endif
}

void main() {
    float depth = texture(depthtex0, uv).r;
    vec3 viewPos = screenToView(vec3(uv, depth), gbufferProjectionInverse);
    vec3 scenePos = mat3(gbufferModelViewInverse) * viewPos
                  + gbufferModelViewInverse[3].xyz;
    vec3 worldDir = normalize(mat3(gbufferModelViewInverse) * viewPos);

    // Sun/moon directions + day phase.
    vec3 sunDir  = normalize(mat3(gbufferModelViewInverse) * sunPosition);
    vec3 moonDir = normalize(mat3(gbufferModelViewInverse) * moonPosition);
    DayPhase phase = getDayPhase(sunDir.y);
    vec3 lightDir = phase.day > 0.5 ? sunDir : moonDir;
    vec3 lightColor = getShadowLightColor(phase, rainStrength);

    float dither = interleavedGradient(gl_FragCoord.xy, float(frameCounter));

    // ---------------------------------------------------------------- SKY ----
    if (depth >= 1.0) {
        vec3 sky = getSkyColor(worldDir, sunDir, moonDir, phase, rainStrength);
        sky += getSunMoonDiscs(worldDir, sunDir, moonDir, phase, rainStrength);
        sky += renderNightSkyExtras(worldDir, sunDir, phase, rainStrength, wetness);

        // Volumetric clouds over the sky.
        vec4 cloud = renderClouds(worldDir, sunDir, phase, rainStrength, dither);
        sky = sky * cloud.a + cloud.rgb;

        outColor = vec4(max0(sky), 1.0);
        return;
    }

    // ------------------------------------------------------------ GEOMETRY ---
    vec4 geo = texture(colortex1, uv);
    float matID = geo.a;

    vec3 albedoSrgb = texture(colortex0, uv).rgb;

    // Unlit passthrough (selection boxes, etc.).
    if (isMat(matID, MATID_UNLIT)) { outColor = vec4(albedoSrgb, 1.0); return; }

    vec3 albedo = srgbToLinear(albedoSrgb);
    vec3 N = decodeNormal(geo.rg);
    vec2 lm = decodeLightmap(geo.b);
    vec4 material = texture(colortex2, uv);
    vec4 aogi = texture(colortex3, uv);

    float smoothness = material.r;
    float roughness = max(sqr(1.0 - smoothness), 0.02);
    float f0scalar = material.g;
    float emission = material.b;
    float sss = material.a;
    float ao = aogi.a;
    vec3  giBounce = aogi.rgb;

    bool metal = f0scalar > 0.9;
    vec3 f0 = metal ? albedo : vec3(f0scalar);
    float metalness = metal ? 1.0 : 0.0;

    // ---- Wet surfaces (rain darkens and glosses up sky-exposed tops) --------
#ifdef WET_SURFACES
    if (wetness > 0.0 && !metal && !isMat(matID, MATID_WATER)) {
        float wet = wetness * saturate(lm.y * 1.6 - 0.4) * saturate(N.y * 0.5 + 0.5);
        albedo *= mix(1.0, 0.72, wet);
        smoothness = mix(smoothness, 0.9, wet);
        roughness = max(sqr(1.0 - smoothness), 0.02);
        f0 = mix(f0, vec3(0.02), wet);
    }
#endif

    vec3 V = normalize(-viewPos);
    V = normalize(mat3(gbufferModelViewInverse) * V); // to world space

    float NdotL = dot(N, lightDir);

    // ---- Shadows ------------------------------------------------------------
    vec3 shadow = vec3(saturate(NdotL));
    if (!isMat(matID, MATID_HAND)) {
        shadow = getShadows(scenePos, N, NdotL, dither) * saturate(NdotL);
    } else {
        shadow = vec3(saturate(NdotL) * 0.5 + 0.5); // hand: soft, no world shadow
    }

    // ---- Direct light -------------------------------------------------------
    vec3 direct = evalBRDF(N, V, lightDir, albedo, f0, roughness, metalness);
    direct *= lightColor * shadow;

    // Contact shadows tighten the transition where geometry meets the ground.
    if (!isMat(matID, MATID_HAND) && NdotL > 0.0) {
        direct *= contactShadow(viewPos, normalize(shadowLightPosition), dither);
    }

    // Subsurface back-scatter for foliage (light coming through leaves/grass).
    if (sss > 0.01) {
        float back = saturate(dot(-lightDir, V)) * 0.5 + 0.5;
        float wrap = saturate((NdotL + 0.3) / 1.3);
        vec3 sssLight = lightColor * getShadows(scenePos, N, 1.0, dither);
        direct += albedo * sssLight * back * wrap * sss * 0.6;
    }

    // ---- Ambient (sky + ground) --------------------------------------------
    vec3 skyAmb = getSkyAmbientColor(phase, rainStrength);
    vec3 groundAmb = getGroundAmbientColor(phase, rainStrength);
    float skyLight = pow(saturate(lm.y), 2.2);
    float upFactor = saturate(N.y * 0.5 + 0.5);
    vec3 ambient = mix(groundAmb, skyAmb, upFactor) * skyLight;
    ambient *= ao;
    vec3 ambientDiffuse = albedo * ambient * (1.0 - metalness);

    // Screen-space GI bounce.
#ifdef GI
    ambientDiffuse += albedo * giBounce * GI_STRENGTH * ao;
#endif

    // Environment specular (image-based approximation using the sky ambient).
    float NdotV = max(dot(N, V), 1e-3);
    vec3 envSpec = envBRDFApprox(f0, roughness, NdotV) * skyAmb * skyLight * ao;

    // ---- Block light + emission --------------------------------------------
    vec3 blockLightColor = blackbody(float(BLOCKLIGHT_TEMPERATURE));
    float blockBright = pow(saturate(lm.x), 3.0) * BLOCKLIGHT_INTENSITY;
    vec3 blockLight = blockLightColor * blockBright;
#ifdef COLORED_LIGHTING
    blockLight *= vec3(1.0, 0.85, 0.7); // warm bias
#endif
    vec3 blockDiffuse = albedo * blockLight;

    vec3 emissive = albedo * emission * 4.0;

    // ---- Held-item light ----------------------------------------------------
#ifdef HANDHELD_LIGHT
    float held = float(max(heldBlockLightValue, heldBlockLightValue2)) / 15.0;
    if (held > 0.0) {
        float d = length(viewPos);
        float atten = held / (1.0 + d * d * 0.25);
        blockDiffuse += albedo * blackbody(float(BLOCKLIGHT_TEMPERATURE))
                      * atten * HANDHELD_LIGHT_INTENSITY;
    }
#endif

    // ---- Minimum brightness / night vision ---------------------------------
    vec3 minBright = albedo * (nightVision * 0.4 + screenBrightness * 0.02 + 0.0015);

    vec3 color = direct + ambientDiffuse + envSpec + blockDiffuse + emissive + minBright;

    // ---- Volumetric light (god rays) : additive in-scatter, not surface light
    color += volumetricLight(worldDir, length(scenePos), lightDir, lightColor, dither);

    outColor = vec4(max0(color), 1.0);
}
