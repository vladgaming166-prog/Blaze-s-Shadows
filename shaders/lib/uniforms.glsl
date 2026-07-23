/*
====================================================================================
  Blaze's Shadows  -  lib/uniforms.glsl
------------------------------------------------------------------------------------
  A single place that declares the uniforms shared by the full-screen (deferred /
  composite / final) programs. Declaring an unused uniform is harmless, so grouping
  them here removes a lot of copy-paste from the individual passes.

  NOTE: `noisetex` is declared in lib/util/noise.glsl to keep noise self-contained,
  so it is intentionally absent here to avoid a double declaration.
====================================================================================
*/
#ifndef BLAZE_UNIFORMS_GLSL
#define BLAZE_UNIFORMS_GLSL

/* ---------- G-buffer / scene samplers ---------- */
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D colortex6;
uniform sampler2D colortex7;

uniform sampler2D depthtex0; // scene depth (with translucents)
uniform sampler2D depthtex1; // scene depth (opaque only)
uniform sampler2D depthtex2; // scene depth (no hand)

/* ---------- Shadow samplers ---------- */
uniform sampler2D   shadowtex0;      // full shadow depth
uniform sampler2D   shadowtex1;      // opaque-only shadow depth
uniform sampler2D   shadowcolor0;    // coloured shadow (stained glass / water)
uniform sampler2D   shadowcolor1;    // extra shadow data (normals / caustics)

/* ---------- Matrices ---------- */
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;

/* ---------- Camera / world state ---------- */
uniform vec3  cameraPosition;
uniform vec3  previousCameraPosition;
uniform vec3  sunPosition;      // view space
uniform vec3  moonPosition;     // view space
uniform vec3  shadowLightPosition; // whichever of sun/moon is up (view space)
uniform vec3  upPosition;       // view space up
uniform vec3  skyColor;
uniform vec3  fogColor;

uniform float sunAngle;         // 0..1 around the day
uniform float rainStrength;     // 0..1
uniform float wetness;          // smoothed rainStrength
uniform float thunderStrength;  // 0..1 (Iris)
uniform float nightVision;
uniform float blindness;
uniform float darknessFactor;
uniform float screenBrightness; // in-game brightness slider
uniform int   isEyeInWater;     // 0 air, 1 water, 2 lava, 3 powder snow
uniform float eyeAltitude;
uniform ivec2 eyeBrightnessSmooth;
uniform int   worldTime;
uniform int   worldDay;
uniform int   moonPhase;
uniform int   heldItemId;
uniform int   heldBlockLightValue;
uniform int   heldItemId2;
uniform int   heldBlockLightValue2;

/* ---------- Frame / viewport ---------- */
uniform float frameTimeCounter;  // seconds since load (wraps)
uniform float frameTime;         // last frame duration
uniform int   frameCounter;      // integer frame index
uniform float aspectRatio;
uniform float viewWidth;
uniform float viewHeight;
uniform float near;
uniform float far;

#endif // BLAZE_UNIFORMS_GLSL
