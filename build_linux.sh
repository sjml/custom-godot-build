#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"

GODOT_COMMIT=$(jq --raw-output '.godot_commit' ./config.json)
PULL_PATCHES=$(jq --raw-output '.pulls[]' ./config.json)

GODOT_SOURCE_URL="https://github.com/godotengine/godot/archive/${GODOT_COMMIT}.tar.gz"

mkdir -p godot-source
curl -Ls "$GODOT_SOURCE_URL" | tar xz --strip-components=1 -C godot-source

pushd godot-source
  for p in $PULL_PATCHES; do
    curl -L https://github.com/godotengine/godot/pull/$p.diff -o $p.diff
    patch -p1 < $p.diff
  done

  scons platform=linuxbsd arch=$BUILD_ARCH target=template_release production=yes lto=none accesskit=no angle=no
  scons platform=linuxbsd arch=$BUILD_ARCH target=template_debug   production=yes lto=none accesskit=no angle=no
  strip bin/godot.*
popd # godot-source

mkdir -p build
pushd build
  mkdir -p templates
  cp ../godot-source/bin/godot.linuxbsd.template_release.$BUILD_ARCH ./templates/linux_release.$BUILD_ARCH
  cp ../godot-source/bin/godot.linuxbsd.template_debug.$BUILD_ARCH   ./templates/linux_debug.$BUILD_ARCH
popd # build
