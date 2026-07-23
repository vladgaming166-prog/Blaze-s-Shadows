#version 330 compatibility
/*
  Blaze's Shadows - gbuffers_spidereyes.fsh
  Glowing mob eyes (spiders, endermen...). Rendered additively by Minecraft; we just
  emit the texture with a touch of extra intensity so it glows in the dark.
*/
#include "/lib/framebuffer.glsl"
#include "/lib/settings.glsl"

uniform sampler2D gtexture;

in vec4 glcolor;
in vec2 texcoord;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 outColor;

void main() {
    vec4 tex = texture(gtexture, texcoord) * glcolor;
    outColor = vec4(tex.rgb * (1.0 + EMISSIVE_STRENGTH), tex.a);
}
