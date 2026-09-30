import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const here=path.dirname(fileURLToPath(import.meta.url));
const packageRoot=path.resolve(here,'..');
const patch=await readFile(
  path.join(packageRoot,'patches/lean4-4.34.0-emscripten-uv-stubs.patch'),
  'utf8',
);

// Lean erases IO.RealWorld from generated C calls. Native C ABIs have long
// tolerated several runtime definitions that retain a trailing dummy world
// argument; typed WebAssembly does not. Keep the native ABI untouched while
// making the Emscripten definitions match generated Lean C exactly.
assert.match(patch,/src\/runtime\/io\.cpp/);
assert.match(patch,/LEAN_EMSCRIPTEN/);
assert.match(patch,/lean_io_create_tempfile\(\)/);
assert.match(patch,/lean_io_create_tempdir\(\)/);

assert.match(patch,/src\/library\/ir_interpreter\.cpp/);
assert.match(
  patch,
  /lean_run_init\(object \* env, object \* opts, object \* decl, object \* init_decl\)/,
);

assert.match(patch,/src\/library\/module\.cpp/);
assert.match(
  patch,
  /lean_compacted_region_read\(b_obj_arg ofname, b_obj_arg odep_regions\)/,
);
assert.match(
  patch,
  /lean_compacted_region_free\(obj_arg region\)/,
);
assert.match(
  patch,
  /uint8 allow_closures_u8\)/,
);

console.log('PSC2_LEAN_KERNEL_WASM_ABI_CONTRACT: PASS');
