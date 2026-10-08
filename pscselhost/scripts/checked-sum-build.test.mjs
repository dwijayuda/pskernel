import test from 'node:test';import assert from 'node:assert/strict';import {mkdtemp,writeFile,readFile,rm} from 'node:fs/promises';import {existsSync} from 'node:fs';import path from 'node:path';import {tmpdir} from 'node:os';import {pathToFileURL} from 'node:url';import {buildChecked,defaultCheckedSeed} from './checked-build.mjs';
const seed=process.env.PSC2_CHECKED_SEED_BIN??defaultCheckedSeed;
const lean='inductive OwnedChoice where\n  | empty\n  | payload (left : Nat) (right : Nat)\n  | single (value : Nat)\ndef choose (choice : OwnedChoice) : Nat :=\n  match choice with\n  | OwnedChoice.empty => 0\n  | OwnedChoice.payload left right => right\n  | OwnedChoice.single value => value\ndef answer : Nat := choose (OwnedChoice.payload 7 11)\n';
const ps='inductive OwnedChoice where {\n  | empty;\n  | payload (left : Nat) (right : Nat);\n  | single (value : Nat);\n};\ndef choose (choice : OwnedChoice) : Nat := match choice with {\n  | OwnedChoice.empty => 0;\n  | OwnedChoice.payload left right => right;\n  | OwnedChoice.single value => value;\n};\ndef answer : Nat := choose(OwnedChoice.payload(7, 11));\n';
for(const kind of ['lean','ps'])test('real '+kind+' payload sum is owned-checked, emitted and executed',{skip:!existsSync(seed)},async()=>{
 const dir=await mkdtemp(path.join(tmpdir(),'psc2-owned-sum-'));try{await writeFile(path.join(dir,'package.json'),'{"type":"module"}');const entryPath=path.join(dir,'Main.'+kind),outputPath=path.join(dir,'out.js');await writeFile(entryPath,kind==='lean'?lean:ps);
  const receipt=await buildChecked({entryPath,outputPath,seedPath:seed});assert.equal(receipt.kernel.selector,'pskernel-core');assert.equal(receipt.provider.profile,'owned-uniform-algebraic/11');assert.equal((await import(pathToFileURL(outputPath).href)).answer,11n);
  const input=JSON.parse(await readFile(path.join(dir,'out.admissions.json'),'utf8'));assert(input.admissions.some(x=>x.kind==='inductive'&&x.declaration.ts[0].cs.length===3));
 }finally{await rm(dir,{recursive:true,force:true});}
});
test('ill-typed payload branch rejects before emitting any output',{skip:!existsSync(seed)},async()=>{
 const dir=await mkdtemp(path.join(tmpdir(),'psc2-owned-sum-rejected-'));try{const entryPath=path.join(dir,'Main.lean'),outputPath=path.join(dir,'never/out.js');await writeFile(entryPath,lean.replace('OwnedChoice.empty => 0','OwnedChoice.empty => OwnedChoice.empty'));await assert.rejects(buildChecked({entryPath,outputPath,seedPath:seed}));assert.equal(existsSync(path.dirname(outputPath)),false);}finally{await rm(dir,{recursive:true,force:true});}
});
