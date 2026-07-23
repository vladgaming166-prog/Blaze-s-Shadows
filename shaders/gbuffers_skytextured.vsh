#version 330 compatibility
/*
  Blaze's Shadows - gbuffers_skytextured.vsh
  Vanilla sun/moon/star textures. Suppressed in the overworld (we draw our own
  celestial bodies in the deferred pass). Dimension overrides may reinstate it.
*/
void main() {
    gl_Position = ftransform();
}
