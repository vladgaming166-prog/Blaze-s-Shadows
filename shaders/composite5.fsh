#version 330 compatibility
/*
  Blaze's Shadows - composite5.fsh  (pass 8: bloom blur V, iteration 1)
  colortex3 -> colortex6, vertical Gaussian.
*/
#include "/lib/framebuffer.glsl"
#include "/lib/post/bloom.glsl"

uniform sampler2D colortex3;
uniform float viewWidth;
uniform float viewHeight;

in vec2 uv;

/* DRAWBUFFERS:6 */
layout(location = 0) out vec4 outBloom;

void main() {
#ifdef BLOOM
    vec2 texel = 1.0 / vec2(viewWidth, viewHeight);
    outBloom = vec4(gaussianBlur(colortex3, uv, vec2(0.0, 1.0), texel), 1.0);
#else
    outBloom = vec4(0.0);
#endif
}
