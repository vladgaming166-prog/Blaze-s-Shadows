#version 330 compatibility
/*
====================================================================================
  Blaze's Shadows  -  world1/composite1.fsh   (THE END : fog + particles)
------------------------------------------------------------------------------------
  Soft purple aerial fog plus drifting, twinkling motes that give the void a living,
  dreamlike quality.
====================================================================================
*/
#include "/lib/framebuffer.glsl"
#include "/lib/settings.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/util/spaces.glsl"
#include "/lib/util/noise.glsl"

in vec2 uv;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 outColor;

void main() {
    vec3 color = texture(colortex0, uv).rgb;
    float depth = texture(depthtex0, uv).r;

    vec3 viewPos = screenToView(vec3(uv, depth), gbufferProjectionInverse);
    float dist = length(viewPos);

    // Purple aerial fog on world geometry only.
    if (depth < 1.0) {
        vec3 fog = vec3(0.06, 0.03, 0.12);
        float f = 1.0 - exp(-dist * 0.012 * FOG_DENSITY);
        color = mix(color, fog, saturate(f));
    }

    // ---- Floating End particles --------------------------------------------
#ifdef END_PARTICLES
    vec2 p = uv * vec2(aspectRatio, 1.0) * 12.0;
    for (int layer = 0; layer < 2; layer++) {
        float drift = frameTimeCounter * (0.05 + float(layer) * 0.03);
        vec2 lp = p + vec2(drift, drift * 0.5) + float(layer) * 17.0;
        vec2 cell = floor(lp);
        vec2 f = fract(lp);
        vec2 rnd = hash22(cell + float(layer) * 5.0);
        float d = length(f - rnd);
        float twinkle = 0.5 + 0.5 * sin(frameTimeCounter * 2.0 + rnd.x * 30.0);
        float mote = smoothstep(0.06, 0.0, d) * twinkle;
        color += vec3(0.5, 0.35, 0.7) * mote * 0.25;
    }
#endif

    color *= 1.0 - saturate(blindness + darknessFactor);
    outColor = vec4(max(color, vec3(0.0)), 1.0);
}
