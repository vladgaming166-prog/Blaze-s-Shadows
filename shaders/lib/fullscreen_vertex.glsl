/*
====================================================================================
  Blaze's Shadows  -  lib/fullscreen_vertex.glsl
------------------------------------------------------------------------------------
  Shared vertex shader body for every full-screen (deferred / composite / final)
  pass. These programs draw a single fullscreen triangle/quad, so all the vertex
  stage does is forward the screen texture coordinate.
====================================================================================
*/
out vec2 uv;

void main() {
    gl_Position = ftransform();
    uv = gl_MultiTexCoord0.xy;
}
