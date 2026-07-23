#version 330 compatibility
/*
====================================================================================
  Blaze's Shadows  -  composite2.fsh   (pass 5: TAA resolve + auto-exposure)
------------------------------------------------------------------------------------
  Temporal anti-aliasing: reproject last frame using the previous camera matrices,
  clamp the history to the current 3x3 neighbourhood colour box (kills ghosting),
  and blend. The resolved HDR colour is written to colortex0 and to the history
  buffer colortex5 (also used by SSGI next frame).

  Auto-exposure: estimate average scene luminance from a sparse grid and smoothly
  adapt a stored exposure value in colortex7 (persistent), used by the final pass.
====================================================================================
*/
#include "/lib/framebuffer.glsl"
#include "/lib/settings.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/util/spaces.glsl"
#include "/lib/util/math.glsl"

in vec2 uv;

/* DRAWBUFFERS:057 */
layout(location = 0) out vec4 outColor;   // colortex0 : resolved scene
layout(location = 1) out vec4 outHistory; // colortex5 : history
layout(location = 2) out vec4 outExposure;// colortex7 : exposure store

// Cannot initialise a global from uniforms in GLSL, so use a macro.
#define texel (1.0 / vec2(viewWidth, viewHeight))

void main() {
    vec3 current = texture(colortex0, uv).rgb;

#ifdef TAA
    // Reproject into the previous frame.
    float depth = texture(depthtex0, uv).r;
    vec3 viewPos = screenToView(vec3(uv, depth), gbufferProjectionInverse);
    vec3 scenePos = mat3(gbufferModelViewInverse) * viewPos + gbufferModelViewInverse[3].xyz;
    vec3 worldPos = scenePos + cameraPosition;

    vec3 prevPlayer = worldPos - previousCameraPosition;
    vec3 prevView = (gbufferPreviousModelView * vec4(prevPlayer, 1.0)).xyz;
    vec4 prevClip = gbufferPreviousProjection * vec4(prevView, 1.0);
    vec2 prevUV = prevClip.xy / prevClip.w * 0.5 + 0.5;

    vec3 resolved = current;
    if (all(greaterThanEqual(prevUV, vec2(0.0))) && all(lessThanEqual(prevUV, vec2(1.0)))) {
        vec3 history = texture(colortex5, prevUV).rgb;

        // Neighbourhood colour-box clamp.
        vec3 mn = current, mx = current;
        for (int y = -1; y <= 1; y++)
        for (int x = -1; x <= 1; x++) {
            vec3 c = texture(colortex0, uv + vec2(x, y) * texel).rgb;
            mn = min(mn, c); mx = max(mx, c);
        }
        history = clamp(history, mn, mx);

        // Reduce blending when the camera moves fast (less trailing).
        float velocity = length((prevUV - uv) * vec2(viewWidth, viewHeight));
        float blend = TAA_STRENGTH * saturate(1.0 - velocity * 0.02);
        resolved = mix(current, history, blend);
    }
    current = resolved;
#endif

    outColor   = vec4(current, 1.0);
    outHistory = vec4(current, 1.0);

    // ---- Auto-exposure ------------------------------------------------------
    // Geometric-mean luminance over a coarse grid (kept small for performance;
    // every pixel computes the same value so the store is uniform for `final`).
    float avgLum = 0.0;
    const int G = 4;
    for (int y = 0; y < G; y++)
    for (int x = 0; x < G; x++) {
        vec2 g = (vec2(x, y) + 0.5) / float(G);
        avgLum += log(luminance(texture(colortex0, g).rgb) + 1e-4);
    }
    avgLum = exp(avgLum / float(G * G)); // geometric mean is more stable

#ifdef AUTO_EXPOSURE
    float target = clamp(0.35 / max(avgLum, 1e-3), EXPOSURE_MIN, EXPOSURE_MAX);
    float prev = texture(colortex7, uv).r;
    if (prev <= 0.0 || prev > 100.0) prev = target; // initialise
    float rate = saturate(frameTime * EXPOSURE_SPEED * 1.5);
    float exposure = mix(prev, target, rate);
#else
    float exposure = MANUAL_EXPOSURE;
#endif
    outExposure = vec4(exposure, avgLum, 0.0, 1.0);
}
