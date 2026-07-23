#version 330 compatibility
/*
  Blaze's Shadows - gbuffers_beaconbeam.fsh
  The beacon beam is fully emissive - output it bright so bloom gives it a glow.
*/
#include "/lib/framebuffer.glsl"

uniform sampler2D gtexture;
uniform float alphaTestRef;

in vec4 glcolor;
in vec2 texcoord;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 outColor;

void main() {
    vec4 tex = texture(gtexture, texcoord) * glcolor;
    if (tex.a < alphaTestRef) discard;
    // Boost slightly so the beam blooms against a bright sky.
    outColor = vec4(tex.rgb * 1.6, tex.a);
}
