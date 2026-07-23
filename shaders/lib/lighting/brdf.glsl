/*
====================================================================================
  Blaze's Shadows  -  lib/lighting/brdf.glsl
------------------------------------------------------------------------------------
  A compact, physically based BRDF: GGX/Trowbridge-Reitz specular with the
  height-correlated Smith visibility term and Schlick Fresnel, plus a Burley
  (Disney) diffuse term for softer, more realistic shading than flat Lambert.
====================================================================================
*/
#ifndef BLAZE_BRDF_GLSL
#define BLAZE_BRDF_GLSL

#include "/lib/util/math.glsl"

// Schlick's Fresnel approximation.
vec3 fresnelSchlick(float cosTheta, vec3 f0) {
    return f0 + (1.0 - f0) * pow(saturate(1.0 - cosTheta), 5.0);
}
float fresnelSchlick(float cosTheta, float f0) {
    return f0 + (1.0 - f0) * pow(saturate(1.0 - cosTheta), 5.0);
}

// GGX normal distribution function.
float distributionGGX(float NdotH, float roughness) {
    float a = roughness * roughness;
    float a2 = a * a;
    float d = NdotH * NdotH * (a2 - 1.0) + 1.0;
    return a2 / max(PI * d * d, 1e-7);
}

// Height-correlated Smith visibility (already includes the 1/(4 NdotL NdotV)).
float visibilitySmith(float NdotV, float NdotL, float roughness) {
    float a = roughness * roughness;
    float a2 = a * a;
    float gv = NdotL * sqrt(NdotV * NdotV * (1.0 - a2) + a2);
    float gl = NdotV * sqrt(NdotL * NdotL * (1.0 - a2) + a2);
    return 0.5 / max(gv + gl, 1e-7);
}

// Burley (Disney) diffuse - retroreflection at grazing angles.
float diffuseBurley(float NdotV, float NdotL, float LdotH, float roughness) {
    float fd90 = 0.5 + 2.0 * LdotH * LdotH * roughness;
    float fv = 1.0 + (fd90 - 1.0) * pow(1.0 - NdotV, 5.0);
    float fl = 1.0 + (fd90 - 1.0) * pow(1.0 - NdotL, 5.0);
    return fv * fl * INV_PI;
}

/*
  Evaluate direct lighting for one light.
    N,V,L      - normal, view, light directions (world space, normalized)
    albedo     - base colour (linear)
    f0         - specular reflectance at normal incidence
    roughness  - perceptual roughness [0,1]
    metalness  - 0 dielectric .. 1 metal
  Returns radiance (to be multiplied by light colour * NdotL * shadow).
*/
vec3 evalBRDF(vec3 N, vec3 V, vec3 L, vec3 albedo, vec3 f0, float roughness, float metalness) {
    vec3 H = normalize(V + L);
    float NdotL = max(dot(N, L), 0.0);
    float NdotV = max(dot(N, V), 1e-4);
    float NdotH = max(dot(N, H), 0.0);
    float LdotH = max(dot(L, H), 0.0);

    // Specular.
    float D = distributionGGX(NdotH, roughness);
    float Vis = visibilitySmith(NdotV, NdotL, roughness);
    vec3  F = fresnelSchlick(LdotH, f0);
    vec3 spec = D * Vis * F;

    // Diffuse (metals have no diffuse).
    vec3 kd = (1.0 - F) * (1.0 - metalness);
    vec3 diff = kd * albedo * diffuseBurley(NdotV, NdotL, LdotH, roughness);

    return (diff + spec);
}

// Environment BRDF approximation (Karis' analytic fit) for image-based specular.
vec3 envBRDFApprox(vec3 f0, float roughness, float NdotV) {
    const vec4 c0 = vec4(-1.0, -0.0275, -0.572, 0.022);
    const vec4 c1 = vec4( 1.0,  0.0425,  1.04, -0.04);
    vec4 r = roughness * c0 + c1;
    float a004 = min(r.x * r.x, exp2(-9.28 * NdotV)) * r.x + r.y;
    vec2 ab = vec2(-1.04, 1.04) * a004 + r.zw;
    return f0 * ab.x + ab.y;
}

#endif // BLAZE_BRDF_GLSL
