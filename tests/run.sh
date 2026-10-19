#!/bin/sh
set -eu

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
BUILD_ROOT=$(mktemp -d)
PLUGIN_BUILD_ROOT="$BUILD_ROOT/plugin"
TESTS_BUILD_ROOT="$BUILD_ROOT/tests"

trap 'rm -rf "$BUILD_ROOT"' EXIT

build_teal() {
  if ! output=$(cd "$1" && ${CYAN:-cyan} build -q -b "$2" 2>&1); then
    printf 'Teal build failed in %s:\n%s\n' "$1" "$output"
    exit 1
  fi
}

build_teal "$REPO_ROOT" "$PLUGIN_BUILD_ROOT/lua"
build_teal "$REPO_ROOT/tests" "$TESTS_BUILD_ROOT"

nvim --clean --headless \
  --cmd "lua package.path = '$TESTS_BUILD_ROOT/?.lua;' .. package.path" \
  -l "$TESTS_BUILD_ROOT/run.lua" \
  "$REPO_ROOT" "$PLUGIN_BUILD_ROOT" "$TESTS_BUILD_ROOT" "$@"
