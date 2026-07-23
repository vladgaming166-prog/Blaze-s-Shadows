#version 330 compatibility
/* Blaze's Shadows - gbuffers_weather.vsh : rain & snow particles. */
out vec4 glcolor;
out vec2 texcoord;
out vec2 lmcoord;
void main() {
    gl_Position = ftransform();
    glcolor  = gl_Color;
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord  = (gl_TextureMatrix[1] * vec4(gl_MultiTexCoord1.xy, 0.0, 1.0)).xy;
}
