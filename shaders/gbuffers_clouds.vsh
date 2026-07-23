#version 330 compatibility
/*
  Blaze's Shadows - gbuffers_clouds.vsh
  Vanilla clouds are replaced by our ray-marched volumetric clouds in the sky pass.
*/
void main() {
    gl_Position = ftransform();
}
