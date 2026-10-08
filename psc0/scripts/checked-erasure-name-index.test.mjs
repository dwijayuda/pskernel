import assert from 'node:assert/strict';
import { test } from 'node:test';
import { readFileSync, existsSync } from 'node:fs';
import { mkdtemp, writeFile, rm } from 'node:fs/promises';
import { execFileSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { resolveTypeScriptCli } from './typescript-cli.mjs';

const root=fileURLToPath(new URL('../',import.meta.url));
const seed=path.join(root,'.lake/build/bin/psc1'+(process.platform==='win32'?'.exe':''));
test('generated erasure indexes preserve collisions, structured names, precedence and output reservations', {skip:!existsSync(seed)},async()=>{
  const dir=await mkdtemp(path.join(tmpdir(),'psc2-erasure-index-'));
  try {
    const read=p=>readFileSync(path.join(root,p),'utf8');
    const basic=read('packages/erasure/src/Ps/Erasure/Basic.lean');
    const environment=read('packages/environment/src/Ps/Environment/Basic.lean');
    const source=read('packages/foundation/src/Ps/Foundation/Name.lean')+'\n'+
      environment.slice(environment.indexOf('def psEnvironmentHashStringWorker'),environment.indexOf('def psEnvironmentIndexFindWorker'))+'\n'+
      basic.slice(basic.indexOf('-- Persistent collision buckets'),basic.indexOf('inductive PsErasedBinderKind'))+
      '\ndef erasureIndexEntriesNil : List (Prod PsName String) := List.nil\n'+
      'def erasureIndexEntriesCons (name : PsName) (value : String) (tail : List (Prod PsName String)) : List (Prod PsName String) := List.cons (Prod.mk name value) tail\n'+
      'def A.value : Nat := 9\ndef erasureScopeCollision (A_value : Nat) : Nat := Nat.add A_value A.value\n';
    const input=path.join(dir,'Index.lean'),ts=path.join(dir,'index.ts');
    await writeFile(input,source);await writeFile(path.join(dir,'package.json'),'{"type":"module"}');
    const output=execFileSync(seed,['typescript',input],{encoding:'utf8',timeout:60000,maxBuffer:8*1024*1024});
    await writeFile(ts,output);
    const compiler=resolveTypeScriptCli();
    execFileSync(process.execPath,[compiler,'--strict','--target','ES2022','--module','ES2022','--outDir',dir,ts],{encoding:'utf8',timeout:60000});
    const m=await import(pathToFileURL(path.join(dir,'index.js')).href);
    assert.equal(m.erasureScopeCollision(7n),16n, 'local output names must not capture a qualified declaration');
    const tag=x=>x?.[Object.getOwnPropertySymbols(x??{})[0]],N=s=>m.PsName.str(m.PsName.anonymous,s);
    const lookup=(map,n)=>{const r=m.psErasureIndexFind(map,n);return tag(r)==='some'?r.value:undefined;};
    let map=m.PsErasureNameIndex.empty();
    const a=m.PsName.num(m.PsName.anonymous,0n),b=m.PsName.num(m.PsName.anonymous,65521n);
    assert.equal(m.psEnvironmentNameHash(a),m.psEnvironmentNameHash(b));
    map=m.psErasureIndexInsert(map,a,'first');map=m.psErasureIndexInsert(map,b,'collision');
    assert.equal(lookup(map,a),'first');assert.equal(lookup(map,b),'collision');
    map=m.psErasureIndexInsert(map,a,'replacement');assert.equal(lookup(map,a),'replacement');assert.equal(lookup(map,b),'collision');
    const flat=N('A.B'),nested=m.PsName.str(N('A'),'B');
    map=m.psErasureIndexInsert(map,flat,'flat');map=m.psErasureIndexInsert(map,nested,'nested');
    assert.equal(lookup(map,flat),'flat');assert.equal(lookup(map,nested),'nested');assert.equal(lookup(map,N('missing')),undefined);
    const pair=(fst,snd)=>[fst,snd],list=xs=>xs.reduceRight((t,h)=>m.erasureIndexEntriesCons(h[0],h[1],t),m.erasureIndexEntriesNil);
    const names=m.psErasureDeclarationNameIndex(list([pair(a,'new'),pair(b,'other'),pair(a,'old')]));
    assert.equal(names.count,3n);
    assert.equal(lookup(names.byCore,a),'new');assert.equal(lookup(names.byCore,b),'other');
    for(const name of ['new','old','other'])assert.equal(lookup(names.byOutput,N(name)),true);
    assert.equal(lookup(names.byOutput,N('absent')),undefined);
    // Exercise all tree levels and collision buckets with ordinary compiler-sized tables.
    for(let i=0;i<1500;i++)map=m.psErasureIndexInsert(map,N('declaration'+i),String(i));
    for(let i=0;i<1500;i+=7)assert.equal(lookup(map,N('declaration'+i)),String(i));
  } finally {await rm(dir,{recursive:true,force:true});}
});
