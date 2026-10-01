import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const here=path.dirname(fileURLToPath(import.meta.url));
const build=await readFile(path.join(here,'build-wasm.sh'),'utf8');
const patch=await readFile(
  path.join(here,'../patches/lean4-4.34.0-emscripten-uv-stubs.patch'),
  'utf8',
);

// Every Lean-generated module calls lean_initialize() before walking its own
// import graph. Linking Lean's stock initialize.cpp would also call
// initialize_Lean and eagerly root the entire Lean umbrella. Keep libleancpp_1
// (which excludes initialize.cpp), and provide an Emscripten-only definition in
// the already-linked kernel init translation unit. That shim initializes only
// stack/runtime/util + the C++ kernel; generated Lean module initializers remain
// responsible for Init/Std/Lean.Environment.
assert.match(
  patch,
  /src\/kernel\/init_module\.cpp/u,
  'compatibility patch must carry the kernel-only initializer shim',
);
assert.match(
  patch,
  /extern\s+"C"\s+LEAN_EXPORT\s+void\s+lean_initialize\s*\(\s*\)/u,
);
assert.match(patch,/save_stack_info\s*\(\s*\)/u);
assert.match(patch,/initialize_util_module\s*\(\s*\)/u);
assert.match(patch,/initialize_kernel_module\s*\(\s*\)/u);
assert.doesNotMatch(patch,/initialize_Lean\s*\(/u);
assert.doesNotMatch(patch,/initialize_library_/u);

// Do not build Lean's full ALL graph. The stock initialize.cpp target and the
// kernel-only shim both define lean_initialize, so building shell/shared targets
// would deliberately collide. In the staged bootstrap these prerequisites live
// in the configured wasm32 stage1 build directory.
assert.match(
  build,
  /cmake\s+--build\s+"\$stage1_build"\s+--target\s+make_stdlib\s+leanrt\s+leancpp_1\s+-j2/u,
  'WASM stage1 build must stop at the static kernel/provider prerequisites',
);
assert.doesNotMatch(
  build,
  /cmake\s+--build\s+"\$stage1_build"\s+-j2/u,
  'WASM stage1 build must not invoke the full default Lean ALL graph',
);

assert.match(
  build,
  /stage1_build\/lib\/temp\/libleancpp_1\.a|\$stage1_build\/lib\/temp\/libleancpp_1\.a/u,
  'WASM provider must verify Lean\'s stage1 leancpp archive without initialize.cpp',
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
