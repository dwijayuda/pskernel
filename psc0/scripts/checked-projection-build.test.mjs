import assert from 'node:assert/strict';
import {test} from 'node:test';
import {mkdtemp,writeFile,readFile,rm} from 'node:fs/promises';
import {existsSync} from 'node:fs';
import {tmpdir} from 'node:os';import path from 'node:path';import {pathToFileURL} from 'node:url';
import {buildChecked,defaultCheckedSeed} from './checked-build.mjs';
const seed=process.env.PSC2_CHECKED_SEED_BIN??defaultCheckedSeed;
for(const kind of ['lean','ps'])test('real '+kind+' record projections pass owned check and execute',{skip:!existsSync(seed)},async()=>{
 const dir=await mkdtemp(path.join(tmpdir(),'psc2-owned-projections-'));
 try{await writeFile(path.join(dir,'package.json'),'{"type":"module"}');const entryPath=path.join(dir,'Main.'+kind),outputPath=path.join(dir,'out.js');
  const source=kind==='lean'?'structure OwnedPair where\n  left : Nat\n  right : Nat\ndef pair : OwnedPair := OwnedPair.mk 7 11\ndef answer : Nat := pair.right\ndef select (p : OwnedPair) : Nat := p.left\n'
   :"structure OwnedPair where { left : Nat\n right : Nat\n }\ndef pair : OwnedPair := OwnedPair.mk(7, 11)\ndef answer : Nat := pair.right\ndef select(p : OwnedPair) : Nat := p.left\n";
  await writeFile(entryPath,source);const receipt=await buildChecked({entryPath,outputPath,seedPath:seed});const out=await import(pathToFileURL(outputPath).href);
  assert.equal(out.answer,11n);assert.equal(out.select(out.pair),7n);assert.equal(receipt.kernel.selector,'pskernel-core');assert.equal(receipt.provider.profile,'owned-uniform-algebraic/11');
  assert.match(await readFile(path.join(dir,'out.admissions.json'),'utf8'),/"k":"proj"/u);
 }finally{await rm(dir,{recursive:true,force:true});}
});
test('real record match uses the owned recursor before emission',{skip:!existsSync(seed)},async()=>{
 const dir=await mkdtemp(path.join(tmpdir(),'psc2-owned-record-match-'));
 try{await writeFile(path.join(dir,'package.json'),'{"type":"module"}');const entryPath=path.join(dir,'Main.lean'),outputPath=path.join(dir,'out.js');
  await writeFile(entryPath,'structure OwnedPair where\n  left : Nat\n  right : Nat\ndef pick (p : OwnedPair) : Nat :=\n  match p with\n  | OwnedPair.mk left right => right\ndef answer : Nat := pick (OwnedPair.mk 7 11)\n');
  const receipt=await buildChecked({entryPath,outputPath,seedPath:seed});assert.equal((await import(pathToFileURL(outputPath).href)).answer,11n);assert.equal(receipt.kernel.selector,'pskernel-core');
 }finally{await rm(dir,{recursive:true,force:true});}
});
