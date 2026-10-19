#!/bin/sh
set -eu

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
TESTS_ROOT="$REPO_ROOT/tests"

nvim --clean --headless \
  --cmd "lua package.path = '$TESTS_ROOT/?.lua;' .. package.path" \
  -l "$TESTS_ROOT/run.lua" \
  "$REPO_ROOT" "$TESTS_ROOT" "$@"
