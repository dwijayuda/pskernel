import {test} from 'node:test';
import assert from 'node:assert/strict';
import {mkdtempSync,mkdirSync,writeFileSync,rmSync,readFileSync} from 'node:fs';
import {tmpdir} from 'node:os';
import path from 'node:path';
import {sealStage1,verifyStage1} from './stage1-cache.mjs';

const required=[
  'stage0/bin/lean','stage1/leanc.sh',
  'stage1/lib/temp/libleancpp_1.a',
  'stage1/lib/lean/libleanrt.a','stage1/lib/lean/libInit.a',
  'stage1/lib/lean/libStd.a','stage1/lib/lean/libLean.a','stage1/lib/lean/Lean.olean',
];
const fingerprint={emcc:'Emscripten 6.0.9 test',clang:'clang version 18 test',
  platform:'linux',arch:'x64'};
function mockBuild(fn){
  const root=mkdtempSync(path.join(tmpdir(),'psc0-stage1-cache-test-'));
  try{
    for(const relative of required){
      const full=path.join(root,relative);
      mkdirSync(path.dirname(full),{recursive:true});
      writeFileSync(full,'pinned-build-artifact:'+relative);
    }
    for(let i=0;i<105;i++){
      const file=path.join(root,'stage1/lib/lean/Init','F'+i+'.olean');
      mkdirSync(path.dirname(file),{recursive:true});
      writeFileSync(file,'pinned-olean:'+i);
    }
    return fn(root);
  }finally{rmSync(root,{recursive:true,force:true});}
}
test('cache seal/reuse requires every exact hashed artifact',async()=>{
  await mockBuild(async root=>{
    const manifest=await sealStage1(root,fingerprint);
    assert.ok(manifest.files.length>=113);
    await verifyStage1(root,fingerprint);
  });
});
test('tampering with target library cannot be silently reused',async()=>{
  await mockBuild(async root=>{
    await sealStage1(root,fingerprint);
    writeFileSync(path.join(root,'stage1/lib/lean/libLean.a'),'changed');
    await assert.rejects(verifyStage1(root,fingerprint),/corrupted or changed/);
  });
});
test('cross-compiler identity cannot be silently substituted',async()=>{
  await mockBuild(async root=>{
    await sealStage1(root,fingerprint);
    await assert.rejects(verifyStage1(root,{...fingerprint,clang:'unknown compiler'}),
      /fingerprint mismatch/);
  });
});
test('deleted olean prevents reusing the cache',async()=>{
  await mockBuild(async root=>{
    await sealStage1(root,fingerprint);
    rmSync(path.join(root,'stage1/lib/lean/Init/F0.olean'));
    await assert.rejects(verifyStage1(root,fingerprint),/file set changed/);
  });
});
