// Linux CI: exercise a real Rust-native PSC service and real native Lean checker.
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const cli=path.join(root,'scripts/native-psc-preview.mjs');
const tmp=fs.mkdtempSync(path.join(os.tmpdir(),'psc1-native-qualification-'));
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const cases=[
  {kind:'ps',text:'def invert(flag : Bool) : Bool := if (flag) { false } else { true }\n'},
  {kind:'lean',text:'def invert (flag : Bool) : Bool := if flag then false else true\n'},
];
const records=[];
const run=(args,pass=true)=>{
  const start=performance.now();
  const result=spawnSync(process.execPath,[cli,...args],{
    encoding:'utf8',timeout:240000,maxBuffer:16*1024*1024,cwd:root,
  });
  const wallMs=performance.now()-start;
  assert.equal(result.error,undefined,String(result.error));
  if(pass)assert.equal(result.status,0,(result.stderr||'')+' '+(result.stdout||'').slice(-1000));
  else assert.notEqual(result.status,0,'invalid source unexpectedly accepted');
  return {result,wallMs};
};
try{
  for(const item of cases){
    const source=path.join(tmp,'Main.'+item.kind);fs.writeFileSync(source,item.text);
    for(let repetition=0;repetition<2;repetition++){
      const {result,wallMs}=run(['compile',source]);
      const resultValue=JSON.parse(result.stdout);
      assert.equal(resultValue.status,'accepted');
      assert.equal(resultValue.compiler,'generated-rust-native-G1');
      assert.equal(resultValue.kernel,'official-Lean-4.35.0-native');
      assert.equal(resultValue.receipt.logicalAdmission,'accepted');
      assert.equal(resultValue.receipt.productionPublication,'pending');
      assert.equal(typeof resultValue.receipt.targetArtifact.consumer,'string');
      const file=path.join(tmp,'target-'+item.kind+'-'+repetition+'.mjs');
      fs.writeFileSync(file,resultValue.source);
      const syntax=spawnSync(process.execPath,['--check',file],{encoding:'utf8',timeout:30000});
      assert.equal(syntax.status,0,syntax.stderr);
      records.push({
        kind:item.kind,repetition,wallMs,
        compilerProcessMs:resultValue.timings.compilerProcessMs,
        independentKernelMs:resultValue.timings.independentKernelMs,
        targetMs:resultValue.timings.targetMs,
        sourceSha256:sha(resultValue.source),
        admissionsSha256:resultValue.receipt.admissionsSha256,
        nativeCompilerSha256:resultValue.nativeCompilerSha256,
        nativeCheckerSha256:resultValue.nativeCheckerSha256
      });
    }
  }
  const bad=path.join(tmp,'Wrong.ps');fs.writeFileSync(bad,'def wrong : Nat := true\n');
  const negative=run(['compile',bad],false);
  assert.match(negative.result.stderr,/PSC1_NATIVE_PREVIEW_REFUSED/);
  // Fully checked transactional publication, plus failed edit retaining the prior target.
  const good=path.join(tmp,'Main.ps'),store=path.join(tmp,'published');
  const published=JSON.parse(run(['build',good,store]).result.stdout);
  assert.equal(published.status,'accepted');
  assert.ok(published.publication);
  const oldGeneration=published.publication.generation;
  run(['build',bad,store],false);
  const {readPublication}=await import('../host-tools/transactional-publication.mjs');
  const retained=readPublication(store,'portable-file');
  assert.ok(retained,'missing retained publication');
  const report={
    schema:'psc1-native-rust-lean435-preview-qualification/1',
    status:'passed',
    sourceCommit:process.env.GITHUB_SHA||'unverified-local',
    scope:'actual Rust-native generated G1/Lean4.35 native checker; NOT current modular G2/G3',
    sourceGrammars:cases.map(x=>x.kind),
    outputTarget:'js',
    nativeCompiler:true,
    nativeKernel:true,
    nodeHostOrchestration:true,
    strictChecks:'unchanged checked session',
    successfulCompilations:records.length,
    negativeTypingRefusal:true,
    transactionalPublication:true,
    retainedGeneration:oldGeneration,
    samples:records,
  };
  const directory=path.join(root,'dist/native-psc-preview');
  fs.mkdirSync(directory,{recursive:true});
  fs.writeFileSync(path.join(directory,'qualification.json'),JSON.stringify(report,null,2)+'\n');
  console.log('PSC1_NATIVE_PREVIEW_QUALIFICATION: '+JSON.stringify(report));
}finally{
  fs.rmSync(tmp,{recursive:true,force:true});
}
