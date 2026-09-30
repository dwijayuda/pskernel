#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
package_root="$(cd "$script_dir/.." && pwd)"
candidate_workspace_root="$(cd "$package_root/../.." && pwd)"
candidate_repo_root="$(cd "$candidate_workspace_root/.." && pwd)"
package_source_root="$package_root/source/proofscript"
patch_file="$package_root/patches/lean4-4.34.0-emscripten-uv-stubs.patch"
out_dir="$package_root/wasm"

expected_lean_commit='293d5d0c0c3f3dded4688b3ccd6a33939ac5102b'
expected_emscripten='6.0.9'

# The same script serves two layouts:
#   1. the pskernel monorepo, where live PSC sources and study/lean4-4.34.0 exist;
#   2. an unpacked/installed npm package, where the PSC source snapshot is under
#      source/proofscript and the full Lean tree is fetched at the exact pin.
if [[ -d "$candidate_workspace_root/packages/foundation/src/Ps" && \
      -d "$candidate_repo_root/study/lean4-4.34.0/src/kernel" ]]; then
  source_mode='monorepo'
  workspace_root="$candidate_workspace_root"
  repo_root="$candidate_repo_root"
  build_root="$workspace_root/.wasm-build"
  lean_source="$repo_root/study/lean4-4.34.0"
  foundation_source="$workspace_root/packages/foundation/src/Ps"
  core_source="$workspace_root/packages/core/src/Ps"
  environment_source="$workspace_root/packages/environment/src/Ps"
  bridge_source="$workspace_root/packages/bridge/src/Ps"
  provider_source="$workspace_root/packages/pskernel-lean/provider/PsKernelLean"
else
  source_mode='package'
  build_root="${PSC_LEAN_WASM_BUILD_ROOT:-$package_root/.wasm-build}"
  lean_source="${PSC_LEAN_WASM_LEAN_SOURCE:-$package_root/.source-cache/lean4-4.34.0}"
  foundation_source="$package_source_root/foundation/Ps"
  core_source="$package_source_root/core/Ps"
  environment_source="$package_source_root/environment/Ps"
  bridge_source="$package_source_root/bridge/Ps"
  provider_source="$package_source_root/provider/PsKernelLean"
fi

lean_build="$build_root/lean4"
provider_overlay="$build_root/provider-overlay"
provider_src="$provider_overlay/src"
provider_olean_dir="$provider_overlay/olean"
provider_c_dir="$provider_overlay/c"
provider_obj_dir="$build_root/provider-obj"

for tool in cmake emcc em++ emar lean node git; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "required build tool missing: $tool" >&2
    exit 1
  fi
done

host_lean="$(command -v lean)"
host_lean_prefix="$(lean --print-prefix)"
host_lean_path="$host_lean_prefix/lib/lean"
actual_lean_commit="$($host_lean --githash | tr -d '\r\n')"
if [[ "$actual_lean_commit" != "$expected_lean_commit" ]]; then
  echo "unexpected Lean commit: $actual_lean_commit" >&2
  exit 1
fi
if [[ ! -f "$host_lean_path/Lean.olean" ]]; then
  echo "host Lean sysroot missing: $host_lean_path/Lean.olean" >&2
  exit 1
fi

emcc_version="$(emcc --version | head -n 1)"
if [[ "$emcc_version" != *"$expected_emscripten"* ]]; then
  echo "unexpected Emscripten version: $emcc_version" >&2
  exit 1
fi

emscripten_root="$(cd "$(dirname "$(command -v emcc)")" && pwd)"
emscripten_toolchain="$emscripten_root/cmake/Modules/Platform/Emscripten.cmake"
if [[ ! -f "$emscripten_toolchain" ]]; then
  echo "Emscripten CMake toolchain missing: $emscripten_toolchain" >&2
  exit 1
fi

if [[ "$source_mode" == 'package' ]]; then
  # The npm package carries the small kernel audit snapshot directly, but a
  # rebuild needs Lean's complete current source tree. Fetch only the exact
  # pinned commit; never fall back to a branch, tag tip, or "latest" source.
  if [[ ! -d "$lean_source/.git" ]]; then
    rm -rf "$lean_source"
    mkdir -p "$lean_source"
    git -C "$lean_source" init -q
    git -C "$lean_source" remote add origin https://github.com/leanprover/lean4.git
  elif ! git -C "$lean_source" remote get-url origin >/dev/null 2>&1; then
    git -C "$lean_source" remote add origin https://github.com/leanprover/lean4.git
  fi
  git -C "$lean_source" fetch --depth 1 origin "$expected_lean_commit"
  git -C "$lean_source" checkout -q --detach FETCH_HEAD
  git -C "$lean_source" reset -q --hard "$expected_lean_commit"
  git -C "$lean_source" clean -q -fdx
  actual_source_commit="$(git -C "$lean_source" rev-parse HEAD)"
  if [[ "$actual_source_commit" != "$expected_lean_commit" ]]; then
    echo "unexpected fetched Lean source commit: $actual_source_commit" >&2
    exit 1
  fi
fi

for source_dir in \
  "$foundation_source" \
  "$core_source" \
  "$environment_source" \
  "$bridge_source" \
  "$provider_source"; do
  if [[ ! -d "$source_dir" ]]; then
    echo "packaged ProofScript source missing: $source_dir" >&2
    exit 1
  fi
done

mkdir -p "$build_root"
if [[ "$source_mode" == 'monorepo' ]]; then
  patch_apply_root="$repo_root"
  patch_to_apply="$patch_file"
else
  patch_apply_root="$lean_source"
  patch_to_apply="$build_root/lean4-4.34.0-emscripten-standalone.patch"
  sed 's#study/lean4-4.34.0/##g' "$patch_file" > "$patch_to_apply"
fi

cd "$patch_apply_root"
if git apply --check "$patch_to_apply" >/dev/null 2>&1; then
  git apply "$patch_to_apply"
elif ! git apply --reverse --check "$patch_to_apply" >/dev/null 2>&1; then
  echo "Lean Emscripten compatibility patch neither applies nor is already present" >&2
  exit 1
fi

# Typed WebAssembly enforces exact function signatures. Apply the small set of
# Lean-4.34 erased-RealWorld/Unit ABI corrections deterministically against the
# pinned source tree. Native signatures stay in the non-Emscripten branches.
node "$script_dir/apply-wasm-abi.mjs" "$lean_source"

# The vendored/study snapshots may not preserve executable bits on Lean helper
# scripts. Repair the current helper sources before CMake stages them.
for helper_source in \
  "$lean_source/src/bin/leanmake" \
  "$lean_source/src/bin/leanc.in"; do
  if [[ ! -f "$helper_source" ]]; then
    echo "Lean helper source missing: $helper_source" >&2
    exit 1
  fi
  chmod +x "$helper_source"
done

if [[ "$source_mode" == 'monorepo' ]]; then
  rm -rf "$workspace_root/.lake/build"
fi
rm -rf "$lean_build" "$provider_overlay" "$provider_obj_dir" "$out_dir"
mkdir -p \
  "$lean_build" \
  "$provider_src/Ps" \
  "$provider_src/PsKernelLean" \
  "$provider_olean_dir" \
  "$provider_c_dir" \
  "$provider_obj_dir" \
  "$out_dir"

# Build Lean 4.34's current source tree directly for wasm32 as STAGE=1. The
# exact pinned native Lean 4.34.0 installation is PREV_STAGE and only emits C;
# no native host object/runtime library enters the WebAssembly artifact.
cmake \
  -S "$lean_source/src" \
  -B "$lean_build" \
  -G 'Unix Makefiles' \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER_WORKS=1 \
  -DCMAKE_AR="$(command -v emar)" \
  -DCMAKE_TOOLCHAIN_FILE="$emscripten_toolchain" \
  -DSTAGE=1 \
  -DPREV_STAGE="$host_lean_prefix" \
  -DPREV_STAGE_CMAKE_EXECUTABLE_SUFFIX= \
  -DMULTI_THREAD=OFF \
  -DUSE_GMP=OFF \
  -DUSE_MIMALLOC=OFF \
  -DUSE_LAKE=OFF \
  -DMMAP=OFF \
  -DLLVM=OFF \
  -DCCACHE=OFF \
  -DWFAIL=OFF \
  -DLEAN_INSTALL_SUFFIX=-linux_wasm32

cmake --build "$lean_build" -j2

wasm_leanc="$lean_build/leanc.sh"
if [[ ! -f "$wasm_leanc" ]]; then
  echo "Emscripten current-source leanc wrapper missing: $wasm_leanc" >&2
  exit 1
fi
chmod +x "$wasm_leanc"

for runtime_lib in \
  "$lean_build/lib/lean/libleanrt.a" \
  "$lean_build/lib/lean/libInit.a" \
  "$lean_build/lib/lean/libStd.a" \
  "$lean_build/lib/lean/libLean.a" \
  "$lean_build/lib/lean/libleancpp.a"; do
  if [[ ! -s "$runtime_lib" ]]; then
    echo "Emscripten Lean current-source library missing: $runtime_lib" >&2
    exit 1
  fi
done

# Stage only the semantic provider closure. In the monorepo these are the live
# sibling sources; in an npm tarball they are the exact source snapshots under
# source/proofscript/.
cp -a "$foundation_source/." "$provider_src/Ps/"
cp -a "$core_source/." "$provider_src/Ps/"
cp -a "$environment_source/." "$provider_src/Ps/"
cp -a "$bridge_source/." "$provider_src/Ps/"
cp -a "$provider_source/." "$provider_src/PsKernelLean/"

provider_modules=(
  "Ps/Foundation/Name"
  "PsKernelLean/Error"
  "Ps/Core/Builtin"
  "Ps/Core/Level"
  "Ps/Bridge/Json"
  "Ps/Core/Expr"
  "Ps/Core/Declaration"
  "Ps/Environment/Basic"
  "Ps/Bridge/CheckedAdmissions"
  "Ps/Environment/Prelude"
  "PsKernelLean/Convert"
  "Ps/Bridge/Codec"
  "Ps/Environment/SelfHostPrelude"
  "Ps/Environment/SelfHostProd"
  "PsKernelLean/Protocol"
  "PsKernelLean/Prelude"
  "PsKernelLean/Admission"
  "PsKernelLean/Response"
  "PsKernelLean/Main"
)

(
  cd "$provider_src"
  export LEAN_PATH="$provider_olean_dir:$host_lean_path"
  export LEAN_ABORT_ON_PANIC=1
  for module in "${provider_modules[@]}"; do
    source="$module.lean"
    olean="$provider_olean_dir/$module.olean"
    ilean="$provider_olean_dir/$module.ilean"
    c_file="$provider_c_dir/$module.c"
    c_tmp="$c_file.tmp"
    mkdir -p "$(dirname "$olean")" "$(dirname "$c_file")"
    echo "PSC2_PROVIDER_HOST_C_EMIT: $module"
    "$host_lean" \
      -o "$olean" \
      -i "$ilean" \
      --c="$c_tmp" \
      "$source"
    mv "$c_tmp" "$c_file"
  done
)

mapfile -d '' provider_c_files < <(find "$provider_c_dir" -type f -name '*.c' -print0 | sort -z)
if [[ ${#provider_c_files[@]} -ne ${#provider_modules[@]} ]]; then
  echo "provider C closure incomplete: ${#provider_c_files[@]} of ${#provider_modules[@]} modules" >&2
  exit 1
fi

provider_objects=()
index=0
for source in "${provider_c_files[@]}"; do
  object="$provider_obj_dir/$index.o"
  "$wasm_leanc" -O3 -c "$source" -o "$object"
  provider_objects+=("$object")
  index=$((index + 1))
done

LEAN_CC="$(command -v em++)" "$wasm_leanc" \
  "${provider_objects[@]}" \
  -lleancpp \
  -lInit \
  -lStd \
  -lLean \
  -lnodefs.js \
  -lleanrt \
  -lstdc++ \
  -O3 \
  -sUSE_PTHREADS=0 \
  -sENVIRONMENT=node \
  -sEXIT_RUNTIME=1 \
  -o "$out_dir/pskernel-lean.cjs"

if [[ ! -s "$out_dir/pskernel-lean.wasm" ]]; then
  echo 'WASM provider artifact was not produced' >&2
  exit 1
fi

health_json="$(node "$out_dir/pskernel-lean.cjs" --health)"
node -e '
  const value=JSON.parse(process.argv[1]);
  if(value.status!=="ok"||value.protocol!=="pskernel-lean/1"||
     value.provider!=="lean4-cpp"||value.leanVersion!=="4.34.0"||
     value.leanCommit!=="293d5d0c0c3f3dded4688b3ccd6a33939ac5102b")process.exit(1);
' "$health_json"

accepted_request='{"protocol":"pskernel-lean/1","format":"proofscript-checked-admissions","version":2,"admissions":[{"kind":"constant","declaration":{"h":{"h":"1","k":"regular"},"k":"definition","lp":[],"n":{"k":"s","p":{"k":"a"},"v":"Test.True"},"s":"safe","t":{"k":"const","ls":[],"n":{"k":"s","p":{"k":"a"},"v":"Nat"}},"v":{"k":"nat","v":"1"}}}]}'
accepted_json="$(printf '%s' "$accepted_request" | node "$out_dir/pskernel-lean.cjs" --check)"
node -e '
  const value=JSON.parse(process.argv[1]);
  if(value.accepted!==true)process.exit(1);
' "$accepted_json"
echo 'PSC2_LEAN_KERNEL_WASM_ACCEPT_SMOKE: PASS'

rejected_request='{"protocol":"pskernel-lean/1","format":"proofscript-checked-admissions","version":2,"admissions":[{"kind":"constant","declaration":{"h":{"h":"1","k":"regular"},"k":"definition","lp":[],"n":{"k":"s","p":{"k":"a"},"v":"Test.Bad"},"s":"safe","t":{"k":"const","ls":[],"n":{"k":"s","p":{"k":"a"},"v":"Nat"}},"v":{"k":"sort","l":{"k":"z"}}}}]}'
rejected_json="$(printf '%s' "$rejected_request" | node "$out_dir/pskernel-lean.cjs" --check)"
node -e '
  const value=JSON.parse(process.argv[1]);
  if(value.accepted!==false||value.errorKind!=="kernel-rejection")process.exit(1);
' "$rejected_json"
echo 'PSC2_LEAN_KERNEL_WASM_REJECT_SMOKE: PASS'

printf 'PSC2_LEAN_KERNEL_WASM_BUILD: PASS %s bytes\n' "$(stat -c '%s' "$out_dir/pskernel-lean.wasm")"
