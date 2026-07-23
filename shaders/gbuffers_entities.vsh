#version 330 compatibility
/*
====================================================================================
  Blaze's Shadows  -  gbuffers_entities.vsh
------------------------------------------------------------------------------------
  Living entities and dropped items. Standard textured geometry with a world-space
  normal; damage flash / spawn-egg tint arrives via the entityColor uniform.
====================================================================================
*/
uniform mat4 gbufferModelViewInverse;

out vec4 glcolor;
out vec2 texcoord;
out vec2 lmcoord;
out vec3 worldNormal;

void main() {
    gl_Position = ftransform();
    glcolor  = gl_Color;
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord  = (gl_TextureMatrix[1] * vec4(gl_MultiTexCoord1.xy, 0.0, 1.0)).xy;
    worldNormal = normalize(mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal));
}
