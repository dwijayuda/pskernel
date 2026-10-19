import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const here=path.dirname(fileURLToPath(import.meta.url));
const rewrite=await readFile(path.join(here,'apply-wasm-abi.mjs'),'utf8');
const build=await readFile(path.join(here,'build-wasm.sh'),'utf8');

// Lean erases IO.RealWorld from generated C calls. Native C ABIs have long
// tolerated several runtime definitions that retain a trailing dummy world
// argument; typed WebAssembly does not. The build applies exact pinned-source
// rewrites and fails closed if Lean's source stops matching.
assert.match(build,/apply-wasm-abi\.mjs/);
assert.match(rewrite,/replaceExact/);
assert.match(rewrite,/pinned Lean ABI source missing/);
assert.match(rewrite,/ABI source is not unique/);

assert.match(rewrite,/src\/runtime\/io\.cpp/);
assert.match(rewrite,/LEAN_EMSCRIPTEN/);
assert.match(rewrite,/lean_io_create_tempfile\(\)/);
assert.match(rewrite,/lean_io_create_tempdir\(\)/);

// Shell's default-limit externs explicitly take Unit. Their C++ runtime
// definitions omit that argument; native C calling conventions tolerate the
// mismatch, but typed WebAssembly requires the exact (i32) -> i32 signature.
// Use the public lean.h argument typedef: runtime translation units do not all
// import the shorter C++ namespace alias `obj_arg`.
assert.match(rewrite,/src\/runtime\/memory\.cpp/);
assert.match(rewrite,/lean_internal_get_default_max_memory\(lean_obj_arg\)/);
assert.match(rewrite,/src\/runtime\/interrupt\.cpp/);
assert.match(rewrite,/lean_internal_get_default_max_heartbeat\(lean_obj_arg\)/);

assert.match(rewrite,/src\/library\/ir_interpreter\.cpp/);
assert.match(
  rewrite,
  /lean_run_init\(object \* env, object \* opts, object \* decl, object \* init_decl\)/,
);

assert.match(rewrite,/src\/library\/module\.cpp/);
assert.match(
  rewrite,
  /lean_compacted_region_read\(b_obj_arg ofname, b_obj_arg odep_regions\)/,
);
assert.match(
  rewrite,
  /lean_compacted_region_free\(obj_arg region\)/,
);
assert.match(rewrite,/uint8 allow_closures_u8\) \{/);

// Compile the scalar-literal regression before the expensive stage0 build.
await import('./scalar-literal-contract.test.mjs');
// Execute UInt32 boxing/exit-code regressions at both native pointer widths.
await import('./shell-exit-code-contract.test.mjs');
// Native i386 workers must fit their finite address space.
await import('./thread-stack-contract.test.mjs');

console.log('PSC2_LEAN_KERNEL_WASM_ABI_CONTRACT: PASS');
