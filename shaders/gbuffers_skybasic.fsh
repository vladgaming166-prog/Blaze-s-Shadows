#version 330 compatibility
/*
  Blaze's Shadows - gbuffers_skybasic.fsh
  Clear the sky pixels to black; the deferred pass paints the procedural sky over
  every fragment whose depth is at the far plane.
*/
#include "/lib/framebuffer.glsl"

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 outColor;

void main() {
    outColor = vec4(0.0, 0.0, 0.0, 1.0);
}
