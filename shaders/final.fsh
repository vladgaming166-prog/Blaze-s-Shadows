#version 330 compatibility
/*
====================================================================================
  Blaze's Shadows  -  final.fsh   (pass 11: present)
------------------------------------------------------------------------------------
  The last stop. In order:
    optional chromatic aberration + camera motion blur (sample the HDR scene),
    add HDR bloom, apply (auto)exposure, contrast-adaptive sharpen, tonemap to LDR,
    colour grade, gamma-encode, then vignette + film grain.
====================================================================================
*/
#include "/lib/framebuffer.glsl"
#include "/lib/settings.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/util/encoding.glsl"
#include "/lib/util/spaces.glsl"
#include "/lib/util/noise.glsl"
#include "/lib/post/tonemap.glsl"
#include "/lib/post/grade.glsl"

in vec2 uv;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 fragColor;

// Cannot initialise a global from uniforms in GLSL, so use a macro.
#define texel (1.0 / vec2(viewWidth, viewHeight))

// Sample the scene with optional chromatic aberration.
vec3 sampleScene(vec2 coord) {
#ifdef CHROMATIC_ABERRATION
    vec2 dir = (coord - 0.5);
    vec2 off = dir * CA_STRENGTH * 0.0025;
    float r = texture(colortex0, coord + off).r;
    float g = texture(colortex0, coord).g;
    float b = texture(colortex0, coord - off).b;
    return vec3(r, g, b);
#else
    return texture(colortex0, coord).rgb;
#endif
}

#ifdef FXAA
// Lightweight FXAA (edge-aware blend) operating on the HDR scene buffer.
vec3 applyFXAA(vec2 coord) {
    vec3 rgbM = texture(colortex0, coord).rgb;
    float lM = luminance(rgbM);
    float lN = luminance(texture(colortex0, coord + vec2(0.0, texel.y)).rgb);
    float lS = luminance(texture(colortex0, coord - vec2(0.0, texel.y)).rgb);
    float lE = luminance(texture(colortex0, coord + vec2(texel.x, 0.0)).rgb);
    float lW = luminance(texture(colortex0, coord - vec2(texel.x, 0.0)).rgb);
    float lMin = min(lM, min(min(lN, lS), min(lE, lW)));
    float lMax = max(lM, max(max(lN, lS), max(lE, lW)));
    // Blend across the local gradient direction proportional to contrast.
    vec2 dir = vec2(-(lN - lS), (lE - lW));
    float contrast = lMax - lMin;
    if (contrast < 0.05) return rgbM;
    dir = normalize(dir + 1e-4) * texel * 1.5;
    vec3 a = 0.5 * (texture(colortex0, coord + dir).rgb + texture(colortex0, coord - dir).rgb);
    return mix(rgbM, a, saturate(contrast));
}
#endif

// Disk offsets for depth-of-field bokeh.
const vec2 DOF_DISK[12] = vec2[12](
    vec2( 0.0,  1.0), vec2( 0.866,  0.5), vec2( 0.866, -0.5),
    vec2( 0.0, -1.0), vec2(-0.866, -0.5), vec2(-0.866,  0.5),
    vec2( 0.0,  0.5), vec2( 0.433,  0.25), vec2( 0.433, -0.25),
    vec2( 0.0, -0.5), vec2(-0.433, -0.25), vec2(-0.433,  0.25)
);

void main() {
    vec2 coord = uv;
    vec3 color;
    float depth = texture(depthtex0, uv).r;

    // ---- Camera motion blur -------------------------------------------------
#ifdef MOTION_BLUR
    vec3 viewPos = screenToView(vec3(uv, depth), gbufferProjectionInverse);
    vec3 worldPos = mat3(gbufferModelViewInverse) * viewPos
                  + gbufferModelViewInverse[3].xyz + cameraPosition;
    vec3 prevView = (gbufferPreviousModelView * vec4(worldPos - previousCameraPosition, 1.0)).xyz;
    vec4 prevClip = gbufferPreviousProjection * vec4(prevView, 1.0);
    vec2 prevUV = prevClip.xy / prevClip.w * 0.5 + 0.5;
    vec2 velocity = (uv - prevUV) * MOTION_BLUR_STRENGTH;
    velocity = clamp(velocity, vec2(-0.05), vec2(0.05));
    color = vec3(0.0);
    for (int i = 0; i < MOTION_BLUR_SAMPLES; i++) {
        float t = float(i) / float(MOTION_BLUR_SAMPLES - 1) - 0.5;
        color += sampleScene(uv + velocity * t);
    }
    color /= float(MOTION_BLUR_SAMPLES);
#else
  #ifdef FXAA
    color = applyFXAA(coord);
  #else
    color = sampleScene(coord);
  #endif
#endif

    // ---- Depth of field -----------------------------------------------------
#ifdef DOF
    float focusDepth = linearizeDepth(texture(depthtex0, vec2(0.5)).r, near, far);
    float fragDepth  = linearizeDepth(depth, near, far);
    float coc = clamp(abs(fragDepth - focusDepth) / max(fragDepth, 1.0) * DOF_STRENGTH, 0.0, 1.0);
    float radius = coc * 12.0; // max blur radius in texels
    if (radius > 0.75) {
        vec3 acc = color;
        for (int i = 0; i < 12; i++) {
            acc += sampleScene(uv + DOF_DISK[i] * texel * radius);
        }
        color = acc / 13.0;
    }
#endif

    // ---- Contrast-adaptive sharpen (on HDR) --------------------------------
#ifdef SHARPEN
    vec3 n = sampleScene(uv + vec2(0.0, texel.y));
    vec3 s = sampleScene(uv - vec2(0.0, texel.y));
    vec3 e = sampleScene(uv + vec2(texel.x, 0.0));
    vec3 w = sampleScene(uv - vec2(texel.x, 0.0));
    vec3 blur = (n + s + e + w) * 0.25;
    color += (color - blur) * SHARPEN_STRENGTH;
    color = max0(color);
#endif

    // ---- Bloom --------------------------------------------------------------
#ifdef BLOOM
    vec3 bloom = texture(colortex6, uv).rgb;
    color += bloom * BLOOM_INTENSITY * 0.06;
#endif

    // ---- Exposure -----------------------------------------------------------
    float exposure = texture(colortex7, uv).r;
    if (exposure <= 0.0 || exposure > 100.0) exposure = MANUAL_EXPOSURE;
    color *= exposure;

    // ---- Tonemap + grade ----------------------------------------------------
    color = tonemap(color);
    color = colorGrade(color);
    color = linearToSrgb(saturate(color));

    // ---- Vignette -----------------------------------------------------------
#ifdef VIGNETTE
    vec2 d = uv - 0.5;
    float vig = 1.0 - dot(d, d) * VIGNETTE_STRENGTH * 2.2;
    color *= saturate(vig);
#endif

    // ---- Film grain ---------------------------------------------------------
#ifdef FILM_GRAIN
    float grain = hash12(uv * vec2(viewWidth, viewHeight) + frameTimeCounter) - 0.5;
    color += grain * FILM_GRAIN_STRENGTH * 0.06;
#endif

    fragColor = vec4(saturate(color), 1.0);
}
