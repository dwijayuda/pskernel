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
 assert.equal(report.target,expected.target);
 if(expected.expectedG1SourceSha256)assert.equal(report.bootstrap.sourceSha256,expected.expectedG1SourceSha256);assert.equal(report.testedCommit,expected.requestCommit);
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
   assert.equal(g.checkerCommit,report.bootstrap.checkerCommit);
   assert.deepEqual(g.observations,report.generations[0].observations);
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
 const sourceLines=fs.readFileSync(path.join(directory,'G1-service',expected.target==='ts'?'module.js':'module.rs'),'utf8').split('\n');
 const selectedSource=sourceLines.map((line,i)=>({line:i+1,text:line})).filter(r=>
  ['psJsonCharNeedsEscape','psBridgeFindConstructor','psBridgeFindRegularHeightInBucket','psBridgeHeightBucket'].some(n=>
   r.text.includes('const __ps$impl$'+n+' ')||r.text.includes('function '+n+'(')||r.text.includes('function* '+n+'(')))
  .slice(0,24).map(r=>({...r,text:r.text.slice(0,4000)}));
 const runtimeReceipts=files.filter(f=>f.endsWith('/ts-utf8-cache/receipt.json')||f.endsWith('/ts-utf8-views/receipt.json')).map(f=>JSON.parse(fs.readFileSync(f)));
 const tokenWorkers=[];
 if(expected.inspectUtf8TokenWorker){
  assert.equal(expected.target,'ts');
  for(const generation of report.generations){
   const file=path.join(directory,'G'+generation.generation+'-service','module.js');
   const source=fs.readFileSync(file,'utf8'),start=source.indexOf('function psStringEqFromWithFuel$worker(');
   assert.ok(start>=0);
   const next=source.indexOf('\nfunction ',start+10);
   const body=source.slice(start,next<0?source.length:next);
   assert.ok(body.includes('__ps$utf8Known('));
   assert.ok(body.includes('__ps$stringGetView(')&&body.includes('__ps$stringNextView('));
   assert.equal(body.includes('__ps$utf8('),false);
   const tokens=(body.match(/let __ps\$viewToken\$/g)||[]).length;
   assert.equal(tokens,2);
   tokenWorkers.push({generation:generation.generation,tokens,directCacheKeyLookups:0,
    startLine:source.slice(0,start).split('\n').length,sourceSha256:sha(body),body});
  }
 }

 const cursorCacheHelpers=[];
 if(expected.inspectCursorCacheHelpers){
  assert.equal(expected.target,'ts');
  for(const generation of report.generations){
   const text=fs.readFileSync(path.join(directory,'G'+generation.generation+'-service','module.js'),'utf8');
   const helpers={};
   for(const name of ['__ps$stringUtf8Size','__ps$stringExtract']){
    const start=text.indexOf('function '+name+'(');assert.ok(start>=0);
    let depth=0,end=-1;for(let i=text.indexOf('{',start);i<text.length;i++){if(text[i]==='{')depth++;else if(text[i]==='}'&&--depth===0){end=i+1;break;}}assert.ok(end>start);const body=text.slice(start,end);
    assert.equal(/__ps\$(?:last|previous)Utf8\s*=/.test(body),false);
    assert.equal(body.includes('new Uint32Array'),false);
    if(name==='__ps$stringUtf8Size')assert.equal(body.includes('__ps$utf8('),false);
    else {assert.ok(body.includes('.slice('));assert.ok(body.includes('for (const char of text)'));}
    helpers[name]={sourceSha256:sha(body),body};
   }
   cursorCacheHelpers.push({generation:generation.generation,helpers,scope:'size-only requests and extraction do not admit/promote views; cold/invalid extraction fallback retained'});
  }
 }


 const erasureWorkers={};
 if(expected.inspectErasureWorkers){
  const names=["psErasureIndexFindInBucketWorker","psErasureLookupRuntimeExpressionWorker","psErasureLookupNatWorker","psErasureNatInListWorker","psErasureTypeValuedWithFuelWorker","psErasureStringInListWorker","psErasureLookupTypeSubstitutionWorker","psErasureFindStringIndexWorker"];
  const countLambdas=value=>Array.isArray(value)?(value[0]==='lambda'?1:0)+value.reduce((n,x)=>n+countLambdas(x),0):0;
  for(const graph of ['originalIr','specializedIr']){
   const selected=bootstrapCandidate[graph][4].filter(d=>names.some(name=>d[0]===name||d[0].startsWith(name+'$')||d[0].startsWith(name+'_')));
   for(const name of names)if(graph==='originalIr')assert.ok(selected.some(d=>d[0]===name),'missing source worker '+name);
   erasureWorkers[graph]=selected.map(d=>({name:d[0],typeParameters:d[1].length,parameters:d[2].length,resultType:d[3],bodyLambdas:countLambdas(d[4]),body:d[4]}));
   console.log('PSC1_ERASURE_WORKER_SHAPES: '+JSON.stringify({graph,workers:erasureWorkers[graph].map(w=>({name:w.name,parameters:w.parameters,resultType:w.resultType,bodyLambdas:w.bodyLambdas}))}));
   for(const worker of erasureWorkers[graph].filter(w=>names.includes(w.name))){assert.notEqual(worker.resultType[0],'function');assert.equal(worker.bodyLambdas,0);}
  }
 }


 const encoderWorkers={};
 if(expected.inspectEncoderWorkers){
  const names=['psIrEncodeTypeWithFuelWorker','psIrEncodeExprWithFuelWorker'];
  function selfCalls(value,name,depth=0,out=[]){
   if(!Array.isArray(value))return out;
   if(value[0]==='call'&&Array.isArray(value[1])&&value[1][0]==='var'&&value[1][1]===name)
    out.push({lambdaDepth:depth,arguments:value[3]?.length});
   for(const child of value)if(Array.isArray(child))selfCalls(child,name,depth+(value[0]==='lambda'?1:0),out);
   return out;
  }
  for(const graph of ['originalIr','specializedIr']){
   encoderWorkers[graph]=bootstrapCandidate[graph][4].filter(d=>names.some(n=>d[0]===n||d[0].startsWith(n+'$')||d[0].startsWith(n+'_')))
    .map(d=>({name:d[0],parameters:d[2],resultType:d[3],body:d[4],selfCalls:selfCalls(d[4],d[0])}));
   for(const name of names)if(graph==='originalIr'){
    const worker=encoderWorkers[graph].find(w=>w.name===name);assert.ok(worker,'missing source encoder worker');
    assert.equal(worker.parameters.length,2);assert.notEqual(worker.resultType[0],'function');
    for(const call of worker.selfCalls){assert.equal(call.arguments,2);assert.ok(call.lambdaDepth>0,'eager recursive fuel prefix');}
   }
  }
  for(const name of names){
   const primary=encoderWorkers.specializedIr.find(w=>w.name===name);assert.ok(primary);
   assert.equal(primary.parameters.length,2);assert.notEqual(primary.resultType[0],'function');
   assert.equal(primary.body[0],'call');assert.equal(primary.body[1][0],'var');
   const helper=encoderWorkers.specializedIr.find(w=>w.name===primary.body[1][1]);assert.ok(helper);
   assert.ok(helper.name.startsWith(name+'_'));assert.equal(helper.parameters.length,2);
   assert.notEqual(helper.resultType[0],'function');assert.equal(primary.body[3].length,2);
   assert.ok(helper.selfCalls.length>0);
   for(const call of helper.selfCalls){assert.equal(call.arguments,2);assert.ok(call.lambdaDepth>0,'eager helper fuel prefix');}
  }
  console.log('PSC1_ENCODER_WORKER_SHAPES: '+JSON.stringify(Object.fromEntries(Object.entries(encoderWorkers).map(([graph,rows])=>[graph,rows.map(({body,...rest})=>rest)]))));
 }


 const textLookupWorkers=[];
 if(expected.inspectTextLookupWorkers){
const arities={psTextInsertApplied:2,psTextJoinApplied:4,psTsLookupApplied:2,psTsExprUsesNameWithFuelWorker:3};
const lambdaCount=v=>Array.isArray(v)?(v[0]==='lambda'?1:0)+v.reduce((n,x)=>n+lambdaCount(x),0):0;
const witnesses=[];
for(const [name,arity] of Object.entries(arities)){
 const original=bootstrapCandidate.originalIr[4].find(d=>d[0]===name);assert.ok(original);assert.equal(original[2].length,arity);assert.notEqual(original[3][0],'function');
 const primary=bootstrapCandidate.specializedIr[4].find(d=>d[0]===name);assert.ok(primary);assert.equal(primary[2].length,arity);assert.notEqual(primary[3][0],'function');
 let helper=primary;
 if(primary[4][0]==='call'&&primary[4][1]?.[0]==='var'&&primary[4][1][1].startsWith(name+'_')){
  helper=bootstrapCandidate.specializedIr[4].find(d=>d[0]===primary[4][1][1]);assert.ok(helper);
  assert.equal(primary[4][3].length,arity);
 }else assert.ok(['matchE','ifE','letE'].includes(primary[4][0]),'expected direct data body or saturated forwarding worker');
 assert.equal(helper[2].length,arity);assert.notEqual(helper[3][0],'function');
 if(name==='psTsExprUsesNameWithFuelWorker'){
  let found=0;
  function rejectPrefix(v){assert.equal(lambdaCount(v),0,'eager visitor callback allocation');if(!Array.isArray(v))return;if(v[0]==='call'&&v[1]?.[0]==='var')assert.ok(!v[1][1].startsWith(name),'visitor recursed before constructor dispatch');for(const x of v)if(Array.isArray(x))rejectPrefix(x);}
  function prelude(v){
   if(v[0]==='letE'){rejectPrefix(v[3]);prelude(v[4]);}
   else if(v[0]==='ifE'){rejectPrefix(v[1]);prelude(v[2]);prelude(v[3]);}
   else if(v[0]==='matchE'&&v[1]==='PsVerifiedIrExpr'){
    found++;const literal=v[4].find(a=>a[0]==='literal'),variable=v[4].find(a=>a[0]==='var');assert.ok(literal&&variable);
    assert.equal(lambdaCount(literal[2]),0);assert.equal(lambdaCount(variable[2]),0);
   }
  }
  prelude(helper[4]);assert.equal(found,1,'missing constructor-directed visitor');
 }else assert.equal(lambdaCount(helper[4]),0,'data worker rebuilt returned-function prefix');
 const selfCalls=[];function inspect(v){if(!Array.isArray(v))return;if(v[0]==='call'&&v[1]?.[0]==='var'&&v[1][1]===helper[0])selfCalls.push(v);for(const x of v)if(Array.isArray(x))inspect(x);}inspect(helper[4]);
 assert.ok(selfCalls.length>0);for(const call of selfCalls)assert.equal(call[3].length,arity,'recursive data call lost saturation');
 witnesses.push({name,arity,helper:helper[0],helperParameters:helper[2],helperResult:helper[3],helperBodyLambdas:lambdaCount(helper[4]),body:helper[4]});
}

 textLookupWorkers.push(...witnesses);
 }
 const row={...expected,candidates,selectedIr,selectedSource,runtimeReceipts,tokenWorkers,cursorCacheHelpers,erasureWorkers,encoderWorkers,textLookupWorkers,artifactReceiptSha256:sha(fs.readFileSync(file)),audit:'source inventory, requests and target manifest bytes verified; no new compiler execution',
  report:{...report,tools:report.tools.map(t=>({file:path.basename(t.file),sha256:t.sha256}))},manifests};
 rows.push(row);
 console.log('PSC1_SELFHOST_RECEIPT_AUDIT: '+JSON.stringify(row));
}
fs.mkdirSync('receipt-audit',{recursive:true});
fs.writeFileSync('receipt-audit/qualification-receipts.json',JSON.stringify({schema:'psc1-selfhost-receipt-audit/1',auditedAt:new Date().toISOString(),attempts:rows},null,2)+'\n');
