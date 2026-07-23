/*
====================================================================================
  Blaze's Shadows  -  lib/util/constants.glsl
------------------------------------------------------------------------------------
  Mathematical and physical constants used throughout the pack. Keeping them in one
  place avoids the classic "one file uses 3.1415, another 3.14159265" drift.
====================================================================================
*/
#ifndef BLAZE_CONSTANTS_GLSL
#define BLAZE_CONSTANTS_GLSL

const float PI        = 3.14159265358979323846;
const float TAU       = 6.28318530717958647692; // 2*PI
const float HALF_PI   = 1.57079632679489661923;
const float INV_PI    = 0.31830988618379067154; // 1/PI
const float RCP_TAU   = 0.15915494309189533577; // 1/TAU
const float SQRT2     = 1.41421356237309504880;
const float GOLDEN    = 2.39996322972865332;    // golden angle (radians)
const float EPSILON   = 1e-6;

// A tiny value used to avoid divide-by-zero without noticeably biasing results.
const float FUDGE     = 1e-4;

// Approximate world-space radius of the atmosphere shell used by the sky model.
const float ATMOSPHERE_INNER = 6371e3;  // planet radius (m)
const float ATMOSPHERE_OUTER = 6471e3;  // atmosphere top (m)

// Rayleigh / Mie scattering coefficients (per metre) tuned for a Minecraft-y look.
const vec3  RAYLEIGH_COEFF = vec3(5.8e-6, 13.5e-6, 33.1e-6);
const float MIE_COEFF      = 21e-6;

#endif // BLAZE_CONSTANTS_GLSL
