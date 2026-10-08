import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {mkdtemp,readFile,rm,writeFile} from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {normalizeShellExitCodes} from './apply-shell-exit-code.mjs';

const here=path.dirname(fileURLToPath(import.meta.url));
const leanSource=path.resolve(here,'../../../../study/lean4-4.34.0');
const build=await readFile(path.join(here,'build-wasm.sh'),'utf8');
assert.match(build,/node "\$script_dir\/apply-shell-exit-code\.mjs" "\$lean_source"/);
assert.ok(build.indexOf('apply-shell-exit-code.mjs')<build.indexOf('cmake \\\n'),
  'normalize shell exit codes before native stage0 compilation');

function definition(source,name){
  const matches=[...source.matchAll(new RegExp(`^static inline [^\\n]*\\b${name}\\([^\\n]*\\) \\{`,'gm'))];
  assert.equal(matches.length,1,`${name}: pinned runtime definition must be unique`);
  const start=matches[0].index;
  let index=source.indexOf('{',start),depth=1;
  while(depth&&++index<source.length){
    if(source[index]==='{') depth++;
    else if(source[index]==='}') depth--;
  }
  assert.equal(depth,0,`${name}: unterminated definition`);
  return source.slice(start,index+1);
}
function success(command,args){
  const result=spawnSync(command,args,{encoding:'utf8',timeout:30000});
  assert.ifError(result.error);
  assert.equal(result.signal,null);
  assert.equal(result.status,0,`${command}: ${result.stdout}${result.stderr}`);
  return result;
}
const temp=await mkdtemp(path.join(os.tmpdir(),'psc2-shell-exit-'));
try{
  for(const prefix of ['stage0/src','src']){
    const shell=await readFile(path.join(leanSource,prefix,'util/shell.cpp'),'utf8');
    const fixed=normalizeShellExitCodes(shell,prefix);
    assert.equal(normalizeShellExitCodes(fixed,prefix),fixed,'rewrite must be idempotent');
    assert.match(fixed,/object_ref result = get_io_result<object_ref>\(lean_shell_main\(/);
    assert.match(fixed,/return lean_unbox_uint32\(result.raw\(\)\);/);
    assert.match(fixed,/rc = lean_unbox_uint32\(io_result_get_error\(r\)\);/);
    assert.doesNotMatch(fixed,/get_io_scalar_result<uint32>\(lean_shell_main/);
    const old=fixed.replace('object_ref result = get_io_result<object_ref>(lean_shell_main(',
      'return get_io_scalar_result<uint32>(lean_shell_main(')
      .replace('\n    return lean_unbox_uint32(result.raw());','')
      .replace('rc = lean_unbox_uint32(io_result_get_error(r));','rc = unbox(io_result_get_error(r));');
    for(const bad of [old.replace('get_io_scalar_result<uint32>','unrecognized_decoder'),
      old+'\n'+old,old+'\n'+fixed]){
      assert.throws(()=>normalizeShellExitCodes(bad),/missing or ambiguous/);
    }
    const header=await readFile(path.join(leanSource,prefix,'include/lean/lean.h'),'utf8');
    const helpers=['lean_box','lean_unbox','lean_box_uint32','lean_unbox_uint32']
      .map(name=>definition(header,name)).join('\n');
    // Execute the pinned boxing/decoding helpers with a tiny scalar allocator.
    // This tests return-value representation, not the full Lean frontend.
    const source=`#include <stdint.h>
#include <stddef.h>
typedef struct { int rc; unsigned short size; unsigned char other,tag; } lean_object;
typedef lean_object *lean_obj_res;
typedef lean_object *b_lean_obj_arg;
static struct { lean_object header; uint32_t value; } scalar;
static lean_object *lean_alloc_ctor(unsigned t,unsigned n,unsigned b){(void)t;(void)n;(void)b;return &scalar.header;}
static void lean_ctor_set_uint32(lean_object *o,size_t i,uint32_t v){*(uint32_t*)((char*)(o+1)+i)=v;}
static uint32_t lean_ctor_get_uint32(lean_object *o,size_t i){return *(uint32_t*)((char*)(o+1)+i);}
${helpers}
__attribute__((noreturn,force_align_arg_pointer)) void _start(void){
  const uint32_t cases[]={0,1,7,255,256,0x7fffffffU,0xffffffffU};
  int status=0;
  for(unsigned i=0;i<sizeof(cases)/sizeof(cases[0]);i++){
    lean_object *value=lean_box_uint32(cases[i]);
#ifdef OLD_DECODER
    uint32_t decoded=lean_unbox(value);
#else
    uint32_t decoded=lean_unbox_uint32(value);
#endif
    if(decoded!=cases[i]){status=42;break;}
  }
#if defined(__i386__)
  __asm__ volatile("int $0x80"::"a"(1),"b"(status):"memory");
#else
  __asm__ volatile("syscall"::"a"(60),"D"(status):"rcx","r11","memory");
#endif
  __builtin_unreachable();
}
`;
    const file=path.join(temp,'decode.c');
    await writeFile(file,source);
    for(const bits of [32,64]){
      for(const oldDecoder of [true,false]){
        const executable=path.join(temp,`decode-${bits}-${oldDecoder}`);
        success('clang',[`-m${bits}`,'-ffreestanding','-nostdlib','-static','-fno-pie',
          '-fno-stack-protector','-O1',...(oldDecoder?['-DOLD_DECODER']:[]),file,'-o',executable]);
        const result=spawnSync(executable,[],{encoding:'utf8',timeout:10000});
        assert.ifError(result.error);
        assert.equal(result.signal,null);
        assert.equal(result.status,oldDecoder&&bits===32?42:0,
          `${prefix}: ${bits}-bit ${oldDecoder?'old':'fixed'} UInt32 decoder`);
      }
    }
  }
  console.log('PSC2_LEAN_KERNEL_WASM_SHELL_EXIT_CODE_CONTRACT: PASS (native32/native64 pinned scalar helpers; both source rewrites; negative controls)');
}finally{
  await rm(temp,{recursive:true,force:true});
}
