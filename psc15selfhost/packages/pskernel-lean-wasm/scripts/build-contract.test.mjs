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
assert.match(build,/-DMMAP=OFF/);
assert.match(build,/stage1-configure/);
assert.match(build,/stage0\/bin\/lake/);
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

const patch=await readFile(path.join(packageRoot,'patches/lean4-4.34.0-emscripten-uv-stubs.patch'),'utf8');
assert.match(patch,/src\/CMakeLists\.txt/);
assert.match(patch,/-  Leanc\n   LeanIR/);
assert.match(patch,/\+  list\(APPEND STDLIBS Leanc\)/);

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
