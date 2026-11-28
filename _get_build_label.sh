#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"

GODOT_COMMIT=$(jq -r '.godot_commit' config.json)
EMSCRIPTEN_VERSION=$(jq -r '.emscripten_version' config.json)

# if there's more than 3 PRs getting patched in,
#   just hash them so the filename doesn't get too long
NUM_PULLS=$(jq -r '.pulls | length' config.json)
if [ "$NUM_PULLS" -eq 0 ]; then
  PATCHES="nopatches"
elif [ "$NUM_PULLS" -le 3 ]; then
  PATCHES=$(jq -r '.pulls | map("pr" + tostring) | join("+")' config.json)
else
  PATCH_HASH=$(jq -r '.pulls | map(tostring) | join(",")' config.json | sha256sum | cut -c1-8)
  PATCHES="prhash${PATCH_HASH}"
fi

ZIP_NAME="godot-custom-${GODOT_COMMIT}+${PATCHES}-emsdk${EMSCRIPTEN_VERSION}"

echo $ZIP_NAME
