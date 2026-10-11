import assert from 'node:assert/strict';
import {readFile,writeFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
const hash=x=>createHash('sha256').update(x).digest('hex');
const baseline=JSON.parse(await readFile('comparison/baseline/report.json','utf8'));
const candidate=JSON.parse(await readFile('comparison/candidate/report.json','utf8'));
for(const [mode,r] of [['baseline',baseline],['candidate',candidate]]){
 assert.equal(r.schema,'psc0-v7-m1-combined-source-closure/2');
 assert.equal(r.phase,'complete');assert.equal(r.mode,mode);
 assert.equal(r.source,process.env.GITHUB_SHA);assert.equal(r.generatedCorpusPassed,true);
 assert.equal(r.totalModules,21);assert.equal(r.modules.length,21);
 assert.equal(r.kernelTestsExecuted,false);assert.equal(r.windowsTestsExecuted,false);
 const selected=r.modules.filter(x=>x.sourceKind==='pscv0-v7').map(x=>x.module).sort();
 assert.deepEqual(selected,mode==='baseline'?['Ps.Syntax.Translate']:
 ['Ps.Foundation.List','Ps.Foundation.Source','Ps.Syntax.Cursor','Ps.Syntax.Token','Ps.Syntax.Translate']);
}
for(const key of ['frontendSource','frontendJsSha256','referenceSha256','builderJsSha256'])
 assert.equal(baseline[key],candidate[key],key);
const report={schema:'psc0-v7-m1-product-comparison/1',source:process.env.GITHUB_SHA,
 frontendSource:baseline.frontendSource,frontendJsSha256:baseline.frontendJsSha256,
 baselineV7Modules:1,candidateV7Modules:5,totalModules:21,
 nativeAndGeneratedCorpus:{positive:18,negative:10},
 kernelTestsExecuted:false,windowsTestsExecuted:false,fullCompilerSelfhostFixedPoint:false,
 products:[],baselineElapsedMs:baseline.elapsedMs,candidateElapsedMs:candidate.elapsedMs,
 candidatePreparationMs:candidate.preparationMs,candidateEmissionMs:candidate.emissionMs,
 typeScriptCompileMs:candidate.typeScriptCompileMs,generatedCorpusMs:candidate.generatedCorpusMs,
 sourceValidationMs:candidate.sourceValidationMs,
 generatedTypeScriptBytes:candidate.generatedTypeScriptBytes,
 generatedJavaScriptBytes:candidate.generatedJavaScriptBytes};
for(const [file,key] of [['bridge.admissions.json','admissionsSha256'],['index.ts','typeScriptSha256'],['index.js','jsSha256']]){
 const a=await readFile('comparison/baseline/'+file),b=await readFile('comparison/candidate/'+file);
 assert.equal(hash(a),baseline[key]);assert.equal(hash(b),candidate[key]);
 const same=a.equals(b);
 const row={file,identical:same,sha256:hash(b),bytes:b.length};
 if(!same){let i=0;while(i<a.length&&i<b.length&&a[i]===b[i])i++;
  row.difference={byteOffset:i,baseline:a.subarray(Math.max(0,i-80),i+160).toString(),candidate:b.subarray(Math.max(0,i-80),i+160).toString()};
 }
 report.products.push(row);
}
report.status=report.products.every(x=>x.identical)?'pass':'fail';
await writeFile('comparison/report.json',JSON.stringify(report,null,2)+'\n');
assert.equal(report.status,'pass','full product mismatch: see comparison/report.json');
console.log('PSCV0_M1_FULL_CLOSURE: PASS '+JSON.stringify(report));
