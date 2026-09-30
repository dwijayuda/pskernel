import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const here=path.dirname(fileURLToPath(import.meta.url));
const build=await readFile(path.join(here,'build-wasm.sh'),'utf8');

// The provider's generated Lean entry point initializes its own import graph.
// Do not link Lean's global C++ initialize.cpp, which eagerly initializes the
// entire Lean frontend (including parser categories) before provider main.
assert.match(
  build,
  /lib\/temp\/libleancpp_1\.a/,
  'WASM provider must verify Lean\'s leancpp archive without initialize.cpp',
);
assert.match(
  build,
  /\n  -lleancpp_1 \\\n/,
  'final WASM provider link must use leancpp_1',
);
assert.doesNotMatch(
  build,
  /\n  -lleancpp \\\n/,
  'final WASM provider link must not use leancpp with global Lean initialization',
);

console.log('PSC2_LEAN_KERNEL_WASM_KERNEL_ONLY_LINK_CONTRACT: PASS');
