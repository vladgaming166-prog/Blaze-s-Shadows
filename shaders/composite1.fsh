#version 330 compatibility
/*
====================================================================================
  Blaze's Shadows  -  composite1.fsh   (pass 4: atmospheric + medium fog)
------------------------------------------------------------------------------------
  Blends the lit scene toward the sky colour with distance (aerial perspective),
  adds cave darkness and border fog, and applies the appropriate underwater / lava /
  powder-snow medium when the camera is submerged.
====================================================================================
*/
#include "/lib/framebuffer.glsl"
#include "/lib/settings.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/util/encoding.glsl"
#include "/lib/util/spaces.glsl"
#include "/lib/atmosphere/sky.glsl"
#include "/lib/atmosphere/fog.glsl"

in vec2 uv;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 outColor;

void main() {
    vec3 color = texture(colortex0, uv).rgb;
    float depth = texture(depthtex0, uv).r;

    vec3 viewPos = screenToView(vec3(uv, depth), gbufferProjectionInverse);
    vec3 scenePos = mat3(gbufferModelViewInverse) * viewPos + gbufferModelViewInverse[3].xyz;
    vec3 worldDir = normalize(mat3(gbufferModelViewInverse) * viewPos);

    vec3 sunDir  = normalize(mat3(gbufferModelViewInverse) * sunPosition);
    vec3 moonDir = normalize(mat3(gbufferModelViewInverse) * moonPosition);
    DayPhase phase = getDayPhase(sunDir.y);

    vec3 skyCol = getSkyColor(worldDir, sunDir, moonDir, phase, rainStrength);

    // Atmospheric fog only affects world geometry (not the sky itself).
    if (depth < 1.0) {
        float skyLight = decodeLightmap(texture(colortex1, uv).b).y;
        color = applyOverworldFog(color, scenePos, skyCol, phase, rainStrength, skyLight, far);
    }

    // Submerged medium.
    if (isEyeInWater > 0) {
        color = applyMediumFog(color, scenePos, isEyeInWater, phase, rainStrength);
    }

    // Blindness / darkness pulse dims the scene.
    color *= 1.0 - saturate(blindness + darknessFactor);

    outColor = vec4(max(color, vec3(0.0)), 1.0);
}
