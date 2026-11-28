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

  python misc/scripts/install_d3d12_sdk_windows.py

  sudo update-alternatives --set x86_64-w64-mingw32-gcc /usr/bin/x86_64-w64-mingw32-gcc-posix
  sudo update-alternatives --set x86_64-w64-mingw32-g++ /usr/bin/x86_64-w64-mingw32-g++-posix

  scons platform=windows arch=x86_64 target=template_release winrt=no production=yes lto=none accesskit=no angle=no
  scons platform=windows arch=x86_64 target=template_debug   winrt=no production=yes lto=none accesskit=no angle=no
popd # godot-source

mkdir -p build
pushd build
  mkdir -p templates

  cp ../godot-source/bin/godot.windows.template_release.x86_64.console.exe ./templates/windows_release_x86_64_console.exe
  cp ../godot-source/bin/godot.windows.template_release.x86_64.exe         ./templates/windows_release_x86_64.exe

  cp ../godot-source/bin/godot.windows.template_debug.x86_64.console.exe ./templates/windows_debug_x86_64_console.exe
  cp ../godot-source/bin/godot.windows.template_debug.x86_64.exe         ./templates/windows_debug_x86_64.exe
popd # build
