#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
LUA_BIN=${LUA:-lua5.1}
for profile in classic era retail forever mop; do
    "$LUA_BIN" tests/regression.lua "$profile"
done
