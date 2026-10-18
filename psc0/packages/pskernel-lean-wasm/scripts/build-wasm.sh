#!/usr/bin/env bash
set -euo pipefail
# The repository root may pin an older Lean toolchain. Never inherit it for
# the 4.35.0 cross-build, even when called from the checkout root.
export ELAN_TOOLCHAIN='leanprover/lean4:v4.35.0'
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
package_root="$(cd "$script_dir/.." && pwd)"
psc0="$(cd "$package_root/../.." && pwd)"
build_root="${PSC_LEAN_WASM_BUILD_ROOT:-$package_root/.wasm-build}"
lean_source="$build_root/lean4-src"
lean_build="$build_root/lean4-build"
stage1="$lean_build/stage1"
target_sysroot="$stage1/lib/lean"
stage1_leanc="$stage1/leanc.sh"
stage0_lean="$lean_build/stage0/bin/lean"
overlay="$build_root/overlay"
src="$overlay/src"
oleans="$overlay/olean"
generated="$overlay/c"
objects="$overlay/obj"
closure="$overlay/closure.json"
output="$package_root/wasm"
lean_commit="eb6cafb7290e8bd5f2937522d8d804f58f02bafc"
for tool in git cmake make clang clang++ emcc em++ emar lean node; do
  command -v "$tool" >/dev/null || { echo "missing tool: $tool" >&2; exit 1; }
done
echo "PSC0_WASM_TOOLCHAIN: ELAN_TOOLCHAIN=$ELAN_TOOLCHAIN lean=$(lean --version | head -1)"
test "$(lean --githash | tr -d '\r\n')" = "$lean_commit" || {
  echo "wrong Lean toolchain (expected 4.35.0 at $lean_commit)" >&2; exit 1;
}
emversion="$(emcc --version | head -1)"
[[ "$emversion" == *'6.0.9'* ]] || { echo "requires Emscripten 6.0.9: $emversion" >&2; exit 1; }
test -x /usr/bin/i386-linux-gnu-pkg-config || { echo 'missing i386 pkg-config' >&2; exit 1; }
toolchain="$(dirname "$(command -v emcc)")/cmake/Modules/Platform/Emscripten.cmake"
test -f "$toolchain" || { echo "missing $toolchain" >&2; exit 1; }

# The build checkout is ignored and is NEVER the PSC0 working tree.
mkdir -p "$build_root"
if [[ ! -d "$lean_source/.git" ]]; then
  mkdir -p "$lean_source"
  git -C "$lean_source" init -q
  git -C "$lean_source" remote add origin https://github.com/leanprover/lean4.git
fi
test "$(git -C "$lean_source" remote get-url origin)" = 'https://github.com/leanprover/lean4.git'
git -C "$lean_source" fetch --depth 1 origin "$lean_commit"
git -C "$lean_source" checkout -q --detach FETCH_HEAD
test "$(git -C "$lean_source" rev-parse HEAD)" = "$lean_commit"
git -C "$lean_source" reset -q --hard "$lean_commit"
git -C "$lean_source" clean -q -fdx
node "$script_dir/apply-lean435-compat.mjs" "$lean_source"
node "$script_dir/verify-lean435-runtime.mjs" "$lean_source"
for helper in "$lean_source/src/bin/leanmake" "$lean_source/src/bin/leanc.in"; do
  test -f "$helper" || { echo "upstream helper missing $helper" >&2; exit 1; }
  chmod +x "$helper"
done

# Retain only a cryptographically sealed same-toolchain bootstrap. A stage1
# cache is *not* evidence that the kernel accepts proofs. Every request must
# still pass current native/Wasm parity and the exact artifact release gates.
rm -rf "$overlay" "$output"
mkdir -p "$src" "$oleans" "$generated" "$objects" "$output"
cache_record="$lean_build/.psc0-stage1-cache-manifest.json"
if [[ -f "$cache_record" ]]; then
  node "$script_dir/stage1-cache.mjs" verify "$lean_build"
  echo "PSC0_WASM_STAGE1_CACHE_REUSED: pinned and hash-verified"
else
  # A build without a sealed manifest must start clean, never assume that
  # incomplete or mismatched cached CMake outputs are a valid Lean toolchain.
  rm -rf "$lean_build"
  mkdir -p "$lean_build"
  # Follow the old proven native i386 stage0 / Emscripten wasm32 stage1.
  cmake -S "$lean_source" -B "$lean_build" -G 'Unix Makefiles' \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER_WORKS=1 \
    -DCMAKE_AR="$(command -v emar)" \
    -DCMAKE_TOOLCHAIN_FILE="$toolchain" \
    -DSTAGE0_USE_GMP=OFF \
    -DSTAGE0_LEAN_EXTRA_CXX_FLAGS='-m32 -msse2 -mfpmath=sse -DLEAN_DEFAULT_THREAD_STACK_SIZE=8388608' \
    -DSTAGE0_LEANC_OPTS='-m32 -msse2 -mfpmath=sse' \
    -DSTAGE0_CMAKE_CXX_COMPILER=clang++ \
    -DSTAGE0_CMAKE_C_COMPILER=clang \
    -DSTAGE0_CMAKE_EXECUTABLE_SUFFIX='' \
    -DSTAGE0_MMAP=OFF \
    -DSTAGE0_CMAKE_LIBRARY_PATH=/usr/lib/i386-linux-gnu/ \
    -DSTAGE0_PKG_CONFIG_EXECUTABLE=/usr/bin/i386-linux-gnu-pkg-config \
    -DMULTI_THREAD=OFF -DUSE_GMP=OFF -DUSE_MIMALLOC=OFF \
    -DUSE_LAKE=OFF -DMMAP=OFF -DLLVM=OFF -DCCACHE=OFF -DWFAIL=OFF \
    -DLEAN_INSTALL_SUFFIX=-linux_wasm32
  
  echo "PSC0_WASM_CROSS_BUILD_STAGE0_BEGIN: native i386 Lean bootstrap"
  cmake --build "$lean_build" --target stage1-configure -j2
  echo "PSC0_WASM_CROSS_BUILD_STAGE0_CONFIGURED"
  test -x "$stage0_lean" || { echo 'native i386 stage0 missing' >&2; exit 1; }
  mkdir -p "$target_sysroot/Init" "$target_sysroot/Std" "$target_sysroot/Lean"
  LEAN_PATH="$target_sysroot" "$stage0_lean" --deps "$lean_source/src/Lean.lean"
  for helper in "$stage1/bin/leanmake" "$stage1_leanc"; do
    if [[ -f "$helper" ]]; then chmod +x "$helper"; fi
  done
  echo "PSC0_WASM_CROSS_BUILD_STAGE1_BEGIN: target compatible Init/Std/Lean and official C++ kernel"
  cmake --build "$stage1" --target make_stdlib leanrt leancpp_1 -j2
  echo "PSC0_WASM_CROSS_BUILD_STAGE1_LIBRARIES_COMPILED"
  node "$script_dir/stage1-cache.mjs" seal "$lean_build"
fi
test -x "$stage0_lean" || { echo 'native i386 stage0 missing' >&2; exit 1; }
test -f "$target_sysroot/Lean.olean"
test -f "$stage1/lib/temp/libleancpp_1.a"
test -f "$stage1/lib/lean/libleanrt.a"
test -f "$stage1/lib/lean/libInit.a"
test -f "$stage1/lib/lean/libStd.a"
test -f "$stage1/lib/lean/libLean.a"
chmod +x "$stage1_leanc"
LEAN_PATH="$target_sysroot" "$stage0_lean" --deps "$lean_source/src/Lean.lean"

node "$script_dir/plan-closure.mjs" "$psc0" "$src" "$closure"
echo "PSC0_WASM_PROVIDER_SOURCE_CLOSURE_COMPLETE"
mapfile -t modules < <(node -e 'for(const m of require(process.argv[1]).modules)console.log(m.module)' "$closure")
test "${#modules[@]}" -gt 5 || { echo 'incomplete PSC0 import closure' >&2; exit 1; }
(
  cd "$src"
  export LEAN_PATH="$oleans:$target_sysroot"
  export LEAN_ABORT_ON_PANIC=1
  for module in "${modules[@]}"; do
    file="${module//.//}"
    mkdir -p "$(dirname "$oleans/$file")" "$(dirname "$generated/$file")"
    echo "PSC0_WASM35_PROVIDER_C_EMIT $module"
    "$stage0_lean" -o "$oleans/$file.olean" -i "$oleans/$file.ilean" \
      --c="$generated/$file.c.tmp" "$file.lean"
    mv "$generated/$file.c.tmp" "$generated/$file.c"
  done
)
echo "PSC0_WASM_PROVIDER_LEAN_C_EMISSION_COMPLETE"
mapfile -d '' cfiles < <(find "$generated" -type f -name '*.c' -print0 | sort -z)
test "${#cfiles[@]}" -eq "${#modules[@]}" || {
  echo 'missing emitted C for provider import closure' >&2; exit 1;
}
object_files=()
count=0
for f in "${cfiles[@]}"; do
  object="$objects/$count.o"
  "$stage1_leanc" -O3 -c "$f" -o "$object"
  object_files+=("$object")
  count=$((count+1))
done

echo "PSC0_WASM_PROVIDER_TARGET_OBJECTS_COMPILED count=${#object_files[@]}"
# Kernel-only static link; no Lean shell/main global initializer, host-native
# .olean, or previous PSC2 runtime artifacts enter the Wasm binary.
LEAN_CC="$(command -v em++)" "$stage1_leanc" \
  "${object_files[@]}" -L"$stage1/lib/temp" -lleancpp_1 \
  -lInit -lStd -lLean -lnodefs.js -lleanrt -lstdc++ -O3 \
  -sENVIRONMENT=node -sEXIT_RUNTIME=1 \
  -o "$output/pskernel-lean.cjs"
echo "PSC0_WASM_KERNEL_LINK_COMPLETE: checking wasm32 binary"
test -s "$output/pskernel-lean.wasm"
test -s "$output/pskernel-lean.cjs"
node -e '
const fs=require("node:fs");
const b=fs.readFileSync(process.argv[1]);
const m=new WebAssembly.Module(b);
if(b.subarray(0,4).toString("hex")!=="0061736d" ||
  ![...WebAssembly.Module.imports(m),...WebAssembly.Module.exports(m)].some(x=>x.kind==="memory"))
  process.exit(1);
' "$output/pskernel-lean.wasm"
node -e '
const p=JSON.parse(require("node:child_process").execFileSync(process.execPath,
 [process.argv[1],"--health"],{encoding:"utf8",timeout:180000}));
if(p.status!=="ok" || p.leanVersion!=="4.35.0" ||
 p.leanCommit!=="eb6cafb7290e8bd5f2937522d8d804f58f02bafc" ||
 p.profile!=="pscv0-v7.2")process.exit(1);
' "$output/pskernel-lean.cjs"
echo "PSC0_WASM_KERNEL_EXECUTION_HEALTH_PASS"
echo "PSC0_LEAN435_LINEAR_WASM_BUILD_PASS bytes=$(stat -c %s "$output/pskernel-lean.wasm")"
