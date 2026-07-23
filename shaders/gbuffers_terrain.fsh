#version 330 compatibility
/*
====================================================================================
  Blaze's Shadows  -  gbuffers_terrain.fsh
------------------------------------------------------------------------------------
  The heart of the G-buffer. Samples albedo (+ optional labPBR normal/specular),
  applies optional parallax occlusion mapping, resolves the world-space normal,
  classifies the material, and packs everything into colortex0/1/2.
====================================================================================
*/
#include "/lib/framebuffer.glsl"
#include "/lib/settings.glsl"
#include "/lib/util/encoding.glsl"
#include "/lib/material/labpbr.glsl"
#include "/lib/material/ids.glsl"

uniform sampler2D gtexture;  // albedo atlas
uniform sampler2D normals;   // labPBR normal atlas
uniform sampler2D specular;  // labPBR specular atlas
uniform float alphaTestRef;

in vec4 glcolor;
in vec2 texcoord;
in vec2 lmcoord;
in vec2 midTexCoord;
in vec3 worldNormal;
in vec3 viewPos;
in mat3 tbn;
flat in int blockId;

/* DRAWBUFFERS:012 */
layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outGeometry;
layout(location = 2) out vec4 outMaterial;

// Emissive / foliage block id sets (see block.properties).
bool isEmissiveBlock(int id) { return id == 10050; }
bool isEmissiveOre(int id)   { return id == 10051; }
bool isFoliage(int id)       { return id == 10001 || id == 10002 || id == 10006; }
bool isLeaves(int id)        { return id == 10003; }

#if defined(NORMAL_MAPS) && (PARALLAX_DEPTH > 0.0)
// Parallax occlusion mapping confined to a single atlas tile.
vec2 parallaxMap(vec2 uv, vec2 tileMin, vec2 tileSize, vec3 viewTangent) {
    const int steps = POM_SAMPLES;
    float layerDepth = 1.0 / float(steps);
    float curLayer = 0.0;
    // March opposite the view direction in tangent space.
    vec2 delta = (viewTangent.xy / max(abs(viewTangent.z), 0.05)) * PARALLAX_DEPTH * tileSize;
    delta /= float(steps);

    vec2 local = fract((uv - tileMin) / tileSize);
    float height = texture(normals, tileMin + local * tileSize).a;
    float prevH = height;
    for (int i = 0; i < steps; i++) {
        if (curLayer >= 1.0 - height) break;
        local = fract(local - delta / tileSize);
        prevH = height;
        height = texture(normals, tileMin + local * tileSize).a;
        curLayer += layerDepth;
    }
    return tileMin + local * tileSize;
}
#endif

void main() {
    vec2 uv = texcoord;

#if defined(NORMAL_MAPS) && (PARALLAX_DEPTH > 0.0)
    // Tile bounds: each vertex sits half a tile from the centre.
    vec2 tileSize = abs(texcoord - midTexCoord) * 2.0;
    vec2 tileMin  = midTexCoord - tileSize * 0.5;
    // View direction in tangent space.
    vec3 viewDirT = normalize(transpose(tbn) * (-viewPos));
    if (tileSize.x > 1e-5 && tileSize.y > 1e-5) {
        vec2 pomUV = parallaxMap(texcoord, tileMin, tileSize, viewDirT);
        // Guard against sampling a neighbouring tile.
        uv = clamp(pomUV, tileMin + 1e-4, tileMin + tileSize - 1e-4);
    }
#endif

    vec4 albedo = texture(gtexture, uv) * glcolor;
    if (albedo.a < alphaTestRef) discard;

    // ---- Material -----------------------------------------------------------
    vec4 specTex = texture(specular, uv);
    Material mat = decodeSpecular(specTex, albedo.rgb);

    // ---- Normal -------------------------------------------------------------
    vec3 wNormal = normalize(worldNormal);
#ifdef NORMAL_MAPS
    float texAO, texHeight;
    vec3 tanN = decodeNormalMap(texture(normals, uv), texAO, texHeight);
    wNormal = normalize(tbn * tanN);
    mat.ao *= texAO;
#endif

    // ---- Material id + hard-coded emission ---------------------------------
    float matID = MATID_OPAQUE;
    if (isFoliage(blockId)) matID = MATID_FOLIAGE;
    if (isLeaves(blockId))  matID = MATID_LEAVES;

#ifdef EMISSIVE
    if (isEmissiveBlock(blockId)) { mat.emission = max(mat.emission, 1.0); matID = MATID_EMISSIVE; }
    if (isEmissiveOre(blockId))   { mat.emission = max(mat.emission, 0.6); }
#endif

    // Give plants a touch of subsurface so backlight glows through them.
    if (matID == MATID_FOLIAGE || matID == MATID_LEAVES) mat.sss = max(mat.sss, 0.6);

    // ---- Output -------------------------------------------------------------
    outColor    = albedo;
    outGeometry = vec4(encodeNormal(wNormal), encodeLightmap(lmcoord), matID);
    outMaterial = vec4(mat.smoothness, mat.metalness > 0.5 ? 1.0 : mat.f0,
                       mat.emission * EMISSIVE_STRENGTH, mat.sss);
    // Bake AO into albedo alpha is not possible (used for cutout); fold light AO into colour.
    outColor.rgb *= mix(1.0, mat.ao, 0.5);
}
