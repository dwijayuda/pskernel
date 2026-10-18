// Guarded, pinned-Lean-4.35.0 C++ ABI source check. This preflight checks
// the precise no-libuv fallback signature and surrounding declaration
// identities before we spend hours on the i386/wasm32 staged build. It does
// not replace a real C++ compile, a kernel check, or parity qualification.
import {readFile} from 'node:fs/promises';
import path from 'node:path';
const root=process.argv[2];
if(!root)throw Error('usage: node verify-lean435-runtime.mjs <pinned-lean-source-root>');
const read=rel=>readFile(path.join(root,rel),'utf8');
const header=await read('src/runtime/uv/system.h');
const source=await read('src/runtime/uv/system.cpp');
const declaration='extern "C" LEAN_EXPORT lean_obj_res lean_uv_os_get_group(uint64_t gid);';
const definition='extern "C" LEAN_EXPORT lean_obj_res lean_uv_os_get_group(uint64_t gid) {';
const fallback='extern "C" LEAN_EXPORT lean_obj_res lean_uv_os_get_group(uint64_t /* gid */) {';
const occurrences=(str,needle)=>str.split(needle).length-1;
if(occurrences(header,declaration)!==1)throw Error('Lean 4.35.0 libuv header ABI differs');
if(occurrences(source,definition)!==1 || occurrences(source,fallback)!==1)
  throw Error('Lean 4.35.0 real/fallback libuv ABI mismatch');
if(source.includes('lean_uv_os_get_group() {'))
  throw Error('Lean 4.35.0 no-libuv old parameterless ABI remains');
// The fallback remains unsupported and must never silently claim success.
const after=source.slice(source.indexOf(fallback)+fallback.length);
if(!after.slice(0,280).includes('lean_always_assert(') ||
   !after.slice(0,280).includes('Please build a version of Lean4 with libuv'))
  throw Error('unsupported no-libuv fallback behavior was unexpectedly changed');
console.log('PSC0_LEAN435_RUNTIME_ABI: verified exact no-libuv fallback');
