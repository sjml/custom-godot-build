#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"

GODOT_COMMIT=$(jq --raw-output '.godot_commit' ./config.json)
PULL_PATCHES=$(jq --raw-output '.pulls[]' ./config.json)

GODOT_SOURCE_URL="https://github.com/godotengine/godot/archive/${GODOT_COMMIT}.tar.gz"

rm -rf godot-source
mkdir -p godot-source
curl -Ls "$GODOT_SOURCE_URL" | tar xz --strip-components=1 -C godot-source

pushd godot-source
  for p in $PULL_PATCHES; do
    curl -L https://github.com/godotengine/godot/pull/$p.diff -o $p.diff
    patch -p1 < $p.diff
  done

  # build mac editor (just for me, so things I don't use disabled and only arm64)
  scons platform=macos arch=arm64 target=editor production=yes metal=yes vulkan=no accesskit=no angle=no debug_symbols=yes

  # build export templates for mac
  scons platform=macos arch=arm64 target=template_release production=yes metal=yes vulkan=no accesskit=no angle=no
  scons platform=macos arch=arm64 target=template_debug   production=yes metal=yes vulkan=no accesskit=no angle=no
  strip bin/godot.*
popd # godot-source

rm -rf build
mkdir -p build
pushd build
  mkdir -p templates

  cp -R ../godot-source/misc/dist/macos_tools.app ./Godot-Mod.app
  mkdir ./Godot-Mod.app/Contents/MacOS
  cp -R ../godot-source/bin/godot.macos.editor.arm64 ./Godot-Mod.app/Contents/MacOS/Godot

  cp -R ../godot-source/misc/dist/macos_template.app ./templates/
  mkdir ./templates/macos_template.app/Contents/MacOS
  cp ../godot-source/bin/godot.macos.template_debug.arm64   ./templates/macos_template.app/Contents/MacOS/godot_macos_debug.arm64
  cp ../godot-source/bin/godot.macos.template_release.arm64 ./templates/macos_template.app/Contents/MacOS/godot_macos_release.arm64
  pushd templates
    zip -r -FS -9 ./macos.zip macos_template.app/
    rm -rf macos_template.app
  popd # templates
popd # build

rm -rf godot-source
