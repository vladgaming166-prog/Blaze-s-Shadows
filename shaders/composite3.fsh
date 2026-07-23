#version 330 compatibility
/*
  Blaze's Shadows - composite3.fsh  (pass 6: bloom bright extraction)
  Extract HDR highlights from the resolved scene into colortex6.
*/
#include "/lib/framebuffer.glsl"
#include "/lib/post/bloom.glsl"

uniform sampler2D colortex0;

in vec2 uv;

/* DRAWBUFFERS:6 */
layout(location = 0) out vec4 outBloom;

void main() {
#ifdef BLOOM
    outBloom = vec4(bloomBrightPass(texture(colortex0, uv).rgb), 1.0);
#else
    outBloom = vec4(0.0);
#endif
}
