#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"

GODOT_COMMIT=$(jq --raw-output '.godot_commit' ./config.json)
PULL_PATCHES=$(jq --raw-output '.pulls[]' ./config.json)
EMSCRIPTEN_VERSION=$(jq --raw-output '.emscripten_version' ./config.json)

git clone https://github.com/emscripten-core/emsdk
pushd emsdk
  ./emsdk install $EMSCRIPTEN_VERSION
  ./emsdk activate $EMSCRIPTEN_VERSION
  source ./emsdk_env.sh
popd


GODOT_SOURCE_URL="https://github.com/godotengine/godot/archive/${GODOT_COMMIT}.tar.gz"

mkdir -p godot-source
curl -Ls "$GODOT_SOURCE_URL" | tar xz --strip-components=1 -C godot-source

pushd godot-source
  for p in $PULL_PATCHES; do
    curl -L https://github.com/godotengine/godot/pull/$p.diff -o $p.diff
    patch -p1 < $p.diff
  done

  scons platform=web target=template_release dev_mode=yes debug_symbols=no dlink_enabled=yes threads=no
  scons platform=web target=template_debug dev_mode=yes debug_symbols=no dlink_enabled=yes threads=no
popd # godot-source

mkdir -p build
pushd build
  mkdir -p templates
  cp ../godot-source/bin/godot.web.template_debug.wasm32.nothreads.dlink.zip ./templates/web_dlink_nothreads_debug.zip
  cp ../godot-source/bin/godot.web.template_release.wasm32.nothreads.dlink.zip ./templates/web_dlink_nothreads_release.zip

  pushd templates
    for zipfile in web_dlink_nothreads_debug.zip web_dlink_nothreads_release.zip; do
      dir="${zipfile%.zip}"

      mkdir -p $dir
      unzip -o $zipfile -d $dir
      rm $zipfile

      pushd $dir
        for wasm in *.wasm; do
          gzip -k -9 $wasm
          brotli -q 11 $wasm
        done
        zip -r -FS -9 ../$zipfile .
      popd # $dir

      rm -rf $dir
    done
  popd # templates
popd # build
