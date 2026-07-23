/*
====================================================================================
  Blaze's Shadows  -  lib/framebuffer.glsl
------------------------------------------------------------------------------------
  Central declaration of every render target's pixel format and clear behaviour.
  OptiFine / Iris scan shader source for these `const` declarations, so this header
  is included by the fragment programs that own the pipeline.

  ----------------------------------------------------------------------------------
  RENDER TARGET LAYOUT
  ----------------------------------------------------------------------------------
  colortex0  RGBA16F   Main HDR scene colour. gbuffers write albedo, deferred writes
                       the lit result, composites keep refining it.
  colortex1  RGBA16    G-buffer geometry:
                         .rg = octahedral world-space normal
                         .b  = packed lightmap (block + sky)
                         .a  = material id / mask  (0..1)
  colortex2  RGBA16F   G-buffer material (labPBR-ish):
                         .r = smoothness (perceptual)
                         .g = reflectance / F0
                         .b = emission
                         .a = subsurface / porosity
  colortex3  RGBA16F   Scratch: SSAO+GI (rgb = bounced light, a = AO). Also reused as
                       a working buffer by fog / reflection passes.
  colortex4  RGBA16F   Volumetrics accumulation (rgb = inscatter, a = transmittance).
  colortex5  RGBA16F   Temporal history (previous frame colour) - NOT cleared.
  colortex6  RGBA16F   Bloom mip pyramid tiles.
  colortex7  RGBA16F   Persistent data (auto-exposure luma, cloud history) - NOT cleared.
  ----------------------------------------------------------------------------------
*/
#ifndef BLAZE_FRAMEBUFFER_GLSL
#define BLAZE_FRAMEBUFFER_GLSL

const int colortex0Format = RGBA16F;
const int colortex1Format = RGBA16;
const int colortex2Format = RGBA16F;
const int colortex3Format = RGBA16F;
const int colortex4Format = RGBA16F;
const int colortex5Format = RGBA16F;
const int colortex6Format = RGBA16F;
const int colortex7Format = RGBA16F;

// History buffers must survive between frames.
const bool colortex5Clear = false;
const bool colortex7Clear = false;

#endif // BLAZE_FRAMEBUFFER_GLSL
