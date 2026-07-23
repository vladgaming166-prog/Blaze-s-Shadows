#version 330 compatibility
/*
====================================================================================
  Blaze's Shadows  -  gbuffers_entities.fsh
------------------------------------------------------------------------------------
  Writes entities into the G-buffer so they receive the same deferred lighting,
  shadows and GI as the world. Honours the entity damage/spawn tint and reads
  labPBR specular for emissive mob parts if the resource pack provides them.
====================================================================================
*/
#include "/lib/framebuffer.glsl"
#include "/lib/settings.glsl"
#include "/lib/util/encoding.glsl"
#include "/lib/material/labpbr.glsl"
#include "/lib/material/ids.glsl"

uniform sampler2D gtexture;
uniform sampler2D specular;
uniform vec4 entityColor;   // .rgb tint, .a blend factor
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

    // Damage flash / spawn-egg overlay.
    tex.rgb = mix(tex.rgb, entityColor.rgb, entityColor.a);

    Material mat = decodeSpecular(texture(specular, texcoord), tex.rgb);

    outColor    = tex;
    outGeometry = vec4(encodeNormal(normalize(worldNormal)), encodeLightmap(lmcoord), MATID_ENTITY);
    outMaterial = vec4(mat.smoothness, mat.metalness > 0.5 ? 1.0 : mat.f0,
                       mat.emission * EMISSIVE_STRENGTH, mat.sss);
}
