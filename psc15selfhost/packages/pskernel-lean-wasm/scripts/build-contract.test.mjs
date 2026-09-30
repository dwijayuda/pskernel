import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const here=path.dirname(fileURLToPath(import.meta.url));
const packageRoot=path.resolve(here,'..');
const repoRoot=path.resolve(packageRoot,'../../..');
const pin=JSON.parse(await readFile(path.join(packageRoot,'EMSCRIPTEN_PIN.json'),'utf8'));
assert.equal(pin.version,'6.0.9');
assert.notEqual(pin.version,'latest');
assert.notEqual(pin.version,'tot');

const build=await readFile(path.join(here,'build-wasm.sh'),'utf8');
assert.match(build,/-DCMAKE_TOOLCHAIN_FILE=/);
assert.match(build,/-DUSE_GMP=OFF/);
assert.match(build,/-DUSE_LAKE=OFF/);
assert.match(build,/-DMMAP=OFF/);
assert.match(build,/lean4-4\.34\.0-emscripten-uv-stubs\.patch/);
assert.match(build,/pskernel-lean\.wasm/);
assert.doesNotMatch(build,/emsdk\s+(install|activate)\s+(latest|tot)/);

// A native i386 stage0 was proven semantically broken in CI: even a trivial
// `def x : Nat := 1` aborts with `unknown parser category `level``. The WASM
// provider therefore uses the exact pinned host Lean only as a C emitter and
// cross-compiles Lean's frozen stage0 runtime/kernel plus the emitted provider
// C with Emscripten. No runnable target-width Lean compiler or stage1 sysroot
// is part of this artifact build.
assert.doesNotMatch(build,/-m32/);
assert.doesNotMatch(build,/i386-linux-gnu/);
assert.doesNotMatch(build,/STAGE0_CMAKE_C_FLAGS/);
assert.doesNotMatch(build,/STAGE0_CMAKE_CXX_FLAGS/);
assert.doesNotMatch(build,/STAGE0_LEAN_EXTRA_CXX_FLAGS/);
assert.doesNotMatch(build,/STAGE0_LEANC_OPTS/);
assert.doesNotMatch(build,/stage1-configure/);
assert.doesNotMatch(build,/--target stage1(?:\s|$)/);
assert.doesNotMatch(build,/target_lean_path/);
assert.doesNotMatch(build,/stage0\/bin\/lean/);
assert.doesNotMatch(build,/PSC2_STAGE0_PARSER_PROBE/);

assert.match(build,/cmake --build "\$lean_build" --target stage0 -j2/);
assert.match(build,/host_lean=.*command -v lean/);
assert.match(build,/host_lean_prefix=.*lean --print-prefix/);
assert.match(build,/host_lean_path=.*lib\/lean/);
assert.match(build,/wasm_leanc=.*stage0\/leanc\.sh/);
assert.match(build,/provider_overlay/);
assert.match(build,/provider_olean_dir/);
assert.match(build,/provider_c_dir/);
assert.match(build,/provider_modules=/);
assert.match(build,/PsKernelLean\/Convert/);
assert.match(build,/PsKernelLean\/Prelude/);
assert.match(build,/PsKernelLean\/Main/);
assert.match(build,/LEAN_PATH=.*host_lean_path/);
assert.match(build,/"\$host_lean"/);
assert.match(build,/--c=/);
assert.match(build,/"\$wasm_leanc" -O3 -c/);
assert.doesNotMatch(build,/LEAN_CC=.*emcc/);
assert.doesNotMatch(build,/"\$stage0_lake"\s+build\s+provider/);
assert.doesNotMatch(build,/\[\[lean_lib\]\]/);

const stage0BuildIndex=build.indexOf('cmake --build "$lean_build" --target stage0 -j2');
const providerCompileIndex=build.indexOf('provider_modules=');
assert.ok(stage0BuildIndex>=0,'Emscripten stage0 build must exist');
assert.ok(providerCompileIndex>=0,'direct provider module compile list must exist');
assert.ok(stage0BuildIndex<providerCompileIndex,'WASM Lean runtime/kernel must exist before provider C compilation');

assert.match(build,/packages\/foundation\/src\/Ps/);
assert.match(build,/packages\/core\/src\/Ps/);
assert.match(build,/packages\/environment\/src\/Ps/);
assert.match(build,/packages\/bridge\/src\/Ps/);
assert.match(build,/packages\/pskernel-lean\/provider\/PsKernelLean/);

const patch=await readFile(path.join(packageRoot,'patches/lean4-4.34.0-emscripten-uv-stubs.patch'),'utf8');
assert.match(patch,/runtime\/uv\/event_loop\.cpp/);
assert.match(patch,/lean_uv_event_loop_alive/);
assert.match(patch,/runtime\/uv\/system\.cpp/);
assert.match(patch,/lean_uv_os_get_group/);

const workflow=await readFile(path.join(repoRoot,'.github/workflows/psc2-lean-kernel-wasm.yml'),'utf8');
assert.match(workflow,/6\.0\.9/);
assert.match(workflow,/emcc --version/);
assert.match(workflow,/build-wasm\.sh/);
assert.doesNotMatch(workflow,/dpkg --add-architecture i386/);
assert.doesNotMatch(workflow,/gcc-multilib/);
assert.doesNotMatch(workflow,/g\+\+-multilib/);
assert.doesNotMatch(workflow,/libuv1-dev:i386/);
assert.doesNotMatch(workflow,/libssl-dev:i386/);
assert.doesNotMatch(workflow,/pkgconf:i386/);

console.log('PSC2_LEAN_KERNEL_WASM_BUILD_CONTRACT: PASS');
