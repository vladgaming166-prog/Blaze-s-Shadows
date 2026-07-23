#version 330 compatibility
/*
====================================================================================
  Blaze's Shadows  -  gbuffers_textured.vsh
------------------------------------------------------------------------------------
  Textured, non-terrain geometry (particles, etc.). Exposes texture coords, vertex
  colour, packed lightmap and a world-space normal for the deferred stage.
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
    // Object normal -> view -> world.
    worldNormal = normalize(mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal));
}
