#version 330 compatibility
/*
  Blaze's Shadows - composite4.fsh  (pass 7: bloom blur H, iteration 1)
  colortex6 -> colortex3, horizontal Gaussian.
*/
#include "/lib/framebuffer.glsl"
#include "/lib/post/bloom.glsl"

uniform sampler2D colortex6;
uniform float viewWidth;
uniform float viewHeight;

in vec2 uv;

/* DRAWBUFFERS:3 */
layout(location = 0) out vec4 outBloom;

void main() {
#ifdef BLOOM
    vec2 texel = 1.0 / vec2(viewWidth, viewHeight);
    outBloom = vec4(gaussianBlur(colortex6, uv, vec2(1.0, 0.0), texel), 1.0);
#else
    outBloom = vec4(0.0);
#endif
}
