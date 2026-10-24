import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {spawnSync} from 'node:child_process';
import {sha,verifyArtifact} from '../host-tools/generated-target-tools.mjs';import {compilerSourceClosureDigest} from '../host-tools/compiler-host-protocol.mjs';
const current='812094c1f5e1e0c0dca516dab1e30ef66f3076f7',focus='a3d3e0a9444934d3f55c41939e971c39e56472d3',previous='9359f07320eaf84af1e551fb86c38718150291ff';
const old={"sourceClosureDigest":"a3350d645a81ed17f69af59333978c60e3b8f9e1d6855a999e0bc5844e183990","sourceInventorySha256":"1935e007515e65df1ccc3772eb158d8ffbe44c882fde7d809bf3513a288cc49e","executableSha256":"3da7d2bf38a335303649c775a680fb9ab9d2e2d943306b0123c4ed856bd82883","bootstrap":{"sourceClosureDigest":"a3350d645a81ed17f69af59333978c60e3b8f9e1d6855a999e0bc5844e183990","sourceSha256":"832f555d5d4f6ed23fabcdc6387035f407aa337bca80196371d2f5c47a1268a9","admissionsSha256":"e28e3f8626a3a1475e6aecd95b1a48967e90edc739ff053a680552a8fc0f3511","originalIrSha256":"704db6c25aca6d5936b424ec42ea5b5d877c9379ca8ae8bbd161e2014a6c2ee5","specializedIrSha256":"e92a580adf2484edf4af80932a2023eb187c837f2823474db0357f6bc36e3584","checkerCommit":"eb6cafb7290e8bd5f2937522d8d804f58f02bafc","logicalAdmission":"accepted","publicNames":["psCompilerServiceCandidate"]}};
const checkout=spawnSync('git',['rev-parse','HEAD'],{encoding:'utf8'});assert.equal(checkout.status,0);assert.equal(checkout.stdout.trim(),current);
const root=path.resolve('dist/unified-v2-readback-input'),records=[];
function find(dir){for(const e of fs.readdirSync(dir,{withFileTypes:true})){const p=path.join(dir,e.name);if(e.isDirectory())find(p);else if(e.name==='qualification.json')inspect(p);}}
function inspect(file){
 const dir=path.dirname(file),q=JSON.parse(fs.readFileSync(file));
 assert.equal(q.schema,'psc1-generated-target-qualification/1');assert.equal(q.serviceKind,'unified');assert.ok([current,focus,previous].includes(q.testedCommit));assert.equal(q.sourceModules,120);
 const input=JSON.parse(fs.readFileSync(path.join(dir,'G1-bootstrap.request.json')));assert.equal(input[0],'psc1-unified-compiler-service/2');const wire=input[2];assert.ok(Array.isArray(wire));
 const sources=wire[6].map(([module,text])=>({module,text,kind:wire[3]}));assert.equal(compilerSourceClosureDigest(sources),q.sourceClosureDigest);
 for(const tool of q.tools){if(fs.existsSync(tool.file))assert.equal(sha(fs.readFileSync(tool.file)),tool.sha256,'qualification tool identity');}
 for(const [i,row]of q.sourceInventory.entries()){
  assert.equal(row.module,sources[i].module);assert.equal(row.bytes,Buffer.byteLength(sources[i].text));assert.equal(row.sha256,sha(sources[i].text));
  assert.ok(!row.module.startsWith('Ps.BackendPython.')&&!row.module.startsWith('Ps.BackendPhp.'));
  if(q.testedCommit!==previous){const actual=fs.readFileSync(row.path);assert.equal(sha(actual),row.sha256);assert.equal(actual.length,row.bytes);}
 }
 const generations=q.generations.map(g=>{
  const mf=path.join(dir,'G'+g.generation+'-service/artifact.json'),m=verifyArtifact(mf,g.artifactSha256),exeHash=sha(fs.readFileSync(path.join(m.directory,m.executable)));
  assert.equal(exeHash,q.executableSha256);assert.equal(m.sourceSha256,g.sourceSha256);assert.equal(g.logicalAdmission,'accepted');assert.equal(g.observations.length,4);assert.ok(g.observations.every(r=>r.observations.length===10));
  const c=JSON.parse(fs.readFileSync(path.join(dir,g.generation===1?'G1-bootstrap.candidate.json':'G'+g.generation+'-self.candidate.json')));
  assert.equal(sha(c.source),g.sourceSha256);assert.equal(sha(JSON.stringify(c.originalIr)),g.originalIrSha256);assert.equal(sha(JSON.stringify(c.specializedIr)),g.specializedIrSha256);
  const {observations,...identity}=g;return {...identity,executableSha256:exeHash,observationsSha256:sha(JSON.stringify(observations)),rawAdmissionsSha256:sha(JSON.stringify(c.admissionRequest.admissions))};
 });
 assert.equal((q.cases||[]).length,generations.length*40);assert.equal((q.envelopeRefusals||[]).length,generations.length*9);
 for(const key of ['sourceClosureDigest','sourceSha256','admissionsSha256','originalIrSha256','specializedIrSha256','executableSha256','observationsSha256','rawAdmissionsSha256'])assert.equal(new Set(generations.map(g=>g[key])).size,generations.length?1:0,key);
 const record={testedCommit:q.testedCommit,target:q.target,status:q.status,correctnessQualification:q.correctnessQualification,performanceQualification:q.performanceQualification,profile:q.profile,
  nativeSeedSha256:q.nativeSeedSha256,toolsInventorySha256:sha(JSON.stringify(q.tools)),sourceClosureDigest:q.sourceClosureDigest,sourceInventorySha256:sha(JSON.stringify(q.sourceInventory)),root:q.sourceInventory.at(-1),sourceModules:q.sourceModules,bootstrap:q.bootstrap,
  generations,fixedPoint:q.fixedPoint,executableSha256:q.executableSha256,events:q.events.filter(e=>['G2-self','G3-self'].includes(e.id)),
  cases:(q.cases||[]).length,envelopeRefusals:(q.envelopeRefusals||[]).length,nativeDelegationBoundary:q.nativeDelegationBoundary,stackOverflow:q.failure?.includes('stack overflow')||false,failure:q.failure?.slice(0,2000)};
 records.push(record);console.log('PSC1_V2_RECEIPT_RECORD: '+JSON.stringify(record));
}
find(root);assert.equal(records.length,7);
const oldWasm=records.find(r=>r.testedCommit===previous&&r.target==='wasm-core');assert.equal(oldWasm.status,'passed');assert.equal(oldWasm.generations.length,3);
for(const key of ['sourceClosureDigest','sourceInventorySha256','executableSha256'])assert.equal(oldWasm[key],old[key]);
for(const key of ['sourceSha256','admissionsSha256','originalIrSha256','specializedIrSha256'])assert.equal(oldWasm.bootstrap[key],old.bootstrap[key]);
const latest=records.filter(r=>r.testedCommit===current);assert.equal(latest.length,4);
assert.deepEqual(latest.map(r=>r.target).sort(),['js','rust','ts','wasm-core']);for(const r of latest){
 const qualified=['ts','wasm-core'].includes(r.target);
 assert.equal(r.status,qualified?'passed':'failed');
 assert.equal(r.correctnessQualification,qualified?'qualified':'not-qualified');
 assert.equal(r.generations.length,qualified?3:1);
 assert.equal(r.cases,qualified?120:40);assert.equal(r.envelopeRefusals,qualified?27:9);
 if(qualified)assert.equal(r.fixedPoint,'passed-G1-G2-G3-exact-source-admission-IR-executable-and-four-target-observations');
 else assert.equal(r.fixedPoint,'not-run');
}
assert.ok(latest.find(r=>r.target==='rust').stackOverflow);
assert.match(latest.find(r=>r.target==='js').failure,/process tree exceeded hard deadline/);
for(const key of ['sourceClosureDigest','sourceInventorySha256'])assert.equal(new Set(latest.map(r=>r[key])).size,1,key);
for(const key of ['originalIrSha256','admissionsSha256'])assert.equal(new Set(latest.map(r=>r.bootstrap[key])).size,1,key);
const focused=records.find(r=>r.testedCommit===focus);assert.equal(focused.status,'passed');const rust=latest.find(r=>r.target==='rust');
for(const key of ['sourceClosureDigest','sourceInventorySha256','executableSha256'])assert.equal(focused[key],rust[key]);
for(const key of ['sourceSha256','admissionsSha256','originalIrSha256','specializedIrSha256'])assert.equal(focused.bootstrap[key],rust.bootstrap[key]);
const report={schema:'psc1-unified-v2-receipt-readback/1',verifiedCheckout:current,readbackControlCommit:process.env.GITHUB_SHA,archives:JSON.parse(fs.readFileSync(path.join(root,'archives.json'))),records,
 currentFourEngineFixedPoints:'not-qualified',preservedTypeScriptAndWasmFixedPoints:'passed',previousV2Wasm:'passed',currentRustIndependentG1Reproduction:'passed-same-source-separate-run-not-clean-build',independentCleanFullReplay:'not-run',formalPreservation:'not-provided',performance240s:'not-run'};
fs.mkdirSync('dist/unified-v2-receipt-readback',{recursive:true});fs.writeFileSync('dist/unified-v2-receipt-readback/receipt.json',JSON.stringify(report,null,2)+'\n');console.log('PSC1_V2_RECEIPT_READBACK: '+JSON.stringify({records:records.length,currentFourEngineFixedPoints:report.currentFourEngineFixedPoints,preservedTypeScriptAndWasmFixedPoints:report.preservedTypeScriptAndWasmFixedPoints,previousV2Wasm:report.previousV2Wasm,currentRustIndependentG1Reproduction:report.currentRustIndependentG1Reproduction}));
