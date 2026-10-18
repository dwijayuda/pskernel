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
const tasks=await read('src/runtime/object.cpp');
const schedulerBoundary='extern "C" LEAN_EXPORT obj_res lean_task_spawn_core(obj_arg c, unsigned prio, bool keep_alive)';
const patchedInline='if (!g_task_manager) {\n#if defined(LEAN_EMSCRIPTEN)\n        // Match task_manager::run_task: reset only the C++ kernel counter.\n        reset_heartbeat();\n#endif\n        return lean_task_pure(apply_1(c, box(0)));';
if(occurrences(tasks,schedulerBoundary)!==1 || occurrences(tasks,patchedInline)!==1)
  throw Error('Lean 4.35.0 wasm32 inline task heartbeat boundary differs');
// The native task manager already resets this kernel counter on task entry.
// Keep the Emscripten-only change localized: no unchecked addDecl API,
// no absolute 0/0 admission budget and no fabricated proof verdicts.
if(!tasks.includes('void run_task(unique_lock<mutex> & lock, lean_task_object * t) {') ||
   !tasks.includes('        reset_heartbeat();\n        object * v = nullptr;'))
  throw Error('Lean 4.35.0 native task reset contract differs');
console.log('PSC0_LEAN435_WASM_TASK_HEARTBEAT: verified native-equivalent inline reset');

console.log('PSC0_LEAN435_RUNTIME_ABI: verified exact no-libuv fallback');
