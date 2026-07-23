#version 330 compatibility
/*
====================================================================================
  Blaze's Shadows  -  shadow.fsh
------------------------------------------------------------------------------------
  Writes the shadow map. shadowtex0/1 store depth automatically; we additionally
  write the occluder's colour into shadowcolor0 so translucent blockers (stained
  glass, water) can tint the light for coloured shadows.
====================================================================================
*/
#include "/lib/util/encoding.glsl"

uniform sampler2D gtexture;
uniform float alphaTestRef;

in vec2 texcoord;
in vec4 glcolor;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 shadowColor0;

void main() {
    vec4 tex = texture(gtexture, texcoord) * glcolor;
    if (tex.a < alphaTestRef) discard;

    // Store a light transmission colour. Opaque occluders (alpha==1) block fully;
    // translucent ones pass a tinted fraction (handled by the deferred sampler).
    vec3 tint = srgbToLinear(tex.rgb);
    shadowColor0 = vec4(tint, tex.a);
}
