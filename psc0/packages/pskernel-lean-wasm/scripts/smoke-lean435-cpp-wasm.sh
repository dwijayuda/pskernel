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

# This is a second, strictly diagnostic boundary: link the REAL official C++
# kernel/runtime archives to a standalone wasm32 executable and verify startup
# and a kernel-expression constructor. It is NOT a proof-admissions checker.
cat > "$build/lean_kernel_link_probe.cpp" <<'CPP'
#include <cstdio>
#include "kernel/init_module.h"
#include "kernel/expr.h"
#include "kernel/level.h"

extern "C" void lean_initialize();

int main() {
    lean_initialize();
    lean::expr zeroSort = lean::mk_sort(lean::mk_level_zero());
    if (!lean::is_sort(zeroSort) || !lean::sort_level(zeroSort).is_zero())
        return 7;
    std::puts("PSC0_LEAN435_WASM_CPP_KERNEL_LINK_AND_EXPR: PASS");
    return 0;
}
CPP
em++ -O2 -fwasm-exceptions -sALLOW_MEMORY_GROWTH=1 -sENVIRONMENT=node \
  -sEXIT_RUNTIME=1 \
  -I"$upstream/src" -I"$upstream/src/include" -I"$build/include" \
  "$build/lean_kernel_link_probe.cpp" \
  "$build/lib/temp/libleancpp_1.a" "$build/lib/lean/libleanrt.a" \
  -lnodefs.js -lstdc++ -o "$build/lean-kernel-link-probe.cjs"
test -s "$build/lean-kernel-link-probe.wasm"
output="$(node "$build/lean-kernel-link-probe.cjs")"
test "$output" = 'PSC0_LEAN435_WASM_CPP_KERNEL_LINK_AND_EXPR: PASS'
node -e '
const fs=require("node:fs");
const b=fs.readFileSync(process.argv[1]);
if(b.subarray(0,4).toString("hex")!=="0061736d")process.exit(1);
const m=new WebAssembly.Module(b);
if(![...WebAssembly.Module.exports(m),...WebAssembly.Module.imports(m)]
  .some(e=>e.kind==="memory"))process.exit(1);
console.log("PSC0_LEAN435_WASM_CPP_KERNEL_LINEAR_MEMORY: PASS");
' "$build/lean-kernel-link-probe.wasm"
echo 'PSC0_LEAN435_CPP_SMOKE_COMPLETE: C++ archives, Wasm linking and startup PASS'
