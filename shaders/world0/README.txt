Blaze's Shadows - world0 (Overworld)

Programs placed in the shaders/ root apply to ALL dimensions, and the Overworld uses
them directly, so there are no per-program overrides needed here. This folder is kept
so the dimension layout (world0 / world-1 / world1) is explicit and so Overworld-only
overrides can be dropped in later without restructuring.

If you want to override a program for the Overworld only (e.g. a special deferred1.fsh),
add it in this folder using the same file name as the root program; it will take
precedence over the root version for the Overworld.
