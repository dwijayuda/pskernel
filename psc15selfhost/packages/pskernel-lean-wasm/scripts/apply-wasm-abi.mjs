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

console.log('PSC2_LEAN_KERNEL_WASM_ABI_REWRITE: PASS');
