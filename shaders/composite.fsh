#version 330 compatibility
/*
====================================================================================
  Blaze's Shadows  -  composite.fsh   (pass 3: screen-space reflections)
------------------------------------------------------------------------------------
  Runs after translucents, so colortex0 holds the full lit scene (incl. water and
  glass). For sufficiently smooth surfaces we march a reflection ray through the
  hierarchical-free depth buffer, refine the hit with a short binary search, and
  blend the reflected colour by Fresnel * smoothness. Rays that leave the screen
  fall back to the procedural sky. Roughness jitters the ray for glossy blur.
====================================================================================
*/
#include "/lib/framebuffer.glsl"
#include "/lib/settings.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/util/encoding.glsl"
#include "/lib/util/spaces.glsl"
#include "/lib/util/noise.glsl"
#include "/lib/atmosphere/sky.glsl"
#include "/lib/lighting/brdf.glsl"
#include "/lib/material/ids.glsl"

in vec2 uv;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 outColor;

// Trace a reflection ray in view space. Returns true + hit uv on success.
bool traceSSR(vec3 viewPos, vec3 reflectDir, float dither, out vec2 hitUV) {
    float rayLen = 1.0;
    vec3 rayEnd = viewPos + reflectDir * rayLen;

    vec3 startScreen = viewToScreen(viewPos, gbufferProjection);
    vec3 endScreen   = viewToScreen(rayEnd, gbufferProjection);
    vec3 delta = endScreen - startScreen;

    int steps = SSR_STEPS;
    vec3 rayStep = delta / float(steps);
    vec3 pos = startScreen + rayStep * (1.0 + dither);

    for (int i = 0; i < steps; i++) {
        pos += rayStep;
        if (any(lessThan(pos.xy, vec2(0.0))) || any(greaterThan(pos.xy, vec2(1.0))) || pos.z > 1.0)
            return false;

        float sceneDepth = texture(depthtex0, pos.xy).r;
        float diff = pos.z - sceneDepth;
        if (diff > 0.0 && diff < 0.0009 * (1.0 + float(i))) {
            // Binary refinement for a crisp hit.
            vec3 lo = pos - rayStep;
            vec3 hi = pos;
            for (int j = 0; j < SSR_REFINE; j++) {
                vec3 mid = (lo + hi) * 0.5;
                float sd = texture(depthtex0, mid.xy).r;
                if (mid.z - sd > 0.0) hi = mid; else lo = mid;
            }
            hitUV = hi.xy;
            return true;
        }
    }
    return false;
}

void main() {
    vec3 color = texture(colortex0, uv).rgb;
    float depth = texture(depthtex0, uv).r;

    if (depth >= 1.0) { outColor = vec4(color, 1.0); return; }

    vec4 material = texture(colortex2, uv);
    vec4 geo = texture(colortex1, uv);
    float smoothness = material.r;
    float matID = geo.a;
    bool isWater = isMat(matID, MATID_WATER);

#ifndef SSR
    outColor = vec4(color, 1.0); return;
#endif

    // Only reflect reasonably smooth surfaces (and water) to save rays.
    if (smoothness < 0.4 && !isWater) { outColor = vec4(color, 1.0); return; }

    vec3 viewPos = screenToView(vec3(uv, depth), gbufferProjectionInverse);
    vec3 worldNormal = decodeNormal(geo.rg);
    vec3 viewNormal = normalize(mat3(gbufferModelView) * worldNormal);

    vec3 I = normalize(viewPos);
    vec3 R = reflect(I, viewNormal);

    float dither = interleavedGradient(gl_FragCoord.xy, float(frameCounter));

    // Glossy jitter for rough reflections.
#ifdef ROUGH_REFLECTIONS
    float rough = sqr(1.0 - smoothness);
    vec3 jitter = (vec3(hash12(gl_FragCoord.xy + float(frameCounter)),
                        hash12(gl_FragCoord.yx + float(frameCounter) * 1.3),
                        hash12(gl_FragCoord.xy * 1.7)) - 0.5) * rough * 0.4;
    R = normalize(R + jitter);
#endif

    // Fresnel term (metals reflect coloured, dielectrics white).
    float f0scalar = material.g;
    vec3 f0 = f0scalar > 0.9 ? texture(colortex0, uv).rgb : vec3(max(f0scalar, 0.02));
    float NdotV = max(dot(viewNormal, -I), 1e-3);
    vec3 fresnel = fresnelSchlick(NdotV, f0);

    vec3 reflColor;
    vec2 hitUV;
    if (traceSSR(viewPos, R, dither, hitUV)) {
        reflColor = texture(colortex0, hitUV).rgb;
        // Fade near screen edges to hide the SSR cut-off.
        vec2 e = smoothstep(0.0, 0.1, hitUV) * smoothstep(1.0, 0.9, hitUV);
        float edge = e.x * e.y;
        // Sky fallback outside the fade.
        vec3 worldR = normalize(mat3(gbufferModelViewInverse) * R);
        vec3 sunDir  = normalize(mat3(gbufferModelViewInverse) * sunPosition);
        vec3 moonDir = normalize(mat3(gbufferModelViewInverse) * moonPosition);
        DayPhase phase = getDayPhase(sunDir.y);
        vec3 skyR = getSkyColor(worldR, sunDir, moonDir, phase, rainStrength);
        reflColor = mix(skyR, reflColor, edge);
    } else {
#ifdef SKY_REFLECTION_FALLBACK
        vec3 worldR = normalize(mat3(gbufferModelViewInverse) * R);
        vec3 sunDir  = normalize(mat3(gbufferModelViewInverse) * sunPosition);
        vec3 moonDir = normalize(mat3(gbufferModelViewInverse) * moonPosition);
        DayPhase phase = getDayPhase(sunDir.y);
        reflColor = getSkyColor(worldR, sunDir, moonDir, phase, rainStrength);
#else
        reflColor = color;
#endif
    }

    // Water already carries a sky reflection; SSR augments it. Opaque smooth
    // surfaces blend by fresnel*smoothness so only glossy areas pick it up.
    float weight = isWater ? maxOf(fresnel) : maxOf(fresnel) * smoothness;
    color = mix(color, reflColor, saturate(weight));

    outColor = vec4(color, 1.0);
}
