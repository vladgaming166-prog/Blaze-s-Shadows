/*
====================================================================================
  Blaze's Shadows  -  lib/util/spaces.glsl
------------------------------------------------------------------------------------
  Coordinate-space conversions. These are the workhorses of any deferred pipeline:
  given a screen pixel + depth we can travel to view space, world/player space, and
  back again for reprojection.

  Conventions used across the pack:
    screen space   : uv in [0,1], depth in [0,1] (gl_FragCoord.z style)
    NDC            : [-1,1] cube
    view space     : camera at origin, -Z forward (OpenGL)
    scene/player   : world space relative to the camera (feet position)
    world space    : scene space + cameraPosition

  All functions take the relevant matrix explicitly so the header stays uniform-free
  and can be included anywhere.
====================================================================================
*/
#ifndef BLAZE_SPACES_GLSL
#define BLAZE_SPACES_GLSL

// screen (uv + depth, all [0,1]) -> NDC [-1,1]
vec3 screenToNDC(vec3 screenPos) {
    return screenPos * 2.0 - 1.0;
}

// NDC -> screen
vec3 ndcToScreen(vec3 ndc) {
    return ndc * 0.5 + 0.5;
}

// screen -> view space, using the inverse projection matrix.
vec3 screenToView(vec3 screenPos, mat4 projInverse) {
    vec3 ndc = screenToNDC(screenPos);
    vec4 tmp = projInverse * vec4(ndc, 1.0);
    return tmp.xyz / tmp.w;
}

// view -> screen, using the projection matrix.
vec3 viewToScreen(vec3 viewPos, mat4 proj) {
    vec4 clip = proj * vec4(viewPos, 1.0);
    vec3 ndc = clip.xyz / clip.w;
    return ndcToScreen(ndc);
}

// view -> scene (player) space using the inverse model-view matrix.
vec3 viewToScene(vec3 viewPos, mat4 mvInverse) {
    return (mvInverse * vec4(viewPos, 1.0)).xyz;
}

// scene -> view space.
vec3 sceneToView(vec3 scenePos, mat4 modelView) {
    return (modelView * vec4(scenePos, 1.0)).xyz;
}

// Directions ignore translation, so use the 3x3 part only.
vec3 viewToSceneDir(vec3 dir, mat4 mvInverse) { return mat3(mvInverse) * dir; }
vec3 sceneToViewDir(vec3 dir, mat4 modelView) { return mat3(modelView) * dir; }

// Linearise the hardware depth buffer value into a positive view-space distance.
float linearizeDepth(float depth, float near, float far) {
    return (near * far) / (far - depth * (far - near));
}

// Fast linear depth that only needs the two projection constants.
// near/far encoded as: A = far/(far-near), B = far*near/(near-far)
float linearizeDepthFast(float depth, float A, float B) {
    return B / (depth - A);
}

#endif // BLAZE_SPACES_GLSL
