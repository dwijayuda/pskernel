#!/usr/bin/env bash
set -euo pipefail
# Experimental source-only C++ runtime/kernel compilation smoke. This does
# not build Lean Standard, create a kernel launcher, or admit any proofs.
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
upstream="${PSC0_LEAN_CPP_SMOKE_SOURCE:-$RUNNER_TEMP/psc0-lean435-cpp-src}"
build="${PSC0_LEAN_CPP_SMOKE_BUILD:-$RUNNER_TEMP/psc0-lean435-cpp-build}"
expected='eb6cafb7290e8bd5f2937522d8d804f58f02bafc'
[[ "$(emcc --version | head -n1)" == *'6.0.9'* ]] || {
  echo 'PSC0_CPP_SMOKE: wrong Emscripten version' >&2; exit 1;
}
for tool in git cmake emcc em++ emar node; do
  command -v "$tool" >/dev/null || { echo "PSC0_CPP_SMOKE: missing $tool" >&2; exit 1; }
done
mkdir -p "$upstream"
git -C "$upstream" init -q
git -C "$upstream" remote add origin https://github.com/leanprover/lean4.git
git -C "$upstream" fetch --depth 1 origin "$expected"
git -C "$upstream" checkout -q --detach FETCH_HEAD
test "$(git -C "$upstream" rev-parse HEAD)" = "$expected"
node "$here/apply-lean435-compat.mjs" "$upstream"
node "$here/verify-lean435-runtime.mjs" "$upstream"
git -C "$upstream" diff --check

toolchain="$(dirname "$(command -v emcc)")/cmake/Modules/Platform/Emscripten.cmake"
test -f "$toolchain"
cmake -S "$upstream/src" -B "$build" -G 'Unix Makefiles' \
  -DCMAKE_TOOLCHAIN_FILE="$toolchain" \
  -DCMAKE_BUILD_TYPE=Release \
  -DSTAGE=1 \
  -DLEAN_SOURCE_DIR="$upstream/src" \
  -DLEAN_BINARY_DIR="$build" \
  -DMULTI_THREAD=OFF -DUSE_GMP=OFF -DUSE_MIMALLOC=OFF \
  -DUSE_LAKE=OFF -DMMAP=OFF -DLLVM=OFF -DCCACHE=OFF \
  -DWFAIL=OFF -DINSTALL_LICENSE=OFF
# Build target-only C++ libs before any expensive bootstrapped Lean libraries.
cmake --build "$build" --target leanrt leancpp_1 -j2
test -s "$build/lib/lean/libleanrt.a"
test -s "$build/lib/temp/libleancpp_1.a"
echo 'PSC0_LEAN435_CPP_SMOKE_PASS: actual wasm32 runtime and C++ kernel archives compiled'
