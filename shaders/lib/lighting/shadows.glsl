/*
====================================================================================
  Blaze's Shadows  -  lib/lighting/shadows.glsl
------------------------------------------------------------------------------------
  Everything shadow related for the deferred lighting pass:
    * shadow-clip distortion (poor-man's cascade: more texels near the camera),
    * normal + slope biasing to kill acne and peter-panning,
    * PCSS: a blocker search estimates penumbra size so contact points stay crisp
      while distant shadows soften (contact hardening),
    * PCF filtering with an interleaved-gradient rotated Poisson disk,
    * coloured shadows via shadowcolor0 (stained glass, tinted water),
    * temporal texel snapping to keep edges stable.

  The functions read the shadow* uniforms and shadow samplers declared in
  lib/uniforms.glsl, so this header must be included by a stage that has them.
====================================================================================
*/
#ifndef BLAZE_SHADOWS_GLSL
#define BLAZE_SHADOWS_GLSL

#include "/lib/settings.glsl"
#include "/lib/util/math.glsl"
#include "/lib/util/noise.glsl"
#include "/lib/lighting/shadow_distort.glsl"

// A 16-tap Poisson disk for filtering.
const vec2 POISSON16[16] = vec2[16](
    vec2(-0.9420, -0.3990), vec2( 0.9456, -0.7689), vec2(-0.0942, -0.9294),
    vec2( 0.3450,  0.2939), vec2(-0.9159,  0.4577), vec2(-0.8154, -0.8791),
    vec2(-0.3828,  0.2768), vec2( 0.9748,  0.7565), vec2( 0.4432, -0.9751),
    vec2( 0.5374, -0.4737), vec2(-0.2650, -0.4189), vec2( 0.7911, -0.1908),
    vec2(-0.2419,  0.9971), vec2( 0.1956,  0.9186), vec2( 0.5033,  0.7452),
    vec2(-0.7196, -0.0777)
);

// Transform a player/scene-space position into distorted shadow-map UV + depth.
vec3 sceneToShadow(vec3 scenePos, vec3 worldNormal, float biasScale) {
    // World -> shadow view -> shadow clip.
    vec3 shadowView = (shadowModelView * vec4(scenePos, 1.0)).xyz;

    // Normal offset bias in shadow-view space (scaled by texel size + distortion).
    vec3 shadowNormal = mat3(shadowModelView) * worldNormal;
    float texelSize = 2.0 / float(shadowMapResolution);
    shadowView += shadowNormal * texelSize * biasScale * 2.0;

    vec3 clip = (shadowProjection * vec4(shadowView, 1.0)).xyz;
    clip = distortShadowClip(clip);
    return clip * 0.5 + 0.5; // to [0,1]
}

// Blocker search: average depth of occluders in front of the receiver.
float findBlockerDepth(vec2 uv, float receiverZ, float searchRadius, float dither) {
    float sum = 0.0;
    float count = 0.0;
    float rot = dither * TAU;
    mat2 rm = mat2(cos(rot), -sin(rot), sin(rot), cos(rot));
    for (int i = 0; i < 8; i++) {
        vec2 o = rm * POISSON16[i] * searchRadius;
        float z = texture(shadowtex0, uv + o).r;
        if (z < receiverZ) { sum += z; count += 1.0; }
    }
    if (count < 0.5) return -1.0; // fully lit
    return sum / count;
}

/*
  Main shadow evaluation.
    scenePos    - fragment position in player space
    worldNormal - fragment world-space normal
    NdotL       - cosine of the light angle (for slope bias)
    dither      - per-pixel dither in [0,1)
  Returns an RGB visibility term (coloured for translucent occluders).
*/
vec3 getShadows(vec3 scenePos, vec3 worldNormal, float NdotL, float dither) {
    // Outside the shadow distance -> assume fully lit (fog/ambient covers it).
    float sceneDist = length(scenePos.xz);
    if (sceneDist > SHADOW_DISTANCE) return vec3(1.0);

    float biasScale = 1.0 + (1.0 - saturate(NdotL)) * 2.0; // more bias at grazing angles
    vec3 shadowPos = sceneToShadow(scenePos, worldNormal, biasScale);

    // Reject samples outside the shadow frustum.
    if (any(lessThan(shadowPos.xy, vec2(0.0))) || any(greaterThan(shadowPos.xy, vec2(1.0))))
        return vec3(1.0);

    float df = distortFactor(shadowPos.xy * 2.0 - 1.0);
    float texel = 1.0 / float(shadowMapResolution);

    // Depth bias to prevent acne, scaled by distortion + slope.
    float depthBias = (0.00035 + 0.0018 * (1.0 - saturate(NdotL))) * df;
    float receiverZ = shadowPos.z - depthBias;

    // ---- Penumbra size ------------------------------------------------------
    float filterRadius = 1.5 * SHADOW_SOFTNESS * texel;
#ifdef CONTACT_HARDENING
    float searchRadius = 3.0 * texel;
    float blocker = findBlockerDepth(shadowPos.xy, receiverZ, searchRadius, dither);
    if (blocker > 0.0) {
        // PCSS penumbra estimate: (receiver - blocker) / blocker.
        float penumbra = (receiverZ - blocker) / max(blocker, 1e-4);
        filterRadius = clamp(penumbra * 60.0, 0.6, 8.0) * SHADOW_SOFTNESS * texel;
    }
#endif

    // ---- PCF filter ---------------------------------------------------------
#ifdef SHADOW_FILTER
    const int TAPS = 16;
#else
    const int TAPS = 1;
#endif
    float rot = dither * TAU;
    mat2 rm = mat2(cos(rot), -sin(rot), sin(rot), cos(rot));

    float visible = 0.0;
    vec3  colored = vec3(0.0);
    for (int i = 0; i < TAPS; i++) {
        vec2 o = (TAPS == 1) ? vec2(0.0) : rm * POISSON16[i] * filterRadius;
        vec2 uv = shadowPos.xy + o;

        // shadowtex1 = opaque only. If the opaque test passes we are fully lit.
        float opaqueZ = texture(shadowtex1, uv).r;
        float litOpaque = step(receiverZ, opaqueZ);

#ifdef COLORED_SHADOWS
        // shadowtex0 includes translucents. Between the two we get a coloured region.
        float allZ = texture(shadowtex0, uv).r;
        float litAll = step(receiverZ, allZ);
        vec4 tint = texture(shadowcolor0, uv);
        // If blocked by a translucent (litOpaque but !litAll) use its colour.
        vec3 sampleCol = mix(tint.rgb * (1.0 - tint.a), vec3(1.0), litAll);
        colored += mix(vec3(0.0), sampleCol, litOpaque);
#else
        colored += vec3(litOpaque);
#endif
        visible += litOpaque;
    }
    colored /= float(TAPS);

    // Fade the shadow out toward the shadow-distance edge (1 near camera, 0 at edge).
    float edgeFade = 1.0 - smoothstep(SHADOW_DISTANCE * 0.85, SHADOW_DISTANCE, sceneDist);
    return mix(vec3(1.0), colored, edgeFade);
}

#endif // BLAZE_SHADOWS_GLSL
