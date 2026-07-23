/*
====================================================================================
  Blaze's Shadows  -  settings.glsl
------------------------------------------------------------------------------------
  Master configuration header.

  Every user facing option lives here as a preprocessor define. The in-game
  settings menu (see shaders.properties) toggles these very same macros, which is
  why the identifiers must match exactly.

  The slider metadata that OptiFine / Iris parses lives in the trailing comment of
  each line, using the syntax:  //[value0 value1 value2 ...]

  This file is included by (almost) every program in the pack. Keep it cheap and
  free of executable code - defines and const-friendly values only.
====================================================================================
*/

#ifndef BLAZE_SETTINGS_GLSL
#define BLAZE_SETTINGS_GLSL

/* ==========================================================================
   0. GLOBAL QUALITY PRESET
   --------------------------------------------------------------------------
   The preset acts as a hint; individual features can still be overridden in
   their own screens. Profiles defined in shaders.properties flip the relevant
   defines directly, so this value is mostly informative for library code that
   wants to scale sample counts.
   ========================================================================== */
#define QUALITY_PRESET 3 // [1 2 3 4 5] Low=1 Medium=2 High=3 Ultra=4 Extreme=5


/* ==========================================================================
   1. LIGHTING
   ========================================================================== */
#define SUNLIGHT_INTENSITY 1.00   // [0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00 2.50 3.00]
#define MOONLIGHT_INTENSITY 1.00  // [0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00 2.50 3.00]
#define AMBIENT_INTENSITY 1.00    // [0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00]
#define BLOCKLIGHT_INTENSITY 1.00 // [0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00 2.50 3.00]
#define BLOCKLIGHT_TEMPERATURE 3000 // [2000 2500 3000 3500 4000 4500 5000] Colour temperature of torch light in Kelvin.

#define COLORED_LIGHTING          // Tint block light by a warm colour and let coloured shadows bleed through translucents.
#define HANDHELD_LIGHT            // Torch/held item illuminates nearby surfaces.
#define HANDHELD_LIGHT_INTENSITY 1.0 // [0.25 0.50 0.75 1.00 1.50 2.00]

// Soft global illumination (single-bounce sky/sun colour bleeding).
#define GI
#define GI_STRENGTH 1.00          // [0.25 0.50 0.75 1.00 1.50 2.00 3.00]


/* ==========================================================================
   2. SHADOWS
   ========================================================================== */
#define SHADOW_QUALITY 2          // [0 1 2 3 4] 0=1024 1=1536 2=2048 3=3072 4=4096
#define SHADOW_DISTANCE 160.0     // [80.0 120.0 160.0 200.0 256.0 320.0 512.0]
#define SHADOW_FILTER             // Soft PCF shadow filtering.
#define SHADOW_SOFTNESS 1.0       // [0.5 0.75 1.0 1.5 2.0 3.0] Penumbra size scale.
#define CONTACT_HARDENING         // PCSS - shadows harden near the contact point, soften with distance.
#define CONTACT_SHADOWS           // Screen space contact shadows for tiny/thin geometry.
#define COLORED_SHADOWS           // Stained glass and water tint the shadow.
#define TEMPORAL_SHADOW_STABILISE // Snap shadow projection to texel grid to reduce shimmering.
#define SHADOW_ENTITIES           // Entities cast shadows.


/* ==========================================================================
   3. AMBIENT OCCLUSION
   ========================================================================== */
#define SSAO                      // Screen space ambient occlusion.
#define SSAO_SAMPLES 12           // [4 6 8 12 16 24 32]
#define SSAO_RADIUS 0.75          // [0.25 0.50 0.75 1.00 1.50 2.00]
#define SSAO_STRENGTH 1.00        // [0.25 0.50 0.75 1.00 1.50 2.00]

#define SSGI                      // Screen space global illumination (one bounce of coloured light).
#define SSGI_STRENGTH 1.00        // [0.25 0.50 0.75 1.00 1.50 2.00]


/* ==========================================================================
   4. VOLUMETRICS
   ========================================================================== */
#define VOLUMETRIC_LIGHT          // God rays / light shafts.
#define VL_SAMPLES 16             // [6 8 12 16 24 32 48]
#define VL_INTENSITY 1.00         // [0.25 0.50 0.75 1.00 1.50 2.00 3.00]

#define VOLUMETRIC_FOG            // Height based volumetric atmospheric fog.
#define VL_FOG_DENSITY 1.00       // [0.25 0.50 0.75 1.00 1.50 2.00]


/* ==========================================================================
   5. SKY & ATMOSPHERE
   ========================================================================== */
#define SKY_BRIGHTNESS 1.00       // [0.50 0.75 1.00 1.25 1.50]
#define SKY_SATURATION 1.00       // [0.50 0.75 1.00 1.25 1.50]

#define CLOUDS                    // Master cloud toggle.
#define CLOUDS_VOLUMETRIC         // Ray-marched volumetric clouds (disable for cheap 2D clouds).
#define CLOUD_SAMPLES 20          // [8 12 16 20 28 40]
#define CLOUD_COVERAGE 0.50       // [0.30 0.40 0.50 0.60 0.70 0.80]
#define CLOUD_HEIGHT 320.0        // [180.0 240.0 320.0 420.0]
#define CLOUD_THICKNESS 220.0     // [120.0 180.0 220.0 300.0]

#define STARS                     // Procedural star field.
#define STAR_BRIGHTNESS 1.0       // [0.5 0.75 1.0 1.5 2.0]
#define MILKY_WAY                 // Galactic band across the night sky.
#define SHOOTING_STARS            // Occasional meteors.
#define AURORA                    // Aurora borealis in clear cold nights.
#define RAINBOW                   // Rainbow after rain while the sun is out.


/* ==========================================================================
   6. WATER
   ========================================================================== */
#define WATER_WAVES               // Animated gerstner-ish wave normals.
#define WATER_WAVE_HEIGHT 1.0     // [0.25 0.50 0.75 1.00 1.50 2.00]
#define WATER_REFRACTION          // Screen space refraction of the underwater scene.
#define WATER_CAUSTICS            // Animated caustics on submerged surfaces.
#define WATER_FOAM                // Foam near shorelines and wave crests.
#define WATER_FOG_DENSITY 1.00    // [0.25 0.50 0.75 1.00 1.50 2.00 3.00]
// Underwater absorption tint (how quickly R,G,B are absorbed by depth).
#define WATER_ABSORPTION_R 0.45   // [0.20 0.35 0.45 0.60 0.80]
#define WATER_ABSORPTION_G 0.16   // [0.08 0.12 0.16 0.24 0.35]
#define WATER_ABSORPTION_B 0.10   // [0.05 0.08 0.10 0.16 0.24]
#define RAIN_RIPPLES              // Rain splash ripples on flat surfaces and water.
#define WET_SURFACES              // Surfaces darken and gloss up in the rain.


/* ==========================================================================
   7. REFLECTIONS
   ========================================================================== */
#define SSR                       // Screen space reflections (opaque + water).
#define SSR_STEPS 24              // [12 16 24 32 48 64]
#define SSR_REFINE 4              // [2 3 4 6 8] Binary refinement iterations.
#define ROUGH_REFLECTIONS         // Blur reflections based on surface roughness.
#define SKY_REFLECTION_FALLBACK   // Use the sky when a screen space ray misses.


/* ==========================================================================
   8. BLOOM & POST PROCESSING
   ========================================================================== */
#define BLOOM                     // HDR bloom.
#define BLOOM_INTENSITY 1.00      // [0.25 0.50 0.75 1.00 1.50 2.00 3.00]
#define BLOOM_RADIUS 1.0          // [0.5 0.75 1.0 1.5 2.0]

// Tonemap operator: 0=Reinhard 1=ACES(filmic) 2=Uchimura 3=AgX-ish 4=Lottes
#define TONEMAP_OPERATOR 1        // [0 1 2 3 4]
#define AUTO_EXPOSURE             // Eye adaptation.
#define EXPOSURE_SPEED 1.0        // [0.25 0.50 1.0 2.0 4.0]
#define MANUAL_EXPOSURE 1.0       // [0.25 0.50 0.75 1.00 1.25 1.50 2.00] Used when auto exposure is off.
#define EXPOSURE_MIN 0.25         // [0.10 0.15 0.25 0.40 0.60]
#define EXPOSURE_MAX 4.0          // [1.5 2.0 3.0 4.0 6.0 8.0]

// Colour grading.
#define BRIGHTNESS 1.00           // [0.80 0.90 1.00 1.10 1.20]
#define CONTRAST 1.00             // [0.80 0.90 1.00 1.05 1.10 1.20 1.30]
#define SATURATION 1.05           // [0.70 0.85 1.00 1.05 1.10 1.25 1.40]
#define VIBRANCE 1.10             // [0.80 1.00 1.10 1.25 1.50]
#define GAMMA 1.00                // [0.80 0.90 1.00 1.10 1.20]
#define WHITE_BALANCE 6500        // [5000 5500 6000 6500 7000 7500 8000] Target white point (Kelvin).
#define TINT_R 1.00               // [0.90 0.95 1.00 1.05 1.10]
#define TINT_G 1.00               // [0.90 0.95 1.00 1.05 1.10]
#define TINT_B 1.00               // [0.90 0.95 1.00 1.05 1.10]

#define VIGNETTE                  // Darken screen corners.
#define VIGNETTE_STRENGTH 0.35    // [0.15 0.25 0.35 0.50 0.70]

#define SHARPEN                   // Contrast adaptive sharpening.
#define SHARPEN_STRENGTH 0.5      // [0.25 0.5 0.75 1.0]

//#define CHROMATIC_ABERRATION    // Lens colour fringing (optional, off by default).
#define CA_STRENGTH 1.0           // [0.5 1.0 1.5 2.0]

//#define MOTION_BLUR             // Camera + object motion blur (optional).
#define MOTION_BLUR_STRENGTH 0.5  // [0.25 0.5 0.75 1.0]
#define MOTION_BLUR_SAMPLES 6     // [4 6 8 12]

//#define FILM_GRAIN              // Subtle animated grain (optional).
#define FILM_GRAIN_STRENGTH 0.35  // [0.15 0.25 0.35 0.50 0.75]

//#define DOF                     // Depth of field (optional, heavy).
#define DOF_STRENGTH 1.0          // [0.5 1.0 1.5 2.0]


/* ==========================================================================
   9. ANTI-ALIASING
   ========================================================================== */
#define TAA                       // Temporal anti-aliasing (also stabilises noise).
#define TAA_STRENGTH 0.85         // [0.60 0.70 0.80 0.85 0.90 0.95] History blend factor.
//#define FXAA                    // Cheap spatial AA (use if TAA is disabled).


/* ==========================================================================
   10. FOG
   ========================================================================== */
#define ATMOSPHERIC_FOG           // Aerial perspective / distance haze.
#define FOG_DENSITY 1.00          // [0.25 0.50 0.75 1.00 1.50 2.00 3.00]
#define CAVE_FOG                  // Ambient fog inside caves.
#define BORDER_FOG                // Hide the render-distance edge.


/* ==========================================================================
   11. WIND / VEGETATION
   ========================================================================== */
#define WAVING_PLANTS             // Grass, flowers, crops, saplings.
#define WAVING_LEAVES             // Leaf blocks.
#define WAVING_VINES              // Vines, ladders that behave like them.
#define WAVING_WATER_PLANTS       // Kelp, seagrass.
#define WAVING_WATER              // Vertex displacement on the water surface.
#define WIND_STRENGTH 1.00        // [0.25 0.50 0.75 1.00 1.50 2.00]
#define WIND_SPEED 1.00           // [0.25 0.50 0.75 1.00 1.50 2.00]


/* ==========================================================================
   12. EMISSIVE / MATERIAL
   ========================================================================== */
#define EMISSIVE                  // Emissive ores, blocks, mob eyes.
#define EMISSIVE_STRENGTH 1.00    // [0.25 0.50 0.75 1.00 1.50 2.00 3.00]
#define SPECULAR_MAPS             // Respect labPBR specular textures if provided.
#define NORMAL_MAPS               // Respect labPBR / bump normal textures if provided.
#define PARALLAX_DEPTH 0.0        // [0.0 0.10 0.25 0.40 0.60] 0 disables POM (needs height maps).
#define POM_SAMPLES 16            // [8 16 24 32]


/* ==========================================================================
   13. NETHER / END
   ========================================================================== */
#define NETHER_HEAT_HAZE          // Heat distortion above lava.
#define NETHER_SMOKE              // Volumetric ambient smoke.
#define END_PARTICLES             // Floating end particles.


/* ==========================================================================
   14. PERFORMANCE
   ========================================================================== */
#define RENDER_SCALE 1.00         // [0.50 0.60 0.70 0.80 0.90 1.00] Internal resolution multiplier.
#define HALF_RES_VOLUMETRICS      // Compute volumetrics at half resolution then upscale.


/* ==========================================================================
   Derived / internal constants (do not expose in the menu)
   ========================================================================== */

// Map SHADOW_QUALITY -> shadow map resolution.
// NOTE: OptiFine / Iris size the shadow map from a `const int shadowMapResolution`
// declaration (not a #define), so it must be a real const. Same for shadowDistance.
#if   SHADOW_QUALITY == 0
    const int shadowMapResolution = 1024;
#elif SHADOW_QUALITY == 1
    const int shadowMapResolution = 1536;
#elif SHADOW_QUALITY == 2
    const int shadowMapResolution = 2048;
#elif SHADOW_QUALITY == 3
    const int shadowMapResolution = 3072;
#else
    const int shadowMapResolution = 4096;
#endif

// Shadow render distance (read by OptiFine / Iris). Mirrors the user slider.
const float shadowDistance = SHADOW_DISTANCE;

// We rely on manual PCF/PCSS filtering, not hardware shadow comparison.
const bool shadowHardwareFiltering = false;

#endif // BLAZE_SETTINGS_GLSL
