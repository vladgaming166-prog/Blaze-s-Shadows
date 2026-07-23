#version 330 compatibility
/*
====================================================================================
  Blaze's Shadows  -  shadow.vsh
------------------------------------------------------------------------------------
  Renders the world from the sun/moon's point of view into the shadow map. Applies
  the same wind displacement as terrain so plant shadows sway in sync, then warps the
  clip position with the distortion function shared with the deferred sampler.
====================================================================================
*/
#include "/lib/settings.glsl"
#include "/lib/vertex/waving.glsl"
#include "/lib/lighting/shadow_distort.glsl"

uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowProjection;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;

in vec4 mc_Entity;
in vec4 mc_midTexCoord;

out vec2 texcoord;
out vec4 glcolor;

#define ID_WATER 10008

void main() {
    glcolor  = gl_Color;
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    int blockId = int(mc_Entity.x + 0.5);

    vec4 viewSpace = gl_ModelViewMatrix * gl_Vertex; // shadow-view space
    vec3 playerPos = (shadowModelViewInverse * viewSpace).xyz;
    vec3 worldPos  = playerPos + cameraPosition;

    // Match terrain waving so shadows line up with geometry.
    float topWeight = float(texcoord.y < mc_midTexCoord.y);
    playerPos += getWavingOffset(worldPos, blockId, topWeight, 1.0);
    if (blockId == ID_WATER) playerPos.y += getWaterWaveHeight(worldPos);

    viewSpace = shadowModelView * vec4(playerPos, 1.0);
    vec4 clip = shadowProjection * viewSpace;
    clip.xyz = distortShadowClip(clip.xyz);
    gl_Position = clip;
}
