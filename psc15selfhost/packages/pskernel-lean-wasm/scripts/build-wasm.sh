#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
package_root="$(cd "$script_dir/.." && pwd)"
workspace_root="$(cd "$package_root/../.." && pwd)"
repo_root="$(cd "$workspace_root/.." && pwd)"
lean_source="$repo_root/study/lean4-4.34.0"
lean_build="$workspace_root/.wasm-build/lean4"
provider_obj_dir="$workspace_root/.wasm-build/provider-obj"
out_dir="$package_root/wasm"
patch_file="$package_root/patches/lean4-4.34.0-emscripten-uv-stubs.patch"

expected_lean_commit='293d5d0c0c3f3dded4688b3ccd6a33939ac5102b'
expected_emscripten='6.0.9'

actual_lean_commit="$(lean --githash | tr -d '\r\n')"
if [[ "$actual_lean_commit" != "$expected_lean_commit" ]]; then
  echo "unexpected Lean commit: $actual_lean_commit" >&2
  exit 1
fi

emcc_version="$(emcc --version | head -n 1)"
if [[ "$emcc_version" != *"$expected_emscripten"* ]]; then
  echo "unexpected Emscripten version: $emcc_version" >&2
  exit 1
fi

for tool in cmake clang clang++ emcc emar; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "required build tool missing: $tool" >&2
    exit 1
  fi
done

if [[ ! -x /usr/bin/i386-linux-gnu-pkg-config ]]; then
  echo '32-bit pkg-config wrapper missing: /usr/bin/i386-linux-gnu-pkg-config' >&2
  exit 1
fi

emscripten_root="$(cd "$(dirname "$(command -v emcc)")" && pwd)"
emscripten_toolchain="$emscripten_root/cmake/Modules/Platform/Emscripten.cmake"
if [[ ! -f "$emscripten_toolchain" ]]; then
  echo "Emscripten CMake toolchain missing: $emscripten_toolchain" >&2
  exit 1
fi

cd "$repo_root"
if git apply --check "$patch_file" >/dev/null 2>&1; then
  git apply "$patch_file"
elif ! git apply --reverse --check "$patch_file" >/dev/null 2>&1; then
  echo "Lean Emscripten compatibility patch neither applies nor is already present" >&2
  exit 1
fi

# The study snapshot does not preserve executable bits on Lean's helper
# scripts. CMake configure_file preserves source permissions, so repair both
# leanmake and leanc templates before ExternalProject configures stage0/stage1.
for helper_source in \
  "$lean_source/stage0/src/bin/leanmake" \
  "$lean_source/stage0/src/bin/leanc.in" \
  "$lean_source/src/bin/leanmake" \
  "$lean_source/src/bin/leanc.in"; do
  if [[ ! -f "$helper_source" ]]; then
    echo "Lean helper source missing: $helper_source" >&2
    exit 1
  fi
  chmod +x "$helper_source"
done

cd "$workspace_root"
rm -rf .lake/build "$lean_build" "$provider_obj_dir" "$out_dir"
mkdir -p "$lean_build" "$provider_obj_dir" "$out_dir"

# Follow Lean's own wasm cross-build architecture. Stage 0 must be a runnable
# native 32-bit compiler so every .olean records wasm32-compatible platform
# constants; stage 1 is then configured with the Emscripten toolchain.
#
# Pass -m32 through CMake's own C/C++ flags as well as Lean's wrappers. This
# makes CMake's ABI probe see a real 32-bit stage0. Force SSE2 floating-point
# evaluation so FLT_EVAL_METHOD is 0, which Lean requires for deterministic
# Float/Float32 semantics on 32-bit x86.
cmake \
  -S "$lean_source" \
  -B "$lean_build" \
  -G 'Unix Makefiles' \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER_WORKS=1 \
  -DCMAKE_AR="$(command -v emar)" \
  -DCMAKE_TOOLCHAIN_FILE="$emscripten_toolchain" \
  -DSTAGE0_USE_GMP=OFF \
  -DSTAGE0_CMAKE_C_FLAGS='-m32 -msse2 -mfpmath=sse' \
  -DSTAGE0_CMAKE_CXX_FLAGS='-m32 -msse2 -mfpmath=sse' \
  -DSTAGE0_LEAN_EXTRA_CXX_FLAGS='-m32 -msse2 -mfpmath=sse' \
  -DSTAGE0_LEANC_OPTS='-m32 -msse2 -mfpmath=sse' \
  -DSTAGE0_CMAKE_CXX_COMPILER=clang++ \
  -DSTAGE0_CMAKE_C_COMPILER=clang \
  -DSTAGE0_CMAKE_EXECUTABLE_SUFFIX='' \
  -DSTAGE0_MMAP=OFF \
  -DSTAGE0_CMAKE_LIBRARY_PATH=/usr/lib/i386-linux-gnu/ \
  -DSTAGE0_PKG_CONFIG_EXECUTABLE=/usr/bin/i386-linux-gnu-pkg-config \
  -DUSE_GMP=OFF \
  -DUSE_MIMALLOC=OFF \
  -DUSE_LAKE=OFF \
  -DMMAP=OFF \
  -DLLVM=OFF \
  -DCCACHE=OFF \
  -DWFAIL=OFF \
  -DLEAN_INSTALL_SUFFIX=-linux_wasm32

# This target builds native stage 0 and configures wasm32 stage 1, but does not
# yet spend the time building the full target stdlib.
cmake --build "$lean_build" --target stage1-configure -j2

stage0_lake="$lean_build/stage0/bin/lake"
stage0_lean="$lean_build/stage0/bin/lean"
stage1_leanc="$lean_build/stage1/leanc.sh"
if [[ ! -x "$stage0_lake" || ! -x "$stage0_lean" ]]; then
  echo 'native 32-bit Lean stage0 was not produced' >&2
  exit 1
fi

# Generate the provider closure with the 32-bit native compiler. Using the
# host x86_64 toolchain here would reintroduce host-width platform constants
# into the C generated for a wasm32 kernel provider.
"$stage0_lake" build psc2_lean_kernel_provider
mapfile -d '' provider_c_files < <(find .lake/build/ir -type f -name '*.c' -print0 | sort -z)
if [[ ${#provider_c_files[@]} -eq 0 ]]; then
  echo '32-bit stage0 Lake produced no provider C sources' >&2
  exit 1
fi

# Normalize generated target helpers too as defense-in-depth for snapshots or
# CMake versions that do not preserve source modes through configure_file.
for helper in "$lean_build/stage1/bin/leanmake" "$stage1_leanc"; do
  if [[ -e "$helper" ]]; then
    chmod +x "$helper"
  fi
done

# Build Lean's complete wasm32 runtime/static-library closure through the
# normal staged target rather than invoking make_stdlib in a direct stage-1
# build directory. This avoids the missing <build>/leanc layout seen in CI.
cmake --build "$lean_build" --target stage1 -j2

if [[ ! -f "$stage1_leanc" ]]; then
  echo "cross leanc wrapper missing: $stage1_leanc" >&2
  exit 1
fi
chmod +x "$stage1_leanc"

provider_objects=()
index=0
for source in "${provider_c_files[@]}"; do
  object="$provider_obj_dir/$index.o"
  "$stage1_leanc" -O3 -c "$source" -o "$object"
  provider_objects+=("$object")
  index=$((index + 1))
done

# Keep the already-proven CLI transport for the first real WASM milestone.
# The following milestone can replace this with the JS-facing memory API
# without changing admission semantics.
"$stage1_leanc" \
  "${provider_objects[@]}" \
  -O3 \
  -sENVIRONMENT=node \
  -sEXIT_RUNTIME=1 \
  -o "$out_dir/pskernel-lean.js"

if [[ ! -s "$out_dir/pskernel-lean.wasm" ]]; then
  echo 'WASM provider artifact was not produced' >&2
  exit 1
fi

health_json="$(node "$out_dir/pskernel-lean.js" --health)"
node -e '
  const value=JSON.parse(process.argv[1]);
  if(value.status!=="ok"||value.protocol!=="pskernel-lean/1"||
     value.provider!=="lean4-cpp"||value.leanVersion!=="4.34.0"||
     value.leanCommit!=="293d5d0c0c3f3dded4688b3ccd6a33939ac5102b")process.exit(1);
' "$health_json"

printf 'PSC2_LEAN_KERNEL_WASM_BUILD: PASS %s bytes\n' "$(stat -c '%s' "$out_dir/pskernel-lean.wasm")"
