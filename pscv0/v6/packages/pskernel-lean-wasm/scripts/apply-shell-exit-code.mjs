import {readFile,writeFile} from 'node:fs/promises';
import path from 'node:path';
import {pathToFileURL} from 'node:url';

const replacements=[
  {
    from:`    return get_io_scalar_result<uint32>(lean_shell_main(
        args.steal(),
        shell_opts.to_obj_arg()
    ));`,
    to:`    object_ref result = get_io_result<object_ref>(lean_shell_main(
        args.steal(),
        shell_opts.to_obj_arg()
    ));
    return lean_unbox_uint32(result.raw());`,
  },
  {
    from:'        rc = unbox(io_result_get_error(r));',
    to:'        rc = lean_unbox_uint32(io_result_get_error(r));',
  },
];

// Both shell APIs return UInt32, which is heap-boxed on 32-bit platforms.
// Generic pointer unboxing returns address bits instead of an exit status.
// Keep normal IO error propagation and object ownership in get_io_result.
export function normalizeShellExitCodes(source,label='shell.cpp'){
  for(const {from,to} of replacements){
    const oldCount=source.split(from).length-1;
    const newCount=source.split(to).length-1;
    if(oldCount===0&&newCount===1) continue;
    if(oldCount!==1||newCount!==0){
      throw new Error(`${label}: missing or ambiguous pinned shell exit-code source`);
    }
    source=source.replace(from,to);
  }
  return source;
}

if(process.argv[1]&&pathToFileURL(path.resolve(process.argv[1])).href===import.meta.url){
  const root=process.argv[2];
  if(!root) throw new Error('usage: node apply-shell-exit-code.mjs <lean-source-root>');
  // Validate both exact source files before writing either one.
  const changes=await Promise.all(['stage0/src/util/shell.cpp','src/util/shell.cpp'].map(async relative=>{
    const file=path.join(root,relative);
    const before=await readFile(file,'utf8');
    return {file,before,after:normalizeShellExitCodes(before,relative)};
  }));
  for(const {file,before,after} of changes){
    if(before!==after) await writeFile(file,after);
  }
  console.log('PSC2_LEAN_KERNEL_WASM_SHELL_EXIT_CODE_REWRITE: PASS');
}
