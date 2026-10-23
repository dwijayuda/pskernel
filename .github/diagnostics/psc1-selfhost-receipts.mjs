// Read-only Linux audit of retained qualification evidence; never runs compiler code.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {compilerSourceClosureDigest} from '../../psc1/host-tools/compiler-host-protocol.mjs';
const sha=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');
const request=JSON.parse(fs.readFileSync('.github/diagnostics/psc1-selfhost-receipts.json','utf8'));
assert.equal(request.schema,'psc1-selfhost-receipt-audit-request/1');
assert.ok(Array.isArray(request.attempts)&&request.attempts.length>0);
const rows=[];
function walk(root) {
 return fs.readdirSync(root,{withFileTypes:true}).flatMap(e=>{
  const file=path.join(root,e.name);
  assert.ok(!e.isSymbolicLink(),'symlink in evidence');
  return e.isDirectory()?walk(file):[file];
 });
}
for(const expected of request.attempts) {
 assert.match(expected.id||expected.target,/^[a-z0-9-]+$/);
 const root=path.join('input',expected.id||expected.target),files=walk(root);
 const reports=files.filter(f=>path.basename(f)==='qualification.json');assert.equal(reports.length,1);
 const file=reports[0],directory=path.dirname(file),report=JSON.parse(fs.readFileSync(file));
 assert.equal(report.schema,'psc1-generated-target-qualification/1');
 assert.equal(report.target,expected.target);assert.equal(report.testedCommit,expected.requestCommit);
 assert.equal(report.profile?.name||'performance-240s',expected.profile);
 const bootstrap=JSON.parse(fs.readFileSync(path.join(directory,'G1-bootstrap.request.json'),'utf8'));
 assert.equal(bootstrap[0],'psc1-compiler-service/1');
 const sources=bootstrap[6].map(([module,text])=>({module,kind:bootstrap[3],text}));
 assert.equal(sources.length,report.sourceInventory.length);
 sources.forEach((s,i)=>{
  const row=report.sourceInventory[i];
  assert.equal(s.module,row.module);assert.equal(Buffer.byteLength(s.text),row.bytes);assert.equal(sha(s.text),row.sha256);
 });
 assert.equal(compilerSourceClosureDigest(sources),report.sourceClosureDigest);
 for(const event of report.events.filter(e=>e.role==='generated-compiler')) {
  const req=path.join(directory,event.id+'.request.json');
  assert.equal(sha(fs.readFileSync(req)),event.requestSha256);
  const candidate=path.join(directory,event.id+'.candidate.json');
  if(event.status===0&&!event.error)assert.ok(fs.existsSync(candidate));
 }
 const manifests=[];
 for(const f of files.filter(f=>path.basename(f)==='artifact.json')) {
  const m=JSON.parse(fs.readFileSync(f));
  assert.equal(m.schema,'psc1-generated-target-artifact/1');assert.equal(m.target,expected.target);
  for(const item of m.files) {
   assert.match(item.path,/^[a-zA-Z0-9_.-]+$/);
   const bytes=fs.readFileSync(path.join(path.dirname(f),item.path));
   assert.equal(bytes.length,item.bytes);assert.equal(sha(bytes),item.sha256);
  }
  manifests.push({generation:path.basename(path.dirname(f)),sha256:sha(fs.readFileSync(f)),sourceSha256:m.sourceSha256,
   executableSha256:m.files.find(x=>x.path===m.executable).sha256,compilerVersion:m.compilerVersion,
   rustOptimizationLevel:m.rustOptimizationLevel??null});
 }
 if(report.status==='passed') {
  assert.deepEqual(report.generations.map(g=>g.generation),[1,2,3]);
  assert.match(report.fixedPoint,/^passed-G1-G2-G3/);
  for(const g of report.generations) {
   for(const key of ['sourceClosureDigest','sourceSha256','admissionsSha256','originalIrSha256','specializedIrSha256'])
    assert.equal(g[key],report.bootstrap[key]);
   assert.equal(g.logicalAdmission,'accepted');assert.equal(g.observations.length,10);
  }
 }
 const candidates=[];
 for(const generation of [2,3]) {
  const candidate=path.join(directory,'G'+generation+'-self.candidate.json');
  if(!fs.existsSync(candidate))continue;
  const bytes=fs.readFileSync(candidate);
  try {
   const value=JSON.parse(bytes);
   candidates.push({generation,wireSha256:sha(bytes),status:value.status,phase:value.phase,code:value.code,
    sourceClosureDigest:value.sourceClosureDigest,sourceSha256:typeof value.source==='string'?sha(value.source):undefined,
    admissionsSha256:value.admissionRequest?.admissions?sha(value.admissionRequest.admissions):undefined,
    originalIrSha256:value.originalIr?sha(JSON.stringify(value.originalIr)):undefined,
    specializedIrSha256:value.specializedIr?sha(JSON.stringify(value.specializedIr)):undefined,
    logicalAdmission:report.generations.find(g=>g.generation===generation)?.logicalAdmission||'not-established-by-this-audit'});
  } catch(error) { candidates.push({generation,wireSha256:sha(bytes),parseError:error.message}); }
 }
 const bootstrapCandidate=JSON.parse(fs.readFileSync(path.join(directory,'G1-bootstrap.candidate.json')));
 const selectedIr={};
 for(const graph of ['originalIr','specializedIr'])
  selectedIr[graph]=bootstrapCandidate[graph][4].filter(d=>typeof d[0]==='string'&&
   ['psJsonCharNeedsEscape','psBridgeFindConstructor','psBridgeFindRegularHeightInBucket','psBridgeHeightBucket'].some(n=>d[0].includes(n)));
 const sourceLines=fs.readFileSync(path.join(directory,'G1-service',expected.target==='ts'?'module.js':'module.rs'),'utf8').split('\\n');
 const selectedSource=sourceLines.map((line,i)=>({line:i+1,text:line})).filter(r=>
  ['psJsonCharNeedsEscape','psBridgeFindConstructor','psBridgeFindRegularHeightInBucket','psBridgeHeightBucket'].some(n=>
   r.text.includes('const __ps$impl,artifactReceiptSha256:sha(fs.readFileSync(file)),audit:'source inventory, requests and target manifest bytes verified; no new compiler execution',
  report:{...report,tools:report.tools.map(t=>({file:path.basename(t.file),sha256:t.sha256}))},manifests};
 rows.push(row);
 console.log('PSC1_SELFHOST_RECEIPT_AUDIT: '+JSON.stringify(row));
}
fs.mkdirSync('receipt-audit',{recursive:true});
fs.writeFileSync('receipt-audit/qualification-receipts.json',JSON.stringify({schema:'psc1-selfhost-receipt-audit/1',auditedAt:new Date().toISOString(),attempts:rows},null,2)+'\n');
+n+' ')||r.text.includes('function '+n+'(')||r.text.includes('function* '+n+'('))).slice(0,24);
 const row={...expected,candidates,selectedIr,selectedSource,artifactReceiptSha256:sha(fs.readFileSync(file)),audit:'source inventory, requests and target manifest bytes verified; no new compiler execution',
  report:{...report,tools:report.tools.map(t=>({file:path.basename(t.file),sha256:t.sha256}))},manifests};
 rows.push(row);
 console.log('PSC1_SELFHOST_RECEIPT_AUDIT: '+JSON.stringify(row));
}
fs.mkdirSync('receipt-audit',{recursive:true});
fs.writeFileSync('receipt-audit/qualification-receipts.json',JSON.stringify({schema:'psc1-selfhost-receipt-audit/1',auditedAt:new Date().toISOString(),attempts:rows},null,2)+'\n');
