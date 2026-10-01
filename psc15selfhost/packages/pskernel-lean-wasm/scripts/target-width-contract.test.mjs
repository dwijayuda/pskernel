import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const here=path.dirname(fileURLToPath(import.meta.url));
const packageRoot=path.resolve(here,'..');
const repoRoot=path.resolve(packageRoot,'../../..');
const build=await readFile(path.join(here,'build-wasm.sh'),'utf8');
const workflow=await readFile(path.join(repoRoot,'.github/workflows/psc2-lean-kernel-wasm.yml'),'utf8');

// Lean 4.34's own WASM CI recipe requires a runnable native 32-bit stage0.
// Stage0 is the target-width code emitter, while wasm32 stage1 make_stdlib
// produces the matching .olean sysroot consumed when compiling provider code.
// An installed x86_64 Lean is valid for version/pin checks only.
assert.match(build,/-S "\$lean_source"(?:\s|\\)/,'WASM build must configure Lean from the top-level staged build');
assert.doesNotMatch(build,/-S "\$lean_source\/src"/,'direct src/ stage1 build bypasses the target-width bootstrap');
assert.match(build,/-DSTAGE0_USE_GMP=OFF/);
assert.match(build,/-DSTAGE0_LEAN_EXTRA_CXX_FLAGS=['"]?-m32/);
assert.match(build,/-DSTAGE0_LEANC_OPTS=['"]?-m32/);
assert.doesNotMatch(build,/-DSTAGE0_CMAKE_C_FLAGS=/,'match Lean 4.34 WASM bootstrap: do not override stage0 global C flags');
assert.doesNotMatch(build,/-DSTAGE0_CMAKE_CXX_FLAGS=/,'match Lean 4.34 WASM bootstrap: do not override stage0 global C++ flags');
assert.match(build,/-DSTAGE0_CMAKE_CXX_COMPILER=clang\+\+/);
assert.match(build,/-DSTAGE0_CMAKE_C_COMPILER=clang/);
assert.match(build,/-DSTAGE0_CMAKE_EXECUTABLE_SUFFIX=['"]?['"]?/);
assert.match(build,/-DSTAGE0_MMAP=OFF/);
assert.match(build,/-DSTAGE0_CMAKE_LIBRARY_PATH=\/usr\/lib\/i386-linux-gnu\//);
assert.match(build,/-DSTAGE0_PKG_CONFIG_EXECUTABLE=\/usr\/bin\/i386-linux-gnu-pkg-config/);
assert.match(build,/--target stage1-configure/);
assert.match(build,/stage0_lean="\$lean_build\/stage0\/bin\/lean"/);
assert.match(build,/stage1_build="\$lean_build\/stage1"/);
assert.match(build,/stage1_lean_path="\$stage1_build\/lib\/lean"/);
assert.match(build,/stage1_leanc="\$stage1_build\/leanc\.sh"/);
assert.match(build,/if \[\[ ! -x "\$stage0_lean" \]\]/,'stage0 readiness must require the runnable compiler, not nonexistent stage0 oleans');
assert.match(build,/"\$stage0_lean" --deps "\$lean_source\/src\/Lean\.lean"/,'stage0 must prove its frontend/parser initialization before the expensive stage1 stdlib build');
assert.doesNotMatch(build,/stage0_lean_path\/Lean\.olean/,'stage0 C_ONLY build must not be treated as an olean sysroot');
assert.match(build,/stage1_lean_path\/Lean\.olean/,'provider compile must require the wasm32 stage1 olean sysroot');
assert.match(build,/LEAN_PATH="\$provider_olean_dir:\$stage1_lean_path"/,'provider imports must resolve against target-width stage1 oleans');
assert.match(build,/"\$stage0_lean"[\s\S]*--c=/,'provider modules must be emitted by native 32-bit Lean stage0');
assert.doesNotMatch(build,/"\$host_lean"[\s\S]{0,240}--c=/,'x86_64 host Lean must not emit provider C for wasm32');
assert.doesNotMatch(build,/-DPREV_STAGE="\$host_lean_prefix"/,'wasm32 build must not use the x86_64 installed Lean as PREV_STAGE');

// The native stage0 is an i386 executable and must have its matching build
// dependencies available on the GitHub runner.
for(const required of [
  'sudo dpkg --add-architecture i386',
  'gcc-multilib',
  'g++-multilib',
  'libuv1-dev:i386',
  'libssl-dev:i386',
  'pkgconf:i386',
  '/usr/bin/i386-linux-gnu-pkg-config',
]){
  assert.ok(workflow.includes(required),`WASM workflow is missing target-width prerequisite: ${required}`);
}

// Exercise the early probe with empty target roots and failing compilers.
await import('./frontend-probe-contract.test.mjs');

console.log('PSC2_LEAN_KERNEL_WASM_TARGET_WIDTH_CONTRACT: PASS');
