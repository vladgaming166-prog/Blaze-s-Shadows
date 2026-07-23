#version 330 compatibility
/*
====================================================================================
  Blaze's Shadows  -  gbuffers_basic.fsh
------------------------------------------------------------------------------------
  Writes the primitive colour straight through and tags it UNLIT so the deferred
  pass leaves it untouched (selection boxes should not receive shadows/GI).
====================================================================================
*/
#include "/lib/framebuffer.glsl"
#include "/lib/util/encoding.glsl"
#include "/lib/material/ids.glsl"

in vec4 glcolor;
in vec2 lmcoord;

/* DRAWBUFFERS:012 */
layout(location = 0) out vec4 outColor;    // colortex0
layout(location = 1) out vec4 outGeometry; // colortex1
layout(location = 2) out vec4 outMaterial; // colortex2

void main() {
    outColor    = glcolor;
    outGeometry = vec4(encodeNormal(vec3(0.0, 1.0, 0.0)), encodeLightmap(lmcoord), MATID_UNLIT);
    outMaterial = vec4(0.0, 0.04, 0.0, 0.0);
}
