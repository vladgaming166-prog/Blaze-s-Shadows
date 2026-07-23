#version 330 compatibility
/*
====================================================================================
  Blaze's Shadows  -  gbuffers_terrain.vsh
------------------------------------------------------------------------------------
  The main terrain (solid + cutout blocks) vertex stage.
    * builds the tangent basis for normal mapping / POM,
    * applies wind displacement to tagged blocks (see block.properties),
    * forwards everything the fragment stage needs.
====================================================================================
*/
#include "/lib/settings.glsl"
#include "/lib/vertex/waving.glsl"

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;

// OptiFine / Iris supplied vertex attributes.
in vec4 mc_Entity;      // .x = block id from block.properties
in vec4 mc_midTexCoord; // centre of the sprite in atlas space
in vec4 at_tangent;     // tangent (.xyz) and handedness (.w)

out vec4 glcolor;
out vec2 texcoord;
out vec2 lmcoord;
out vec2 midTexCoord;
out vec3 worldNormal;
out vec3 viewPos;
out mat3 tbn;
flat out int blockId;

void main() {
    glcolor     = gl_Color;
    texcoord    = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    midTexCoord = mc_midTexCoord.xy;
    lmcoord     = (gl_TextureMatrix[1] * vec4(gl_MultiTexCoord1.xy, 0.0, 1.0)).xy;
    blockId     = int(mc_Entity.x + 0.5);

    // Normal + tangent in world space.
    vec3 wNormal  = normalize(mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal));
    vec3 wTangent = normalize(mat3(gbufferModelViewInverse) * (gl_NormalMatrix * at_tangent.xyz));
    vec3 wBitangent = cross(wTangent, wNormal) * sign(at_tangent.w);
    tbn = mat3(wTangent, wBitangent, wNormal);
    worldNormal = wNormal;

    // View-space position (before waving) for later reconstruction.
    vec4 viewSpace = gl_ModelViewMatrix * gl_Vertex;

    // ---- Wind displacement --------------------------------------------------
    vec3 playerPos = (gbufferModelViewInverse * viewSpace).xyz;
    vec3 worldPos  = playerPos + cameraPosition;
    float topWeight = float(texcoord.y < midTexCoord.y); // upper sprite vertices bend most
    vec3 wave = getWavingOffset(worldPos, blockId, topWeight, lmcoord.y);
    playerPos += wave;

    viewSpace = gbufferModelView * vec4(playerPos, 1.0);
    viewPos = viewSpace.xyz;
    gl_Position = gl_ProjectionMatrix * viewSpace;
}
