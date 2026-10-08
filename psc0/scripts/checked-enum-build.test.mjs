import test from 'node:test';import assert from 'node:assert/strict';import {mkdtemp,writeFile,readFile,rm} from 'node:fs/promises';import {existsSync} from 'node:fs';import path from 'node:path';import {tmpdir} from 'node:os';import {pathToFileURL} from 'node:url';
import {buildChecked,defaultCheckedSeed} from './checked-build.mjs';
const seed=process.env.PSC2_CHECKED_SEED_BIN??defaultCheckedSeed;
const lean='inductive OwnedMode where\n  | read\n  | write\n  | idle\ndef choose (mode : OwnedMode) : Nat :=\n  match mode with\n  | OwnedMode.read => 7\n  | OwnedMode.write => 11\n  | OwnedMode.idle => 13\ndef answer : Nat := choose OwnedMode.write\n';
const ps='inductive OwnedMode where {\n  | read;\n  | write;\n  | idle;\n};\ndef choose (mode : OwnedMode) : Nat := match mode with {\n  | OwnedMode.read => 7;\n  | OwnedMode.write => 11;\n  | OwnedMode.idle => 13;\n};\ndef answer : Nat := choose(OwnedMode.write);\n';
for(const kind of ['lean','ps'])test('real '+kind+' enumeration is owned-checked, emitted, and executed',{skip:!existsSync(seed)},async()=>{
 const dir=await mkdtemp(path.join(tmpdir(),'psc2-owned-enum-'));try{
  await writeFile(path.join(dir,'package.json'),'{"type":"module"}');const entryPath=path.join(dir,'Main.'+kind),outputPath=path.join(dir,'out.js');await writeFile(entryPath,kind==='lean'?lean:ps);
  const receipt=await buildChecked({entryPath,outputPath,seedPath:seed});assert.equal(receipt.kernel.selector,'pskernel-core');assert.equal(receipt.provider.profile,'owned-uniform-algebraic/11');
  const out=await import(pathToFileURL(outputPath).href);assert.equal(out.answer,11n);
  const admissions=JSON.parse(await readFile(path.join(dir,'out.admissions.json'),'utf8'));assert(admissions.admissions.some(a=>a.kind==='inductive'&&a.declaration.ts[0].cs.length===3));
 }finally{await rm(dir,{recursive:true,force:true});}
});
test('ill-typed enum branch cannot cause fallback or emit output',{skip:!existsSync(seed)},async()=>{
 const dir=await mkdtemp(path.join(tmpdir(),'psc2-owned-enum-reject-'));try{
  const entryPath=path.join(dir,'Main.lean'),outputPath=path.join(dir,'out.js');await writeFile(entryPath,lean.replace('OwnedMode.idle => 13','OwnedMode.idle => OwnedMode.read'));
  await assert.rejects(buildChecked({entryPath,outputPath,seedPath:seed}));assert.equal(existsSync(outputPath),false);
 }finally{await rm(dir,{recursive:true,force:true});}
});
