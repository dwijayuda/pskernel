// Exact Lean 4.35.0-only compatibility fixes. Never patch the PSC0 working
// tree. The caller fetches a clean pinned upstream Lean checkout first.
import {readFile,writeFile} from 'node:fs/promises';
import path from 'node:path';
const root=process.argv[2];
if(!root)throw new Error('usage: node apply-lean435-compat.mjs <exact-lean4-src>');
async function modify(rel,changes){
  const file=path.join(root,rel);
  let data=await readFile(file,'utf8');
  for(const [label,from,to] of changes){
    const count=data.split(from).length-1;
    const newCount=data.split(to).length-1;
    if(count===0&&newCount===1)continue;
    if(count!==1)throw new Error(rel+': exact Lean 4.35 source mismatch for '+label+' (found '+count+')');
    data=data.replace(from,to);
  }
  await writeFile(file,data);
}
const emscriptenSettings='  set(EMSCRIPTEN_SETTINGS "-s ALLOW_MEMORY_GROWTH=1 -fwasm-exceptions -pthread -flto")\n  string(APPEND LEANC_EXTRA_CC_FLAGS " -pthread")';
await modify('src/CMakeLists.txt',[
  ['single-threaded kernel-only Emscripten',emscriptenSettings,
   '  set(EMSCRIPTEN_SETTINGS "-s ALLOW_MEMORY_GROWTH=1 -fwasm-exceptions")\n  if(MULTI_THREAD)\n    string(APPEND EMSCRIPTEN_SETTINGS " -pthread")\n    string(APPEND LEANC_EXTRA_CC_FLAGS " -pthread")\n  endif()'],
  ['Leanc target cannot cross execute','  LeanExport\n  Leanc\n  LeanIR\n)\nif(NOT CMAKE_SYSTEM_NAME MATCHES "Emscripten")\n  list(APPEND STDLIBS Lake LeanChecker)',
   '  LeanExport\n  LeanIR\n)\nif(NOT CMAKE_SYSTEM_NAME MATCHES "Emscripten")\n  list(APPEND STDLIBS Leanc Lake LeanChecker)'],
]);
await modify('src/runtime/thread.h',[
  ['no-thread mutex include','#include <utility>\n#include <cstdlib>\n#define LEAN_THREAD_LOCAL',
   '#include <utility>\n#include <cstdlib>\n#include <mutex>\n#define LEAN_THREAD_LOCAL'],
]);
for(const rel of ['src/include/lean/lean.h','stage0/src/include/lean/lean.h']){
  await modify(rel,[['32bit scalar literals','#ifdef LEAN_EMSCRIPTEN\n#define LEAN_SCALAR_PTR_LITERAL',
    '#if UINTPTR_MAX == UINT32_MAX\n#define LEAN_SCALAR_PTR_LITERAL']]);
}
for(const rel of ['src/util/shell.cpp','stage0/src/util/shell.cpp']){
  await modify(rel,[
    ['boxed UInt32 shell status','    return get_io_scalar_result<uint32>(lean_shell_main(\n        args.steal(),\n        shell_opts.to_obj_arg()\n    ));',
     '    object_ref result = get_io_result<object_ref>(lean_shell_main(\n        args.steal(),\n        shell_opts.to_obj_arg()\n    ));\n    return lean_unbox_uint32(result.raw());'],
    ['boxed shell option error','        rc = unbox(io_result_get_error(r));',
     '        rc = lean_unbox_uint32(io_result_get_error(r));'],
  ]);
}
await modify('src/kernel/init_module.cpp',[
  ['explicit kernel-only init','#include "kernel/init_module.h"',
    '#if defined(LEAN_EMSCRIPTEN)\n#include "runtime/stackinfo.h"\n#include "util/init_module.h"\n#endif\n#include "kernel/init_module.h"'],
  ['kernel-only lean_initialize','namespace lean {\nvoid initialize_kernel_module() {',
    'namespace lean {\n#if defined(LEAN_EMSCRIPTEN)\nstatic bool g_pskernel_initialized = false;\nextern "C" LEAN_EXPORT void lean_initialize() {\n    if (g_pskernel_initialized) return;\n    g_pskernel_initialized = true;\n    save_stack_info();\n    initialize_util_module();\n    initialize_kernel_module();\n}\n#endif\nvoid initialize_kernel_module() {'],
]);
await modify('src/runtime/io.cpp',[
  ['tempfile erased world','extern "C" LEAN_EXPORT obj_res lean_io_create_tempfile(lean_object * /* w */) {',
    '#if defined(LEAN_EMSCRIPTEN)\nextern "C" LEAN_EXPORT obj_res lean_io_create_tempfile() {\n#else\nextern "C" LEAN_EXPORT obj_res lean_io_create_tempfile(lean_object * /* w */) {\n#endif'],
  ['tempdir erased world','extern "C" LEAN_EXPORT obj_res lean_io_create_tempdir(lean_object * /* w */) {',
    '#if defined(LEAN_EMSCRIPTEN)\nextern "C" LEAN_EXPORT obj_res lean_io_create_tempdir() {\n#else\nextern "C" LEAN_EXPORT obj_res lean_io_create_tempdir(lean_object * /* w */) {\n#endif'],
]);
await modify('src/runtime/memory.cpp',[
  ['default max memory Unit ABI','extern "C" LEAN_EXPORT lean_obj_res lean_internal_get_default_max_memory() {',
    '#if defined(LEAN_EMSCRIPTEN)\nextern "C" LEAN_EXPORT lean_obj_res lean_internal_get_default_max_memory(lean_obj_arg) {\n#else\nextern "C" LEAN_EXPORT lean_obj_res lean_internal_get_default_max_memory() {\n#endif'],
]);
await modify('src/runtime/interrupt.cpp',[
  ['default heartbeat Unit ABI','extern "C" LEAN_EXPORT obj_res lean_internal_get_default_max_heartbeat() {',
    '#if defined(LEAN_EMSCRIPTEN)\nextern "C" LEAN_EXPORT obj_res lean_internal_get_default_max_heartbeat(lean_obj_arg) {\n#else\nextern "C" LEAN_EXPORT obj_res lean_internal_get_default_max_heartbeat() {\n#endif'],
]);
await modify('src/library/ir_interpreter.cpp',[
  ['run-init erased world','extern "C" LEAN_EXPORT object * lean_run_init(object * env, object * opts, object * decl, object * init_decl, object *) {',
   '#if defined(LEAN_EMSCRIPTEN)\nextern "C" LEAN_EXPORT object * lean_run_init(object * env, object * opts, object * decl, object * init_decl) {\n#else\nextern "C" LEAN_EXPORT object * lean_run_init(object * env, object * opts, object * decl, object * init_decl, object *) {\n#endif'],
]);
await modify('src/library/module.cpp',[
  ['region save ABI','extern "C" LEAN_EXPORT object * lean_compacted_region_save(b_obj_arg ofname, b_obj_arg mod, b_obj_arg odata,\n                                                           b_obj_arg odep_regions, obj_arg oprev,\n                                                           uint8 allow_closures_u8, object *) {',
    '#if defined(LEAN_EMSCRIPTEN)\nextern "C" LEAN_EXPORT object * lean_compacted_region_save(b_obj_arg ofname, b_obj_arg mod, b_obj_arg odata,\n                                                           b_obj_arg odep_regions, obj_arg oprev,\n                                                           uint8 allow_closures_u8) {\n#else\nextern "C" LEAN_EXPORT object * lean_compacted_region_save(b_obj_arg ofname, b_obj_arg mod, b_obj_arg odata,\n                                                           b_obj_arg odep_regions, obj_arg oprev,\n                                                           uint8 allow_closures_u8, object *) {\n#endif'],
  ['region read ABI','extern "C" LEAN_EXPORT object * lean_compacted_region_read(b_obj_arg ofname, b_obj_arg odep_regions, object *) {',
   '#if defined(LEAN_EMSCRIPTEN)\nextern "C" LEAN_EXPORT object * lean_compacted_region_read(b_obj_arg ofname, b_obj_arg odep_regions) {\n#else\nextern "C" LEAN_EXPORT object * lean_compacted_region_read(b_obj_arg ofname, b_obj_arg odep_regions, object *) {\n#endif'],
  ['region free ABI','extern "C" LEAN_EXPORT obj_res lean_compacted_region_free(obj_arg region, object *) {',
   '#if defined(LEAN_EMSCRIPTEN)\nextern "C" LEAN_EXPORT obj_res lean_compacted_region_free(obj_arg region) {\n#else\nextern "C" LEAN_EXPORT obj_res lean_compacted_region_free(obj_arg region, object *) {\n#endif'],
]);
console.log('PSC0_LEAN435_EMSCRIPTEN_COMPAT: exact source rewrites applied');
