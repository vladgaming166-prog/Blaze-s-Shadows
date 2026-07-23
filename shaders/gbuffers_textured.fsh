#version 330 compatibility
/*
====================================================================================
  Blaze's Shadows  -  gbuffers_textured.fsh
------------------------------------------------------------------------------------
  Standard textured fragments (particles, etc.). Emits the full G-buffer so the
  deferred stage can light them like everything else.
====================================================================================
*/
#include "/lib/framebuffer.glsl"
#include "/lib/util/encoding.glsl"
#include "/lib/material/ids.glsl"

uniform sampler2D gtexture;
uniform float alphaTestRef;

in vec4 glcolor;
in vec2 texcoord;
in vec2 lmcoord;
in vec3 worldNormal;

/* DRAWBUFFERS:012 */
layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outGeometry;
layout(location = 2) out vec4 outMaterial;

void main() {
    vec4 tex = texture(gtexture, texcoord) * glcolor;
    if (tex.a < alphaTestRef) discard;

    outColor    = tex;
    outGeometry = vec4(encodeNormal(normalize(worldNormal)), encodeLightmap(lmcoord), MATID_OPAQUE);
    outMaterial = vec4(0.0, 0.04, 0.0, 0.0); // rough dielectric, no emission
}
