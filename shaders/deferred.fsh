#version 330 compatibility
/*
====================================================================================
  Blaze's Shadows  -  deferred.fsh   (pass 1: ambient occlusion + GI gather)
------------------------------------------------------------------------------------
  Computes screen-space ambient occlusion (Alchemy-style horizon estimate) and a
  cheap single-bounce screen-space GI that samples last frame's lit colour around
  the pixel. Results land in colortex3 (.rgb = bounced light, .a = AO) and are read
  back by the main lighting pass.
====================================================================================
*/
#include "/lib/framebuffer.glsl"
#include "/lib/settings.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/util/encoding.glsl"
#include "/lib/util/spaces.glsl"
#include "/lib/util/noise.glsl"

in vec2 uv;

/* DRAWBUFFERS:3 */
layout(location = 0) out vec4 outAOGI;

vec3 getViewPos(vec2 texel, float depth) {
    return screenToView(vec3(texel, depth), gbufferProjectionInverse);
}

void main() {
    float depth = texture(depthtex1, uv).r;

    // Sky / hand: nothing to occlude.
    if (depth >= 1.0) { outAOGI = vec4(0.0, 0.0, 0.0, 1.0); return; }

    vec4 geo = texture(colortex1, uv);
    vec3 worldNormal = decodeNormal(geo.rg);
    vec3 viewNormal = normalize(mat3(gbufferModelView) * worldNormal);
    vec3 viewPos = getViewPos(uv, depth);

    float dither = interleavedGradient(gl_FragCoord.xy, float(frameCounter));

    float ao = 1.0;
    vec3 gi = vec3(0.0);

#ifdef SSAO
    float occlusion = 0.0;
    float radius = SSAO_RADIUS;
    // Screen-space radius shrinks with distance so world-space radius stays constant.
    float projScale = radius / max(-viewPos.z, 0.1);
    const int N = SSAO_SAMPLES;
    float giWeight = 0.0;
    for (int i = 0; i < N; i++) {
        // Spiral sampling pattern rotated per pixel.
        float angle = (float(i) + dither) * GOLDEN;
        float r = sqrt((float(i) + 0.5) / float(N));
        vec2 offset = vec2(cos(angle), sin(angle)) * r * projScale;
        offset.x /= aspectRatio;

        vec2 sampUV = uv + offset;
        if (any(lessThan(sampUV, vec2(0.0))) || any(greaterThan(sampUV, vec2(1.0)))) continue;

        float sd = texture(depthtex1, sampUV).r;
        vec3 sampPos = getViewPos(sampUV, sd);
        vec3 diff = sampPos - viewPos;
        float dist = length(diff);
        // Alchemy AO horizon term with a range check.
        float rangeCheck = saturate(1.0 - (dist - radius) / radius);
        float ndl = max(dot(viewNormal, diff / max(dist, 1e-3)) - 0.02, 0.0);
        occlusion += ndl / (dist * dist + 0.05) * rangeCheck;

#ifdef SSGI
        // Gather bounced light from last frame's colour buffer.
        if (dist < radius * 2.0 && ndl > 0.0) {
            // Clamp guards against uninitialised history on the very first frames.
            vec3 sampCol = clamp(texture(colortex5, sampUV).rgb, vec3(0.0), vec3(8.0));
            gi += sampCol * ndl * rangeCheck;
            giWeight += 1.0;
        }
#endif
    }
    occlusion = occlusion * (radius / float(N)) * 2.0 * SSAO_STRENGTH;
    ao = saturate(1.0 - occlusion);

#ifdef SSGI
    if (giWeight > 0.0) gi = gi / giWeight * SSGI_STRENGTH;
#endif
#endif // SSAO

    outAOGI = vec4(gi, ao);
}
