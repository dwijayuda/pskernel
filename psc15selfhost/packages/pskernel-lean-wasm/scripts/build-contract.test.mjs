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
assert.match(build,/-DSTAGE0_USE_GMP=OFF/);
assert.match(build,/-DSTAGE0_CMAKE_C_FLAGS=['"]-m32 -msse2 -mfpmath=sse['"]/);
assert.match(build,/-DSTAGE0_CMAKE_CXX_FLAGS=['"]-m32 -msse2 -mfpmath=sse['"]/);
assert.match(build,/-DSTAGE0_LEAN_EXTRA_CXX_FLAGS=['"]-m32 -msse2 -mfpmath=sse['"]/);
assert.match(build,/-DSTAGE0_LEANC_OPTS=['"]-m32 -msse2 -mfpmath=sse['"]/);
assert.match(build,/-DSTAGE0_CMAKE_CXX_COMPILER=clang\+\+/);
assert.match(build,/-DSTAGE0_CMAKE_C_COMPILER=clang/);
assert.match(build,/-DSTAGE0_CMAKE_EXECUTABLE_SUFFIX=/);
assert.match(build,/-DSTAGE0_MMAP=OFF/);
assert.match(build,/-DSTAGE0_CMAKE_LIBRARY_PATH=\/usr\/lib\/i386-linux-gnu\//);
assert.match(build,/-DUSE_GMP=OFF/);
assert.match(build,/-DUSE_LAKE=OFF/);
assert.match(build,/-DMMAP=OFF/);
assert.match(build,/stage1-configure/);
assert.match(build,/stage0\/bin\/lean/);
assert.match(build,/stage1\/leanc\.sh/);
assert.match(build,/stage0\/src\/bin\/leanmake/);
assert.match(build,/stage0\/src\/bin\/leanc\.in/);
assert.match(build,/src\/bin\/leanmake/);
assert.match(build,/src\/bin\/leanc\.in/);
assert.doesNotMatch(build,/-DPREV_STAGE=["']?\$lean_prefix/);
assert.doesNotMatch(build,/emcmake\s+cmake\s+\\\s*\n\s+-S\s+["']?\$lean_source\/src/);
assert.match(build,/lean4-4\.34\.0-emscripten-uv-stubs\.patch/);
assert.match(build,/pskernel-lean\.wasm/);
assert.doesNotMatch(build,/emsdk\s+(install|activate)\s+(latest|tot)/);

// Lean stage0 is C_ONLY: it is the previous-stage compiler, not the target
// current-source .olean sysroot. Build stage1 first, then use the native 32-bit
// stage0 compiler directly against stage1/lib/lean to emit the provider's C.
// Do not route the external provider through bootstrap Lake.
assert.match(build,/provider_overlay/);
assert.match(build,/target_lean_path=.*stage1\/lib\/lean/);
assert.match(build,/provider_olean_dir/);
assert.match(build,/provider_c_dir/);
assert.match(build,/provider_modules=/);
assert.match(build,/PsKernelLean\/Convert/);
assert.match(build,/PsKernelLean\/Prelude/);
assert.match(build,/PsKernelLean\/Main/);
assert.match(build,/LEAN_PATH=.*target_lean_path/);
assert.match(build,/--c=/);
assert.doesNotMatch(build,/"\$stage0_lake"\s+build\s+provider/);
assert.doesNotMatch(build,/\[\[lean_lib\]\]/);

const stage1BuildIndex=build.indexOf('cmake --build "$lean_build" --target stage1 -j2');
const providerCompileIndex=build.indexOf('provider_modules=');
assert.ok(stage1BuildIndex>=0,'stage1 target build must exist');
assert.ok(providerCompileIndex>=0,'direct provider module compile list must exist');
assert.ok(stage1BuildIndex<providerCompileIndex,'stage1 sysroot must exist before provider compilation');

assert.match(build,/packages\/foundation\/src\/Ps/);
assert.match(build,/packages\/core\/src\/Ps/);
assert.match(build,/packages\/environment\/src\/Ps/);
assert.match(build,/packages\/bridge\/src\/Ps/);
assert.match(build,/packages\/pskernel-lean\/provider\/PsKernelLean/);

// Keep the diagnostic matrix until the stage0/stage1 ordering fix is proven in
// CI. It provides direct evidence that basic/core compilation is distinct from
// imports requiring the target Lean .olean environment.
assert.match(build,/PSC2_STAGE0_PARSER_PROBE/);
assert.match(build,/Stage0ProbeBasic\.lean/);
assert.match(build,/Stage0ProbeLean\.lean/);
assert.match(build,/Stage0ProbePs\.lean/);
assert.match(build,/import Lean/);
assert.match(build,/import Ps\.Foundation\.Name/);

const patch=await readFile(path.join(packageRoot,'patches/lean4-4.34.0-emscripten-uv-stubs.patch'),'utf8');
assert.match(patch,/src\/CMakeLists\.txt/);
assert.match(patch,/-  Leanc\n   LeanIR/);
assert.match(patch,/\+  list\(APPEND STDLIBS Leanc\)/);
// Lean 4.34's leanir make rule is the one stage0 executable link that omits
// LEANC_OPTS. A native -m32 stage0 therefore compiles 32-bit libraries but
// tries to link leanir as host-width. Patch both the frozen stage0 template and
// the normal stage template so the target-compatible bootstrap stays coherent.
assert.match(patch,/stage0\/src\/stdlib\.make\.in/);
assert.match(patch,/src\/stdlib\.make\.in/);
const leanirLinkFixes=patch.match(/\$\{LEAN_EXE_LINKER_FLAGS\} \$\{LEANC_OPTS\} -o \$@/g)??[];
assert.ok(leanirLinkFixes.length>=2,'Lean stage0/stage1 leanir links must preserve LEANC_OPTS');

const workflow=await readFile(path.join(repoRoot,'.github/workflows/psc2-lean-kernel-wasm.yml'),'utf8');
assert.match(workflow,/6\.0\.9/);
assert.match(workflow,/emcc --version/);
assert.match(workflow,/dpkg --add-architecture i386/);
assert.match(workflow,/gcc-multilib/);
assert.match(workflow,/g\+\+-multilib/);
assert.match(workflow,/libuv1-dev:i386/);
assert.match(workflow,/libssl-dev:i386/);
assert.match(workflow,/pkgconf:i386/);
assert.match(workflow,/build-wasm\.sh/);

console.log('PSC2_LEAN_KERNEL_WASM_BUILD_CONTRACT: PASS');
