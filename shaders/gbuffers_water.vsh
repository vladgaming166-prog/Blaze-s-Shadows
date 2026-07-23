#version 330 compatibility
/*
====================================================================================
  Blaze's Shadows  -  gbuffers_water.vsh
------------------------------------------------------------------------------------
  Translucent geometry (water, stained glass, ice, slime...). Water vertices get a
  vertical wave displacement; everything else passes through. Builds the tangent
  basis and forwards world/view positions for the forward-shaded fragment stage.
====================================================================================
*/
#include "/lib/settings.glsl"
#include "/lib/vertex/waving.glsl"

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;

in vec4 mc_Entity;
in vec4 mc_midTexCoord;
in vec4 at_tangent;

out vec4 glcolor;
out vec2 texcoord;
out vec2 lmcoord;
out vec3 worldNormal;
out vec3 viewPos;
out vec3 worldPos;
out mat3 tbn;
flat out int blockId;

#define ID_WATER 10008

void main() {
    glcolor  = gl_Color;
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord  = (gl_TextureMatrix[1] * vec4(gl_MultiTexCoord1.xy, 0.0, 1.0)).xy;
    blockId  = int(mc_Entity.x + 0.5);

    vec3 wN = normalize(mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal));
    vec3 wT = normalize(mat3(gbufferModelViewInverse) * (gl_NormalMatrix * at_tangent.xyz));
    tbn = mat3(wT, cross(wT, wN) * sign(at_tangent.w), wN);
    worldNormal = wN;

    vec4 viewSpace = gl_ModelViewMatrix * gl_Vertex;
    vec3 playerPos = (gbufferModelViewInverse * viewSpace).xyz;
    worldPos = playerPos + cameraPosition;

    // Vertical wave displacement on horizontal water surfaces.
    if (blockId == ID_WATER && wN.y > 0.5) {
        playerPos.y += getWaterWaveHeight(worldPos);
    }

    viewSpace = gbufferModelView * vec4(playerPos, 1.0);
    viewPos = viewSpace.xyz;
    worldPos = playerPos + cameraPosition;
    gl_Position = gl_ProjectionMatrix * viewSpace;
}
