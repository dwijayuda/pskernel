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
mkdir -p "$lean_build" "$provider_src/Ps" "$provider_src/PsKernelLean" "$provider_obj_dir" "$out_dir"

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

# Do not ask bootstrap Lake to elaborate the full modern psc15selfhost
# lakefile.lean. Stage0 Lake intentionally comes from Lean's frozen bootstrap
# sources and can lack parser categories used by the current Lake DSL. Instead,
# construct a tiny TOML-only package containing precisely the source families
# needed by PsKernelLean.Main. The merged src/Ps tree preserves the original
# module names while keeping the cross-build independent of the host workspace
# build description.
cp -a "$workspace_root/packages/foundation/src/Ps/." "$provider_src/Ps/"
cp -a "$workspace_root/packages/core/src/Ps/." "$provider_src/Ps/"
cp -a "$workspace_root/packages/environment/src/Ps/." "$provider_src/Ps/"
cp -a "$workspace_root/packages/bridge/src/Ps/." "$provider_src/Ps/"
cp -a "$workspace_root/packages/pskernel-lean/provider/PsKernelLean/." "$provider_src/PsKernelLean/"

cat > "$provider_overlay/lakefile.toml" <<'EOF'
name = "pskernelLeanWasmBootstrap"
version = "0.0.0"
defaultTargets = ["provider"]
srcDir = "src"

[[lean_lib]]
name = "ProviderModules"
roots = [
  "Ps.Foundation.Name",
  "Ps.Core.Builtin",
  "Ps.Core.Level",
  "Ps.Core.Expr",
  "Ps.Core.Declaration",
  "Ps.Bridge.Json",
  "Ps.Bridge.CheckedAdmissions",
  "Ps.Bridge.Codec",
  "Ps.Environment.Basic",
  "Ps.Environment.Prelude",
  "Ps.Environment.SelfHostPrelude",
  "Ps.Environment.SelfHostProd",
  "PsKernelLean.Error",
  "PsKernelLean.Convert",
  "PsKernelLean.Protocol",
  "PsKernelLean.Prelude",
  "PsKernelLean.Admission",
  "PsKernelLean.Response"
]

[[lean_exe]]
name = "provider"
root = "PsKernelLean.Main"
EOF

# Diagnostic matrix for the current bootstrap-parser failure. These probes are
# intentionally non-fatal: they localize whether stage0 fails on a trivial
# file, on importing Lean's parser environment, or only on PSC source/modules.
# Keep the output compact so the CI failure tail contains the causal boundary.
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
run_stage0_probe lean_import "$stage0_lean" "$provider_overlay/Stage0ProbeLean.lean"
run_stage0_probe ps_source "$stage0_lean" "$provider_src/Ps/Foundation/Name.lean"

probe_lib="$provider_overlay/probe-lib"
mkdir -p "$probe_lib/Ps/Foundation"
run_stage0_probe ps_name_olean \
  "$stage0_lean" \
  -o "$probe_lib/Ps/Foundation/Name.olean" \
  "$provider_src/Ps/Foundation/Name.lean"
LEAN_PATH="$probe_lib${LEAN_PATH:+:$LEAN_PATH}" \
  run_stage0_probe ps_import "$stage0_lean" "$provider_overlay/Stage0ProbePs.lean"

# Generate the provider C closure with the target-width-compatible native
# stage0 compiler. The TOML overlay is intentionally self-contained and does
# not contain a lakefile.lean.
(
  cd "$provider_overlay"
  "$stage0_lake" build provider
)
mapfile -d '' provider_c_files < <(find "$provider_overlay/.lake/build/ir" -type f -name '*.c' -print0 | sort -z)
if [[ ${#provider_c_files[@]} -eq 0 ]]; then
  echo '32-bit stage0 Lake produced no provider C sources from the minimal overlay' >&2
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
