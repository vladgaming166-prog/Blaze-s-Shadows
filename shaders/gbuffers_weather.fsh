#version 330 compatibility
/*
  Blaze's Shadows - gbuffers_weather.fsh
  Rain streaks and snowflakes. Dimmed in caves (low sky light) and tinted slightly by
  the fog colour so precipitation blends with the atmosphere.
*/
#include "/lib/framebuffer.glsl"
#include "/lib/util/math.glsl"

uniform sampler2D gtexture;
uniform vec3 fogColor;
uniform float alphaTestRef;

in vec4 glcolor;
in vec2 texcoord;
in vec2 lmcoord;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 outColor;

void main() {
    vec4 tex = texture(gtexture, texcoord) * glcolor;
    if (tex.a < alphaTestRef) discard;
    // Fade with sky light and tint toward the fog colour for cohesion.
    float sky = saturate(lmcoord.y * 1.2);
    tex.rgb = mix(tex.rgb, fogColor, 0.35) * (0.4 + 0.6 * sky);
    tex.a *= 0.6;
    outColor = tex;
}
