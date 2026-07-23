#version 330 compatibility
/*
====================================================================================
  Blaze's Shadows  -  gbuffers_basic.vsh
------------------------------------------------------------------------------------
  Untextured primitives: block selection outline, hitboxes, leash/fishing lines.
  We just forward colour and lightmap; these are shaded flat (unlit) downstream.
====================================================================================
*/
out vec4 glcolor;
out vec2 lmcoord;

void main() {
    gl_Position = ftransform();
    glcolor = gl_Color;
    lmcoord = (gl_TextureMatrix[1] * vec4(gl_MultiTexCoord1.xy, 0.0, 1.0)).xy;
}
