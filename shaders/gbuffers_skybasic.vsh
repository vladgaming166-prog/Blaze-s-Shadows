#version 330 compatibility
/*
  Blaze's Shadows - gbuffers_skybasic.vsh
  The vanilla sky gradient. We recompute the whole sky procedurally in the deferred
  stage (depth == far), so this pass only needs to establish position.
*/
void main() {
    gl_Position = ftransform();
}
