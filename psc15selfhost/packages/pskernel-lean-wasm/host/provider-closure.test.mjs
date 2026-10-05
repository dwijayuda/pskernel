import assert from 'node:assert/strict';
import { mkdtemp, mkdir, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { resolveProviderModules } from '../scripts/resolve-provider-modules.mjs';

const temp=await mkdtemp(path.join(os.tmpdir(),'psc2-provider-closure-'));
const write=async(moduleName,source)=>{
  const file=path.join(temp,...moduleName.split('.'))+'.lean';
  await mkdir(path.dirname(file),{recursive:true});
  await writeFile(file,source,'utf8');
};

try{
  await write('Root.Main','import Local.Middle\nimport External.Lean\n');
  await write('Local.Middle','public import Local.Leaf\n');
  await write('Local.Leaf','def value : Nat := 1\n');
  assert.deepEqual(
    resolveProviderModules(temp,['Root.Main']),
    ['Local.Leaf','Local.Middle','Root.Main'],
    'local dependencies must precede importers and external imports stay external',
  );

  await write('Cycle.A','import Cycle.B\n');
  await write('Cycle.B','import Cycle.A\n');
  assert.throws(
    ()=>resolveProviderModules(temp,['Cycle.A']),
    /local import cycle/u,
  );
  assert.throws(
    ()=>resolveProviderModules(temp,['Missing.Root']),
    /root module missing/u,
  );
}finally{
  await rm(temp,{recursive:true,force:true});
}

console.log('PSC2_LEAN_KERNEL_WASM_PROVIDER_CLOSURE: PASS');
