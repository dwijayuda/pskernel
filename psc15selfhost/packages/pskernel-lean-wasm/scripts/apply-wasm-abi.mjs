import {readFile,writeFile} from 'node:fs/promises';
import path from 'node:path';

const leanSource=process.argv[2];
if(!leanSource){
  throw new Error('usage: node apply-wasm-abi.mjs <lean-source-root>');
}

async function replaceExact(relativePath,replacements){
  const file=path.join(leanSource,relativePath);
  let source=await readFile(file,'utf8');
  for(const {from,to,label} of replacements){
    if(source.includes(to)) continue;
    const first=source.indexOf(from);
    if(first<0){
      throw new Error(`${relativePath}: pinned Lean ABI source missing for ${label}`);
    }
    if(source.indexOf(from,first+from.length)>=0){
      throw new Error(`${relativePath}: ABI source is not unique for ${label}`);
    }
    source=source.slice(0,first)+to+source.slice(first+from.length);
  }
  await writeFile(file,source);
}

await replaceExact('src/runtime/io.cpp',[
  {
    label:'lean_io_create_tempfile',
    from:'extern "C" LEAN_EXPORT obj_res lean_io_create_tempfile(lean_object * /* w */) {',
    to:'#if defined(LEAN_EMSCRIPTEN)\nextern "C" LEAN_EXPORT obj_res lean_io_create_tempfile() {\n#else\nextern "C" LEAN_EXPORT obj_res lean_io_create_tempfile(lean_object * /* w */) {\n#endif',
  },
  {
    label:'lean_io_create_tempdir',
    from:'extern "C" LEAN_EXPORT obj_res lean_io_create_tempdir(lean_object * /* w */) {',
    to:'#if defined(LEAN_EMSCRIPTEN)\nextern "C" LEAN_EXPORT obj_res lean_io_create_tempdir() {\n#else\nextern "C" LEAN_EXPORT obj_res lean_io_create_tempdir(lean_object * /* w */) {\n#endif',
  },
]);

// Lean/Shell.lean declares both default-limit externs as (_ : Unit) : Nat.
// The native runtime definitions omit the Unit argument; ordinary native C
// calling conventions tolerate that mismatch, but WebAssembly function types
// do not. Preserve the pinned native definitions and add the ignored Unit
// object only in the Emscripten build. Use lean_obj_arg from lean/lean.h rather
// than the shorter C++ namespace alias, which is not visible in every runtime
// translation unit.
await replaceExact('src/runtime/memory.cpp',[
  {
    label:'lean_internal_get_default_max_memory',
    from:'extern "C" LEAN_EXPORT lean_obj_res lean_internal_get_default_max_memory() {',
    to:'#if defined(LEAN_EMSCRIPTEN)\nextern "C" LEAN_EXPORT lean_obj_res lean_internal_get_default_max_memory(lean_obj_arg) {\n#else\nextern "C" LEAN_EXPORT lean_obj_res lean_internal_get_default_max_memory() {\n#endif',
  },
]);

await replaceExact('src/runtime/interrupt.cpp',[
  {
    label:'lean_internal_get_default_max_heartbeat',
    from:'extern "C" LEAN_EXPORT obj_res lean_internal_get_default_max_heartbeat() {',
    to:'#if defined(LEAN_EMSCRIPTEN)\nextern "C" LEAN_EXPORT obj_res lean_internal_get_default_max_heartbeat(lean_obj_arg) {\n#else\nextern "C" LEAN_EXPORT obj_res lean_internal_get_default_max_heartbeat() {\n#endif',
  },
]);

await replaceExact('src/library/ir_interpreter.cpp',[
  {
    label:'lean_run_init',
    from:'extern "C" LEAN_EXPORT object * lean_run_init(object * env, object * opts, object * decl, object * init_decl, object *) {',
    to:'#if defined(LEAN_EMSCRIPTEN)\nextern "C" LEAN_EXPORT object * lean_run_init(object * env, object * opts, object * decl, object * init_decl) {\n#else\nextern "C" LEAN_EXPORT object * lean_run_init(object * env, object * opts, object * decl, object * init_decl, object *) {\n#endif',
  },
]);

await replaceExact('src/library/module.cpp',[
  {
    label:'lean_compacted_region_save',
    from:'extern "C" LEAN_EXPORT object * lean_compacted_region_save(b_obj_arg ofname, b_obj_arg mod, b_obj_arg odata,\n                                                           b_obj_arg odep_regions, obj_arg oprev,\n                                                           uint8 allow_closures_u8, object *) {',
    to:'#if defined(LEAN_EMSCRIPTEN)\nextern "C" LEAN_EXPORT object * lean_compacted_region_save(b_obj_arg ofname, b_obj_arg mod, b_obj_arg odata,\n                                                           b_obj_arg odep_regions, obj_arg oprev,\n                                                           uint8 allow_closures_u8) {\n#else\nextern "C" LEAN_EXPORT object * lean_compacted_region_save(b_obj_arg ofname, b_obj_arg mod, b_obj_arg odata,\n                                                           b_obj_arg odep_regions, obj_arg oprev,\n                                                           uint8 allow_closures_u8, object *) {\n#endif',
  },
  {
    label:'lean_compacted_region_read',
    from:'extern "C" LEAN_EXPORT object * lean_compacted_region_read(b_obj_arg ofname, b_obj_arg odep_regions, object *) {',
    to:'#if defined(LEAN_EMSCRIPTEN)\nextern "C" LEAN_EXPORT object * lean_compacted_region_read(b_obj_arg ofname, b_obj_arg odep_regions) {\n#else\nextern "C" LEAN_EXPORT object * lean_compacted_region_read(b_obj_arg ofname, b_obj_arg odep_regions, object *) {\n#endif',
  },
  {
    label:'lean_compacted_region_free',
    from:'extern "C" LEAN_EXPORT obj_res lean_compacted_region_free(obj_arg region, object *) {',
    to:'#if defined(LEAN_EMSCRIPTEN)\nextern "C" LEAN_EXPORT obj_res lean_compacted_region_free(obj_arg region) {\n#else\nextern "C" LEAN_EXPORT obj_res lean_compacted_region_free(obj_arg region, object *) {\n#endif',
  },
]);

// Compact literals serialize eight scalar bytes into pointer-sized slots.
// Native i386 stage0 needs the same two-slot layout as wasm32. Selecting only
// LEAN_EMSCRIPTEN truncates compact Name hashes before parser initialization.
// Keep the 64-bit layout and all runtime platform guards unchanged.
for(const header of ['stage0/src/include/lean/lean.h','src/include/lean/lean.h']){
  await replaceExact(header,[{
    label:'target-width scalar pointer literals',
    from:'#ifdef LEAN_EMSCRIPTEN\n#define LEAN_SCALAR_PTR_LITERAL',
    to:'#if UINTPTR_MAX == UINT32_MAX\n#define LEAN_SCALAR_PTR_LITERAL',
  }]);
}

console.log('PSC2_LEAN_KERNEL_WASM_ABI_REWRITE: PASS');
