#version 330 compatibility
/*
====================================================================================
  Blaze's Shadows  -  world-1/composite1.fsh   (NETHER fog / heat haze / smoke)
------------------------------------------------------------------------------------
  Dense, warm distance fog plus an optional heat-shimmer that distorts the scene and
  a drifting volumetric smoke haze for atmosphere.
====================================================================================
*/
#include "/lib/framebuffer.glsl"
#include "/lib/settings.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/util/encoding.glsl"
#include "/lib/util/spaces.glsl"
#include "/lib/util/noise.glsl"

in vec2 uv;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 outColor;

void main() {
    vec2 coord = uv;

    // ---- Heat haze : distort the sample coordinate --------------------------
#ifdef NETHER_HEAT_HAZE
    float t = frameTimeCounter * 1.5;
    vec2 warp = vec2(
        valueNoise(vec2(uv.y * 40.0, t)) - 0.5,
        valueNoise(vec2(uv.x * 40.0 + 13.0, t)) - 0.5);
    // Stronger toward the bottom of the screen (closer to lava seas).
    float haze = (1.0 - uv.y) * 0.004;
    coord += warp * haze;
#endif

    vec3 color = texture(colortex0, coord).rgb;
    float depth = texture(depthtex0, coord).r;

    vec3 viewPos = screenToView(vec3(coord, depth), gbufferProjectionInverse);
    float dist = length(viewPos);
    vec3 fog = srgbToLinear(fogColor) * 1.2;

    // Dense exponential fog.
    float f = 1.0 - exp(-dist * 0.03 * FOG_DENSITY);
    color = mix(color, fog, saturate(f));

    // ---- Volumetric smoke : drifting noise haze ----------------------------
#ifdef NETHER_SMOKE
    vec3 scenePos = mat3(gbufferModelViewInverse) * viewPos + gbufferModelViewInverse[3].xyz
                  + cameraPosition;
    float smoke = fbm(scenePos * 0.03 + vec3(frameTimeCounter * 0.15, 0.0, 0.0), 4, 2.0, 0.5);
    smoke = saturate(smoke - 0.4) * saturate(dist * 0.02);
    color += fog * smoke * 0.4;
#endif

    color *= 1.0 - saturate(blindness + darknessFactor);
    outColor = vec4(max(color, vec3(0.0)), 1.0);
}
