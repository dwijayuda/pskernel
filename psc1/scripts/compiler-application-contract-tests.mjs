import assert from 'node:assert/strict';
import fs from 'node:fs';
import crypto from 'node:crypto';
import {deriveReadiness} from './practical-core-readiness.mjs';
import {checkCompilerApplication} from './check-compiler-application.mjs';
const c=JSON.parse(fs.readFileSync(new URL('../docs/PSC1_COMPILER_APPLICATION_CONTRACT.json',import.meta.url)));
const h='a'.repeat(64),commit='b'.repeat(40),sha=s=>crypto.createHash('sha256').update(s).digest('hex');
const receipt={schema:'psc1-compiler-application-execution/1',contract:c.id,testedCommit:commit,
 checkerCommit:c.checkerCommit,targets:c.targets,passed:true,failures:[],
 records:c.grammars.flatMap(syntax=>c.targets.map(target=>({
  syntax,target,passed:true,runtime:'executed',hostEffects:true,admission:'independent-official-Lean',checkerCommit:c.checkerCommit,
  strictIr:'required-by-production-publication',moduleSha256:Object.fromEntries(c.requiredModules.map(m=>[m,h])),hostCargoLockSha256:h,
  ...Object.fromEntries(['sourceSha256','librarySha256','artifactSha256','manifestSha256','kernelAdmissionSha256','sourceClosureSha256','oracleSha256'].map(k=>[k,h])),
  cases:c.cases.map(x=>{
   const input=x.repeat?x.repeat.repeat(x.count):x.input;
   return {id:x.id,passed:true,exitCode:x.code,stdoutSha256:sha(x.stdout),stderrSha256:h,
    inputSha256:sha(input),inputBytes:Buffer.byteLength(input),outputSha256:sha(x.output??'previous'),
    preservedPrevious:x.output===undefined,metrics:x.performance?{elapsedSeconds:1,maxRssKiB:65536}:null};
  })
 })))};
checkCompilerApplication(c,receipt,{commit});
for(const change of [
 x=>x.testedCommit='c'.repeat(40),x=>x.records.pop(),x=>x.records.push(x.records[0]),
 x=>x.records[0].cases.pop(),x=>x.records[0].cases.push(x.records[0].cases[0]),
 x=>x.records[0].cases[0].exitCode=99,x=>x.records[0].cases[0].inputSha256=h,
 x=>x.records[0].runtime='skipped',x=>x.records[0].sourceClosureSha256=null,
 x=>x.records[0].cases.at(-1).metrics=null,
 x=>x.records[0].cases.at(-1).metrics.elapsedSeconds=121,
 x=>x.records[0].cases.at(-1).metrics.maxRssKiB=1048577,
 x=>x.records[0].cases.find(c=>c.id==='second-line-location').stdoutSha256=h
]){
 const bad=structuredClone(receipt);change(bad);
 assert.throws(()=>checkCompilerApplication(c,bad,{commit}));
}
const subset={...receipt,targets:['js'],records:receipt.records.filter(r=>r.target==='js')};
checkCompilerApplication(c,subset,{commit,targets:['js']});
assert.throws(()=>checkCompilerApplication(c,subset,{commit}));
console.log('PSC1_COMPILER_APPLICATION_CONTRACT: PASS complete corpus, location, result, measured memory/deadline and identity boundaries');

const release=JSON.parse(fs.readFileSync(new URL('../docs/PSC1_PRACTICAL_CORE_V1_CONTRACT.json',import.meta.url)));
const full={schema:'psc1-seven-backend-qualification/1',testedCommit:commit,qualification:'passed-scoped-execution',
 assurance:{checked:true,explicitOrdinary:true,verifiedRequest:'refused'}};
const report=deriveReadiness(release,{commit,compilerApplicationReceipt:receipt,compilerApplicationContract:c,fullQualification:full});
assert.equal(report.applications.find(a=>a.id==='compiler-like').status,'qualified');
assert.equal(report.releaseReady,false);
assert.throws(()=>deriveReadiness(release,{commit,compilerApplicationReceipt:subset,compilerApplicationContract:c,fullQualification:full}),/full compiler application matrix/);

const weakenedContract=structuredClone(c);weakenedContract.cases.pop();
assert.throws(()=>checkCompilerApplication(weakenedContract,receipt,{commit}),/frozen compiler application case identities/);
