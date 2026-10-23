// Inspect only immutable, independently admitted generated compiler artifacts.
import assert from 'node:assert/strict';import fs from 'node:fs';import path from 'node:path';
import {sha,verifyArtifact} from '../../psc1/host-tools/generated-target-tools.mjs';
import {compilerSourceClosureDigest} from '../../psc1/host-tools/compiler-host-protocol.mjs';
const request=JSON.parse(fs.readFileSync('../.github/diagnostics/psc1-ecmascript-architecture.json'));
assert.equal(request.schema,'psc1-retained-ecmascript-architecture/1');
function walk(root){return fs.readdirSync(root,{withFileTypes:true}).flatMap(e=>{const f=path.join(root,e.name);assert.equal(e.isSymbolicLink(),false);return e.isDirectory()?walk(f):[f];});}
const results=[];
for(const expected of request.attempts){
 const reports=walk('../input/architecture/'+expected.target).filter(f=>path.basename(f)==='qualification.json');assert.equal(reports.length,1);
 const root=path.dirname(reports[0]),report=JSON.parse(fs.readFileSync(reports[0]));
 assert.equal(report.target,expected.target);assert.equal(report.testedCommit,expected.requestCommit);
 assert.equal(report.sourceClosureDigest,expected.sourceClosureDigest);
 const first=report.generations[0];assert.equal(first.generation,1);assert.equal(first.logicalAdmission,'accepted');assert.equal(first.observations.length,10);
 if(expected.target==='ts'){assert.equal(report.status,'passed');assert.equal(report.correctnessQualification,'qualified');assert.deepEqual(report.generations.map(g=>g.generation),[1,2,3]);}
 const input=JSON.parse(fs.readFileSync(path.join(root,'G1-bootstrap.request.json')));
 const sources=input[6].map(([module,text])=>({module,kind:input[3],text}));assert.equal(compilerSourceClosureDigest(sources),expected.sourceClosureDigest);
 const manifest=verifyArtifact(path.join(root,'G1-service/artifact.json'),first.artifactSha256);
 const source=fs.readFileSync(path.join(root,'G1-service',expected.target==='ts'?'module.ts':'module.js'),'utf8');
 assert.equal(sha(source),manifest.sourceSha256);
 const executable=fs.readFileSync(path.join(root,'G1-service/module.js'),'utf8');
 const count=x=>executable.split(x).length-1;
 const starts=Array.from(executable.matchAll(/^(?:export )?function(\*)?\s+([\w$]+)/gm));
 const selected=[];
 for(let i=0;i<starts.length;i++){
   const name=starts[i][2];
   if(!/^(?:__ps\$impl\$)?(?:psExprInstantiateAtWorker|psStringEq(?:FromWithFuel)?|psNameEq|psEnvironmentIndexFindWorker)(?:\$|$)/.test(name))continue;
   const body=executable.slice(starts[i].index,starts[i+1]?.index??executable.length);
   selected.push({name,bytes:Buffer.byteLength(body),generators:(body.match(/function\*/g)||[]).length,delegated:(body.match(/yield\*/g)||[]).length,loop:body.includes('while (true)'),snippet:body.slice(0,1800)});
 }
 results.push({target:expected.target,runId:expected.runId,sourceModules:report.sourceModules,sourceClosureDigest:expected.sourceClosureDigest,artifactSha256:first.artifactSha256,
  sourceSha256:manifest.sourceSha256,executableSha256:sha(executable),executableBytes:Buffer.byteLength(executable),
  generators:(executable.match(/function\*/g)||[]).length,generatorIifes:count('yield* (function*'),
  invokeSites:count('yield* __ps$invoke('),tailSites:count('yield* __ps$tail(')+count('yield* __ps$tailInvoke('),
  directDriverSites:count('(yield { fn:'),loops:count('while (true)'),lazyGetters:count('})(__ps$utf8Known('),nestedFieldLoads:count('["$ps$fields"]'),selected});
}
const profileFiles=walk('../input/architecture/profile');
const profileReceiptFiles=profileFiles.filter(f=>path.basename(f)==='receipt.json');assert.equal(profileReceiptFiles.length,1);
const profileReceipt=JSON.parse(fs.readFileSync(profileReceiptFiles[0]));
assert.equal(profileReceipt.testedCommit,request.profiles[0].requestCommit);
assert.equal(profileReceipt.qualification,false);assert.equal(profileReceipt.nativeDelegation,false);
assert.equal(profileReceipt.source.sourceClosureDigest,request.attempts[0].sourceClosureDigest);
const cpu=[];
for(const file of profileFiles.filter(f=>f.endsWith('.log.txt'))){
 const text=fs.readFileSync(file,'utf8'),lines=text.split('\\n');
 const sections={};
 for(const name of ['Summary','Bottom up (heavy) profile']){
   const at=lines.findIndex(l=>l.includes('['+name+']'));
   sections[name]=at<0?[]:lines.slice(at,at+(name==='Summary'?15:85));
 }
 cpu.push({file:path.basename(file),sha256:sha(text),sections});
}
assert.ok(cpu.length>0,'full retained processed CPU report must be present');
const receipt={schema:request.schema,testedCommit:process.env.GITHUB_SHA,compilerExecution:false,nativeDelegation:false,qualification:false,comparisonLimits:'Different target closures and source snapshots; shape comparison is not a matched performance benchmark.',results,cpu};
fs.mkdirSync('dist/ecmascript-architecture',{recursive:true});fs.writeFileSync('dist/ecmascript-architecture/receipt.json',JSON.stringify(receipt,null,2)+'\n');
console.log('PSC1_RETAINED_ECMASCRIPT_ARCHITECTURE: '+JSON.stringify(receipt));
