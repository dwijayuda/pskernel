#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
package_root="$(cd "$script_dir/.." && pwd)"
workspace_root="$(cd "$package_root/../.." && pwd)"
repo_root="$(cd "$workspace_root/.." && pwd)"
lean_source="$repo_root/study/lean4-4.34.0"
lean_build="$workspace_root/.wasm-build/lean4"
provider_overlay="$workspace_root/.wasm-build/provider-overlay"
provider_src="$provider_overlay/src"
provider_olean_dir="$provider_overlay/olean"
provider_c_dir="$provider_overlay/c"
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
rm -rf .lake/build "$lean_build" "$provider_overlay" "$provider_obj_dir" "$out_dir"
mkdir -p \
  "$lean_build" \
  "$provider_src/Ps" \
  "$provider_src/PsKernelLean" \
  "$provider_olean_dir" \
  "$provider_c_dir" \
  "$provider_obj_dir" \
  "$out_dir"

# Follow Lean's wasm cross-build architecture. Stage0 is a runnable native
# 32-bit previous-stage compiler; stage1 is configured for Emscripten/wasm32.
# Matching the previous-stage width to wasm32 prevents host-width platform
# constants from entering the target .olean/C closure.
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

# Build native stage0 and configure wasm32 stage1 first.
cmake --build "$lean_build" --target stage1-configure -j2

stage0_lean="$lean_build/stage0/bin/lean"
stage1_leanc="$lean_build/stage1/leanc.sh"
target_lean_path="$lean_build/stage1/lib/lean"
if [[ ! -x "$stage0_lean" ]]; then
  echo 'native 32-bit Lean stage0 compiler was not produced' >&2
  exit 1
fi

# Stage0 is deliberately C_ONLY in Lean's bootstrap. It is a compiler, not a
# complete current-source .olean sysroot. The provider imports `Lean`, so build
# the target stage1 stdlib/runtime first. USE_LAKE=OFF keeps this bootstrap on
# Lean's leanmake path, which itself invokes PREV_STAGE/bin/lean to produce the
# wasm32-compatible target .oleans and C/runtime libraries.
cmake --build "$lean_build" --target stage1 -j2

if [[ ! -f "$stage1_leanc" ]]; then
  echo "cross leanc wrapper missing: $stage1_leanc" >&2
  exit 1
fi
chmod +x "$stage1_leanc"
if [[ ! -f "$target_lean_path/Lean.olean" ]]; then
  echo "target Lean sysroot missing: $target_lean_path/Lean.olean" >&2
  exit 1
fi

# Stage only the semantic provider sources. The direct compile list below is the
# same closure already proven by the native Lean provider tests; parser,
# elaborator, compiler, CLI and backend packages stay outside this artifact.
cp -a "$workspace_root/packages/foundation/src/Ps/." "$provider_src/Ps/"
cp -a "$workspace_root/packages/core/src/Ps/." "$provider_src/Ps/"
cp -a "$workspace_root/packages/environment/src/Ps/." "$provider_src/Ps/"
cp -a "$workspace_root/packages/bridge/src/Ps/." "$provider_src/Ps/"
cp -a "$workspace_root/packages/pskernel-lean/provider/PsKernelLean/." "$provider_src/PsKernelLean/"

# Keep compact probes while this bootstrap seam is being proven. Before stage1,
# importing Lean had no target .olean environment; after stage1 the same native
# stage0 compiler must succeed when pointed at stage1/lib/lean.
run_stage0_probe() {
  local name="$1"
  shift
  local log="$provider_overlay/$name.log"
  echo "PSC2_STAGE0_PARSER_PROBE: BEGIN $name"
  set +e
  "$@" >"$log" 2>&1
  local status=$?
  set -e
  if [[ $status -eq 0 ]]; then
    echo "PSC2_STAGE0_PARSER_PROBE: PASS $name"
  else
    echo "PSC2_STAGE0_PARSER_PROBE: FAIL $name status=$status"
    tail -n 40 "$log" || true
  fi
}

cat > "$provider_overlay/Stage0ProbeBasic.lean" <<'EOF'
def stage0ProbeBasic : Nat := 1
EOF

cat > "$provider_overlay/Stage0ProbeLean.lean" <<'EOF'
import Lean
def stage0ProbeLean : Nat := 1
EOF

cat > "$provider_overlay/Stage0ProbePs.lean" <<'EOF'
import Ps.Foundation.Name
def stage0ProbePs : PsName := PsName.anonymous
EOF

run_stage0_probe basic "$stage0_lean" "$provider_overlay/Stage0ProbeBasic.lean"
run_stage0_probe lean_import_stage1 \
  env LEAN_PATH="$target_lean_path" \
  "$stage0_lean" "$provider_overlay/Stage0ProbeLean.lean"

# Emit the provider closure directly with the target-width-compatible previous
# stage compiler. This is the same Lean invocation shape used by lean.mk:
#   lean -o module.olean -i module.ilean --c=module.c module.lean
# stage1/lib/lean supplies target-compatible `Lean` imports; provider_olean_dir
# supplies already-built PSC/provider imports as the list advances.
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
  export LEAN_PATH="$provider_olean_dir:$target_lean_path"
  export LEAN_CC="$(command -v emcc)"
  export LEAN_ABORT_ON_PANIC=1
  for module in "${provider_modules[@]}"; do
    source="$module.lean"
    olean="$provider_olean_dir/$module.olean"
    ilean="$provider_olean_dir/$module.ilean"
    c_file="$provider_c_dir/$module.c"
    c_tmp="$c_file.tmp"
    mkdir -p "$(dirname "$olean")" "$(dirname "$c_file")"
    echo "PSC2_PROVIDER_STAGE0_COMPILE: $module"
    "$stage0_lean" \
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
  "$stage1_leanc" -O3 -c "$source" -o "$object"
  provider_objects+=("$object")
  index=$((index + 1))
done

# Keep the already-proven CLI transport for the first real WASM milestone. The
# following milestone can replace this with the JS-facing memory ABI without
# changing admission semantics.
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
