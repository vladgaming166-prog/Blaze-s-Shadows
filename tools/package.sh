#!/usr/bin/env bash
# ====================================================================================
#  Blaze's Shadows - package.sh
#  Builds a ready-to-install shaderpack zip whose root contains `shaders/` (+ pack.png).
# ====================================================================================
set -euo pipefail

cd "$(dirname "$0")/.."   # repo root

NAME="BlazesShadows"
OUT="${NAME}.zip"

echo "Packaging ${OUT} ..."
rm -f "${OUT}"

# The zip must contain the shaders/ folder at its root for Iris/OptiFine to detect it.
zip -r -q "${OUT}" \
    shaders \
    pack.png \
    README.md \
    LICENSE \
    CHANGELOG.md \
    -x "*/.DS_Store" "*/Thumbs.db"

echo "Done -> ${OUT}"
echo "Drop it into .minecraft/shaderpacks and select it in-game."
