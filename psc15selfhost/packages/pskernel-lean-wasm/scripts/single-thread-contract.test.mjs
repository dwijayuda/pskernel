import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const here=path.dirname(fileURLToPath(import.meta.url));
const packageRoot=path.resolve(here,'..');
const build=await readFile(path.join(here,'build-wasm.sh'),'utf8');
const patch=await readFile(
  path.join(packageRoot,'patches/lean4-4.34.0-emscripten-uv-stubs.patch'),
  'utf8',
);

// Lean 4.34's Emscripten branch forces -pthread even when MULTI_THREAD=OFF.
// The PSC kernel provider must be a genuine single-threaded Node WASM build:
// no shared-memory/pthread runtime is part of the semantic assurance artifact.
assert.match(build,/-DMULTI_THREAD=OFF/);
assert.match(build,/-sUSE_PTHREADS=0/);

// Carry the upstream fixes required for a real MULTI_THREAD=OFF build.
assert.match(patch,/src\/CMakeLists\.txt/);
assert.match(patch,/if\(MULTI_THREAD\)/);
assert.match(patch,/EMSCRIPTEN_SETTINGS/);
assert.match(patch,/LEANC_EXTRA_CC_FLAGS/);
assert.match(patch,/src\/runtime\/thread\.h/);
assert.match(patch,/#include <mutex>/);

console.log('PSC2_LEAN_KERNEL_WASM_SINGLE_THREAD_CONTRACT: PASS');
