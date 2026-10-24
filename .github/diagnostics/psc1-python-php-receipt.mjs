// Read immutable qualification artifacts only; never executes a compiler.
import assert from 'node:assert/strict';import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const row=JSON.parse(process.env.PSC1_RECEIPT_ROW);
const files=dir=>fs.readdirSync(dir,{withFileTypes:true}).flatMap(e=>e.isDirectory()?files(path.join(dir,e.name)):e.isFile()?[path.join(dir,e.name)]:[]);
const all=files('baseline'),reports=all.filter(p=>path.basename(p)==='qualification.json');assert.equal(reports.length,1);
const report=JSON.parse(fs.readFileSync(reports[0]));assert.equal(report.testedCommit,row.commit);assert.equal(report.target,row.target);
assert.equal(report.profile.name,'correctness-3600s');assert.equal(report.profile.g1TimeoutMs,240000);assert.equal(report.profile.selfCompileTimeoutMs,3600000);
const root=path.dirname(reports[0]),extension=row.target==='python'?'py':'php';
const sourceChecks=report.generations.map(g=>{const p=path.join(root,'G'+g.generation+'-service','module.'+extension),bytes=fs.readFileSync(p);assert.equal(sha(bytes),g.sourceSha256);return {generation:g.generation,bytes:bytes.length,sha256:sha(bytes)};});
if(report.status==='passed'){assert.equal(report.correctnessQualification,'qualified');assert.deepEqual(sourceChecks.map(g=>g.generation),[1,2,3]);const first=fs.readFileSync(path.join(root,'G1-service','module.'+extension));for(const g of [2,3])assert.equal(Buffer.compare(first,fs.readFileSync(path.join(root,'G'+g+'-service','module.'+extension))),0);}
const heartbeatFiles=all.filter(p=>path.basename(p)==='resource-heartbeats.jsonl');
const heartbeats=heartbeatFiles.map(p=>{const rows=fs.readFileSync(p,'utf8').trim().split('\n').filter(Boolean).map(JSON.parse);return {file:path.relative(root,p),count:rows.length,first:rows[0],last:rows.at(-1)};});
const receipt={schema:'psc1-python-php-3600s-artifact-readback/1',producer:row,qualificationSha256:sha(fs.readFileSync(reports[0])),status:report.status,target:report.target,profile:report.profile,correctnessQualification:report.correctnessQualification,performanceQualification:report.performanceQualification,sourceClosureDigest:report.sourceClosureDigest,bootstrap:report.bootstrap,serviceArtifact:report.serviceArtifact,sourceChecks,sourceInventory:report.sourceInventory,tools:report.tools,events:report.events,attempts:report.attempts,generations:report.generations.map(g=>({generation:g.generation,sourceClosureDigest:g.sourceClosureDigest,sourceSha256:g.sourceSha256,admissionsSha256:g.admissionsSha256,originalIrSha256:g.originalIrSha256,specializedIrSha256:g.specializedIrSha256,logicalAdmission:g.logicalAdmission,checkerCommit:g.checkerCommit,observations:g.observations})),fixedPoint:report.fixedPoint,failure:report.failure,completedAt:report.completedAt,heartbeats};
fs.mkdirSync('diagnostics',{recursive:true});fs.writeFileSync('diagnostics/receipt-'+row.target+'.json',JSON.stringify(receipt,null,2)+'\n');
console.log('PSC1_3600S_ARTIFACT_READBACK: '+JSON.stringify(receipt));
