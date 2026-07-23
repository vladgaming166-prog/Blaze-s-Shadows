#version 330 compatibility
/*
  Blaze's Shadows - gbuffers_clouds.fsh
  Discard the vanilla cloud plane so our volumetric clouds are the only ones visible.
*/
void main() {
    discard;
}
