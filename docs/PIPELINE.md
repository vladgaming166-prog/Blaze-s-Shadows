# Blaze's Shadows — Render Pipeline

This document describes the data flow and buffer layout so contributors can extend the
pack without spelunking every file.

## Stages (execution order)

```
1.  gbuffers_*        Rasterize the world into the G-buffer (colortex0/1/2).
2.  shadow            Render the scene from the light's POV into the shadow map
                      (+ shadowcolor0 for coloured shadows). Wind is applied here too.
3.  deferred          SSAO + single-bounce SSGI gather  ->  colortex3.
4.  deferred1         Opaque lighting, procedural sky, volumetric clouds, god rays.
                      Reads colortex0/1/2/3 + shadow map, writes lit HDR -> colortex0.
--- translucents ---
5.  gbuffers_water    Forward-shaded water & glass. Samples colortex0 for refraction /
                      background (blending disabled), writes water normal to colortex1.
6.  composite         Screen-space reflections (opaque + water)     -> colortex0.
7.  composite1        Atmospheric / cave / border / underwater fog  -> colortex0.
8.  composite2        TAA resolve (+history colortex5) + auto-exposure (colortex7).
9.  composite3..7     Soft-knee HDR bloom: bright pass + 2x separable Gaussian.
10. final             Bloom composite, exposure, DoF/CA/motion blur, sharpen, tonemap,
                      colour grade, gamma, vignette, film grain -> screen.
```

Per-dimension overrides live in `world-1` (Nether) and `world1` (End); they replace
`deferred1` and `composite1` with dimension-appropriate lighting, sky and fog while
reusing every other root program.

## Render targets

| Buffer      | Format   | Contents |
|-------------|----------|----------|
| colortex0   | RGBA16F  | HDR scene colour (albedo → lit → post) |
| colortex1   | RGBA16   | `.rg` octahedral normal · `.b` packed lightmap · `.a` material id |
| colortex2   | RGBA16F  | `.r` smoothness · `.g` F0/metal · `.b` emission · `.a` subsurface |
| colortex3   | RGBA16F  | SSAO/SSGI (`.rgb` bounce, `.a` AO); reused as bloom scratch |
| colortex4   | RGBA16F  | scratch / reserved for future volumetrics |
| colortex5   | RGBA16F  | **persistent** TAA history (also read by SSGI) |
| colortex6   | RGBA16F  | bloom mip / blur target |
| colortex7   | RGBA16F  | **persistent** auto-exposure store |

`shadowtex0` (all occluders), `shadowtex1` (opaque only) and `shadowcolor0` (light tint)
carry the shadow data. `noisetex` is the auto-generated tiling noise texture.

## Coordinate spaces

See `lib/util/spaces.glsl`. The pack works in world/scene (player-relative) space for
lighting and fog, view space for SSR/SSAO ray marching, and screen space for sampling.

## Material ids (`colortex1.a`)

Defined in `lib/material/ids.glsl`: opaque, foliage, leaves, emissive, water, translucent,
hand, entity, unlit. The deferred pass branches on these (e.g. unlit passthrough, hand
gets no world shadow, foliage/leaves get subsurface scattering).

## Adding a setting

1. Add the `#define` (with slider metadata comment) to `lib/settings.glsl`.
2. Reference it in the relevant program / library guarded by `#ifdef`.
3. Expose it in `shaders/shaders.properties` (a `screen.*` entry, and `sliders` if numeric).
4. Add a friendly label to `shaders/lang/en_US.lang` (and translations if you can).
