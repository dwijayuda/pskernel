import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {spawnSync} from 'node:child_process';
import {sha,verifyArtifact} from '../host-tools/generated-target-tools.mjs';import {compilerSourceClosureDigest} from '../host-tools/compiler-host-protocol.mjs';
const current='f5a00e75ef4b46831ccefdfc78f47a45ea1174bf',focus='e913a6d391a68c6c9460d090de7100323e3bd9b0';
const checkout=spawnSync('git',['rev-parse','HEAD'],{encoding:'utf8'});assert.equal(checkout.status,0);assert.equal(checkout.stdout.trim(),current);
const root=path.resolve('dist/unified-v2-readback-input'),records=[];
function find(dir){for(const e of fs.readdirSync(dir,{withFileTypes:true})){const p=path.join(dir,e.name);if(e.isDirectory())find(p);else if(e.name==='qualification.json')inspect(p);}}
function inspect(file){
 const dir=path.dirname(file),q=JSON.parse(fs.readFileSync(file));
 if(q.schema!=='psc1-generated-target-qualification/1')return;assert.equal(q.serviceKind,'unified');assert.ok([current,focus].includes(q.testedCommit));assert.equal(q.sourceModules,120);
 const input=JSON.parse(fs.readFileSync(path.join(dir,'G1-bootstrap.request.json')));assert.equal(input[0],'psc1-unified-compiler-service/2');const wire=input[2];assert.ok(Array.isArray(wire));
 const sources=wire[6].map(([module,text])=>({module,text,kind:wire[3]}));assert.equal(compilerSourceClosureDigest(sources),q.sourceClosureDigest);
 for(const tool of q.tools){if(fs.existsSync(tool.file))assert.equal(sha(fs.readFileSync(tool.file)),tool.sha256,'qualification tool identity');}
 for(const [i,row]of q.sourceInventory.entries()){
  assert.equal(row.module,sources[i].module);assert.equal(row.bytes,Buffer.byteLength(sources[i].text));assert.equal(row.sha256,sha(sources[i].text));
  assert.ok(!row.module.startsWith('Ps.BackendPython.')&&!row.module.startsWith('Ps.BackendPhp.'));
  if(true){const actual=fs.readFileSync(row.path);assert.equal(sha(actual),row.sha256);assert.equal(actual.length,row.bytes);}
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
find(root);assert.equal(records.length,2);
const focused=records.find(r=>r.testedCommit===focus),rust=records.find(r=>r.testedCommit===current);
assert.equal(focused.target,'rust');assert.equal(focused.status,'passed');assert.equal(focused.correctnessQualification,'G1-only');
assert.equal(rust.target,'rust');
assert.equal(rust.status,'failed');
if(rust.status==='passed'){
 assert.equal(rust.correctnessQualification,'qualified');assert.equal(rust.generations.length,3);
 assert.equal(rust.cases,120);assert.equal(rust.envelopeRefusals,27);
 assert.equal(rust.fixedPoint,'passed-G1-G2-G3-exact-source-admission-IR-executable-and-four-target-observations');
}else{
 assert.equal(rust.correctnessQualification,'not-qualified');assert.equal(rust.fixedPoint,'not-run');
}
for(const key of ['sourceClosureDigest','sourceInventorySha256','executableSha256'])assert.equal(focused[key],rust[key]);
for(const key of ['sourceSha256','admissionsSha256','originalIrSha256','specializedIrSha256'])assert.equal(focused.bootstrap[key],rust.bootstrap[key]);
const report={schema:'psc1-codec-rust-receipt-readback/1',verifiedCheckout:current,readbackControlCommit:process.env.GITHUB_SHA,archives:JSON.parse(fs.readFileSync(path.join(root,'archives.json'))),records,
 rustFixedPoint:rust.fixedPoint,independentG1Reproduction:'passed-same-source-separate-run-not-clean-build',
 independentCleanFullReplay:'not-run',formalCompilerPreservation:'not-provided',performance240s:'not-run'};
fs.mkdirSync('dist/unified-v2-receipt-readback',{recursive:true});
fs.writeFileSync('dist/unified-v2-receipt-readback/receipt.json',JSON.stringify(report,null,2)+'\n');
console.log('PSC1_CODEC_RUST_READBACK: '+JSON.stringify({records:records.length,rustFixedPoint:report.rustFixedPoint,independentG1Reproduction:report.independentG1Reproduction}));
