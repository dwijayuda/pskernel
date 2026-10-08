import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {mkdtemp,mkdir,readFile,writeFile,rm} from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const here=path.dirname(fileURLToPath(import.meta.url));
const leanSource=path.resolve(here,'../../../../study/lean4-4.34.0');
const rewrite=path.join(here,'apply-wasm-abi.mjs');
const headers=['stage0/src/include/lean/lean.h','src/include/lean/lean.h'];
const sources=[...headers,
  'src/runtime/io.cpp','src/runtime/memory.cpp','src/runtime/interrupt.cpp',
  'src/library/ir_interpreter.cpp','src/library/module.cpp',
];
const originalGuard='#ifdef LEAN_EMSCRIPTEN\n#define LEAN_SCALAR_PTR_LITERAL';
const fixedGuard='#if UINTPTR_MAX == UINT32_MAX\n#define LEAN_SCALAR_PTR_LITERAL';
// The first vector is a compact Name hash in stage0 Lean/Parser/Level.c.
// The second checks adjacent literal boundaries, zeroes, and high bits.
const vectors=[[93,234,74,98,36,143,62,135],[0,1,127,128,254,255,2,3]];
const expected=Buffer.from(vectors.flat());
const temp=await mkdtemp(path.join(os.tmpdir(),'pskernel-scalar-literal-'));

function run(command,args){
  const result=spawnSync(command,args,{encoding:'utf8',timeout:30000});
  assert.ifError(result.error);
  assert.equal(result.signal,null,`${command}: ${result.signal}`);
  return result;
}
function success(command,args){
  const result=run(command,args);
  assert.equal(result.status,0,`${command} ${args.join(' ')}\n${result.stdout}${result.stderr}`);
  return result;
}
function macroBlock(source){
  const blocks=[...source.matchAll(/^#(?:ifdef LEAN_EMSCRIPTEN|if UINTPTR_MAX == UINT32_MAX)\n#define LEAN_SCALAR_PTR_LITERAL[^\n]*\n#else\n#define LEAN_SCALAR_PTR_LITERAL[^\n]*\n#endif/gm)];
  assert.equal(blocks.length,1,'pinned scalar literal macro must be unique');
  return blocks[0][0];
}

async function compilePayload(macro,mode,expectFailure=false){
  const source=path.join(temp,'literal.c');
  const object=path.join(temp,'literal.o');
  const bytes=path.join(temp,'literal.bin');
  await writeFile(source,`#include <stdint.h>
typedef struct lean_object lean_object;
${macro}
__attribute__((section(".pskernel_scalar"),used))
lean_object * const literals[] = {
${vectors.map(v=>`  LEAN_SCALAR_PTR_LITERAL(${v.join(',')})`).join(',\n')}
};
_Static_assert(sizeof(literals) == ${expected.length}, "literal must preserve eight scalar bytes");
`);
  // Dump ELF data instead of executing i386 code: this also runs on hosts
  // without a 32-bit userspace. The Emscripten case checks its preprocessor
  // branch at the same pointer width, not a real provider/WASM runtime.
  const flags=mode==='native64'?['-m64']:['-m32'];
  if(mode==='emscripten32-layout') flags.push('-DLEAN_EMSCRIPTEN');
  const result=run('clang',[...flags,'-ffreestanding','-c',source,'-o',object]);
  if(expectFailure){
    assert.notEqual(result.status,0,'unpatched native i386 must expose the truncation');
    assert.match(result.stderr,/literal must preserve eight scalar bytes/);
    return;
  }
  assert.equal(result.status,0,`${mode}: ${result.stdout}${result.stderr}`);
  await rm(bytes,{force:true});
  success('objcopy',['--dump-section',`.pskernel_scalar=${bytes}`,object]);
  assert.deepEqual(await readFile(bytes),expected,`${mode}: scalar bytes/order changed`);
}

try{
  for(const relative of sources){
    const file=path.join(temp,relative);
    await mkdir(path.dirname(file),{recursive:true});
    await writeFile(file,await readFile(path.join(leanSource,relative)));
  }
  for(const relative of headers){
    // Permit rerunning after a local build has already applied the rewrite;
    // restore only the known old guard in the temporary negative fixture.
    const macro=macroBlock(await readFile(path.join(temp,relative),'utf8'))
      .replace(fixedGuard,originalGuard);
    await compilePayload(macro,'native32',true);
    await compilePayload(macro,'native64');
    await compilePayload(macro,'emscripten32-layout');
  }
  success(process.execPath,[rewrite,temp]);
  const patched=await Promise.all(sources.map(f=>readFile(path.join(temp,f),'utf8')));
  success(process.execPath,[rewrite,temp]);
  assert.deepEqual(await Promise.all(sources.map(f=>readFile(path.join(temp,f),'utf8'))),
    patched,'ABI rewrites must be idempotent');
  for(const [index,relative] of headers.entries()){
    const file=path.join(temp,relative);
    const text=patched[index];
    const macro=macroBlock(text);
    for(const mode of ['native32','native64','emscripten32-layout']){
      await compilePayload(macro,mode);
    }
    assert.ok(macro.startsWith(fixedGuard),`${relative}: select layout by pointer width`);
    // Source drift must fail closed rather than silently omitting this fix.
    for(const bad of [text.replace(macro,''),
      text.replace(macro,`${macro.replace(fixedGuard,originalGuard)}\n${macro.replace(fixedGuard,originalGuard)}`)]){
      await writeFile(file,bad);
      const result=run(process.execPath,[rewrite,temp]);
      assert.notEqual(result.status,0,`${relative}: missing/ambiguous macro must fail`);
      assert.match(result.stderr,/pinned Lean ABI source missing|ABI source is not unique/);
    }
    await writeFile(file,text);
  }
  console.log('PSC2_LEAN_KERNEL_WASM_SCALAR_LITERAL_CONTRACT: PASS (both headers; native32/native64/Emscripten-layout bytes; negative controls; idempotence)');
}finally{
  await rm(temp,{recursive:true,force:true});
}
