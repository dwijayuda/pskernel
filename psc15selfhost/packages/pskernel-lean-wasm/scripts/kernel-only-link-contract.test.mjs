import assert from 'node:assert/strict';
import {existsSync} from 'node:fs';
import {readFile} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const here=path.dirname(fileURLToPath(import.meta.url));
const build=await readFile(path.join(here,'build-wasm.sh'),'utf8');
const initializerPath=path.join(here,'kernel-initialize.cpp');

// Generated Lean module initializers call lean_initialize() before walking their
// own import graph. The WASM provider therefore needs the symbol, but linking
// Lean's stock initialize.cpp would eagerly initialize the entire Lean umbrella.
// Require a tiny provider-local implementation that initializes only the C/C++
// runtime substrate needed by the kernel. Generated Lean code remains
// responsible for Init/Std/Lean.Environment module initialization.
assert.equal(
  existsSync(initializerPath),
  true,
  'WASM provider must provide a kernel-only lean_initialize implementation',
);
const initializer=await readFile(initializerPath,'utf8');
assert.match(initializer,/extern\s+"C"\s+LEAN_EXPORT\s+void\s+lean_initialize\s*\(\s*\)/u);
assert.match(initializer,/save_stack_info\s*\(\s*\)/u);
assert.match(initializer,/initialize_util_module\s*\(\s*\)/u);
assert.match(initializer,/initialize_kernel_module\s*\(\s*\)/u);
assert.doesNotMatch(initializer,/initialize_Lean\s*\(/u);
assert.doesNotMatch(initializer,/initialize_library_/u);

assert.match(
  build,
  /lib\/temp\/libleancpp_1\.a/,
  'WASM provider must verify Lean\'s leancpp archive without initialize.cpp',
);
assert.match(
  build,
  /kernel-initialize\.cpp/u,
  'WASM build must compile the kernel-only initializer',
);
assert.match(
  build,
  /kernel-initialize\.o/u,
  'WASM build must link the kernel-only initializer object',
);
assert.match(
  build,
  /\n  -lleancpp_1 \\\n/u,
  'final WASM provider link must use leancpp_1',
);
assert.doesNotMatch(
  build,
  /\n  -lleancpp \\\n/u,
  'final WASM provider link must not use leancpp with global Lean initialization',
);

console.log('PSC2_LEAN_KERNEL_WASM_KERNEL_ONLY_LINK_CONTRACT: PASS');
