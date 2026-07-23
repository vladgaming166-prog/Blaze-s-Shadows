# Changelog

All notable changes to **Blaze's Shadows** are documented here.
This project adheres to [Semantic Versioning](https://semver.org/).

## [1.0.0] - 2026-07-23

### Added — first public release 🎉

**Pipeline**
- Full deferred HDR pipeline for Iris & OptiFine (`#version 330 compatibility`), MC 1.21.x.
- G-buffer with octahedral normal encoding, packed lightmaps and labPBR material data.

**Lighting**
- Physically based BRDF (GGX + height-correlated Smith + Burley diffuse).
- Dynamic sun & moon with time-of-day colour, soft global illumination.
- Colour-temperature block light, emissive blocks/ores/mob eyes, handheld light.
- SSAO (Alchemy horizon) and single-bounce SSGI.
- Volumetric light shafts marched through the shadow map.

**Shadows**
- Distortion "cascade", PCSS contact hardening, PCF soft penumbra.
- Coloured shadows via `shadowcolor0`; screen-space contact shadows.
- Adjustable resolution (1024–4096) and distance; wind-synced plant shadows.

**Sky**
- Procedural analytic sky, golden sunrise / orange sunset, dynamic atmosphere.
- Ray-marched volumetric clouds with Beer-Powder lighting and storm build-up.
- Star field, Milky Way, shooting stars, aurora borealis, post-rain rainbow.

**Water & Weather**
- Animated waves, per-channel absorption, screen-space refraction, Fresnel + SSR
  reflection, caustics, foam, rain ripples, wet surfaces.

**Post-processing**
- Auto-exposure, five tonemap operators, soft-knee HDR bloom.
- Colour grading suite, TAA, FXAA, sharpen, vignette, chromatic aberration,
  motion blur, film grain, depth of field.

**Dimensions**
- Nether: hot ambient, heat haze, volumetric smoke, better lava.
- End: bespoke purple void sky, nebula, floating particles.

**Content & tooling**
- Five quality profiles (Low → Extreme) and a large, translated settings menu
  (English, Spanish, Simplified Chinese).
- Example look presets, brand assets (logo + icon), packaging & asset scripts,
  and full inline documentation across every shader stage.

[1.0.0]: https://example.com/blazes-shadows/releases/tag/v1.0.0
