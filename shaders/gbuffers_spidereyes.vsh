#version 330 compatibility
/* Blaze's Shadows - gbuffers_spidereyes.vsh : additive emissive mob eyes. */
out vec4 glcolor;
out vec2 texcoord;
void main() {
    gl_Position = ftransform();
    glcolor = gl_Color;
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}
