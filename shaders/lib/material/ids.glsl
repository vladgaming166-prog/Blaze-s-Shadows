/*
====================================================================================
  Blaze's Shadows  -  lib/material/ids.glsl
------------------------------------------------------------------------------------
  Canonical material-id values stored in colortex1.a by the G-buffer stage and read
  back by the deferred lighting stage. Kept as explicit constants (and matched with
  helper comparisons) so both writers and readers never drift apart.
====================================================================================
*/
#ifndef BLAZE_IDS_GLSL
#define BLAZE_IDS_GLSL

const float MATID_OPAQUE   = 0.00; // generic terrain / blocks
const float MATID_FOLIAGE  = 0.10; // grass, small plants (subsurface)
const float MATID_LEAVES   = 0.20; // leaf blocks (subsurface)
const float MATID_EMISSIVE = 0.30; // hard-coded emissive blocks
const float MATID_WATER    = 0.50; // water surface (forward shaded)
const float MATID_TRANSLUC = 0.60; // stained glass, ice, slime
const float MATID_HAND     = 0.70; // held items / arms
const float MATID_ENTITY   = 0.90; // living entities
const float MATID_UNLIT    = 1.00; // already-shaded geometry, skip deferred lighting

// Tolerant comparison for the 16-bit stored value.
bool isMat(float stored, float id) { return abs(stored - id) < 0.03; }

#endif // BLAZE_IDS_GLSL
