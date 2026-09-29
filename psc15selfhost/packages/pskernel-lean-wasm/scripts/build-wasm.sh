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

lean_prefix="$(lean --print-prefix)"
if [[ ! -x "$lean_prefix/bin/lean" ]]; then
  echo "Lean prefix does not contain bin/lean: $lean_prefix" >&2
  exit 1
fi

cd "$repo_root"
if git apply --check "$patch_file" >/dev/null 2>&1; then
  git apply "$patch_file"
elif ! git apply --reverse --check "$patch_file" >/dev/null 2>&1; then
  echo "Lean Emscripten compatibility patch neither applies nor is already present" >&2
  exit 1
fi

cd "$workspace_root"
rm -rf .lake/build "$lean_build" "$provider_obj_dir" "$out_dir"
mkdir -p "$lean_build" "$provider_obj_dir" "$out_dir"

# Generate target-independent C for exactly the working native provider closure.
lake build psc2_lean_kernel_provider
mapfile -d '' provider_c_files < <(find .lake/build/ir -type f -name '*.c' -print0 | sort -z)
if [[ ${#provider_c_files[@]} -eq 0 ]]; then
  echo 'Lake produced no provider C sources' >&2
  exit 1
fi

# Cross-build Lean's runtime and static library closure using the installed native
# Lean 4.34 compiler as the previous stage and Emscripten as the target compiler.
emcmake cmake \
  -S "$lean_source/src" \
  -B "$lean_build" \
  -G 'Unix Makefiles' \
  -DSTAGE=1 \
  -DPREV_STAGE="$lean_prefix" \
  -DPREV_STAGE_CMAKE_EXECUTABLE_SUFFIX='' \
  -DCMAKE_BUILD_TYPE=Release \
  -DUSE_GITHASH=OFF \
  -DUSE_GMP=OFF \
  -DUSE_MIMALLOC=OFF \
  -DUSE_LAKE=OFF \
  -DLLVM=OFF \
  -DCCACHE=OFF \
  -DWFAIL=OFF

cmake --build "$lean_build" --target make_stdlib -j2

if [[ ! -x "$lean_build/leanc.sh" ]]; then
  echo "cross leanc wrapper missing: $lean_build/leanc.sh" >&2
  exit 1
fi

provider_objects=()
index=0
for source in "${provider_c_files[@]}"; do
  object="$provider_obj_dir/$index.o"
  "$lean_build/leanc.sh" -O3 -c "$source" -o "$object"
  provider_objects+=("$object")
  index=$((index + 1))
done

# Task 3 deliberately builds the already-proven CLI transport first. Task 4
# replaces the JS-facing transport with a memory API without changing semantics.
"$lean_build/leanc.sh" \
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
