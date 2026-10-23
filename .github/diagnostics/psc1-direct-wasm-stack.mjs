// Diagnostic: only the number of reported frames changes, never execution stack size.
import assert from 'node:assert/strict';import fs from 'node:fs';import path from 'node:path';
import {sha,boundedRun,verifyArtifact} from '../../psc1/host-tools/generated-target-tools.mjs';
import {compilerRequestLimit} from '../../psc1/scripts/selfhost-qualification-profiles.mjs';
const request=JSON.parse(fs.readFileSync('../.github/diagnostics/psc1-direct-wasm-stack.json'));
function walk(root){return fs.readdirSync(root,{withFileTypes:true}).flatMap(e=>{const f=path.join(root,e.name);assert.equal(e.isSymbolicLink(),false);return e.isDirectory()?walk(f):[f];});}
const reports=walk('../input/wasm-stack').filter(f=>path.basename(f)==='qualification.json');assert.equal(reports.length,1);
const root=path.dirname(reports[0]),report=JSON.parse(fs.readFileSync(reports[0]));
assert.equal(report.testedCommit,request.attempts[0].requestCommit);assert.equal(report.target,'wasm-core');
assert.equal(report.sourceClosureDigest,request.closure);assert.deepEqual(report.generations.map(g=>g.generation),[1]);
assert.equal(report.generations[0].logicalAdmission,'accepted');assert.equal(report.generations[0].observations.length,10);
const artifact=path.join(root,'G1-service/artifact.json'),m=verifyArtifact(artifact,request.serviceSha256);
for(const file of ['scripts/generated-target-runner.mjs','scripts/selfhost-qualification-profiles.mjs',
 'host-tools/generated-target-tools.mjs','host-tools/generated-target-profiles.mjs',
 'host-tools/generated-wasm-transport.mjs','scripts/bounded-process.py']){
 const r=report.tools.find(t=>t.file.endsWith('/'+file));assert.ok(r);assert.equal(sha(fs.readFileSync(file)),r.sha256);
}
const candidate=JSON.parse(fs.readFileSync(path.join(root,'G1-bootstrap.candidate.json')));
const names=candidate.specializedIr[4].map(d=>d[0]),runtime=[];
for(const file of ['RuntimeNat','RuntimeInt','RuntimeString','RuntimeIntRepr']){
 const text=fs.readFileSync('packages/backend-wasm/src/Ps/BackendWasm/'+file+'.lean','utf8');
 const constants=new Map([...text.matchAll(/def (psWasm\w+) : String := "([^"]+)"/g)].map(m=>[m[1],m[2]]));
 const start=text.indexOf('RuntimeFunctions');assert.ok(start>=0);
 for(const match of text.slice(start).matchAll(/name := (psWasm\w+)/g))runtime.push(constants.get(match[1])||match[1]);
}
assert.equal(runtime.length,50);
const wasm=fs.readFileSync(path.join(path.dirname(artifact),'module.wasm'));
assert.deepEqual(WebAssembly.Module.imports(new WebAssembly.Module(wasm)),[]);
let at=8;function leb(){let n=0,shift=0;for(let i=0;i<5;i++){const b=wasm[at++];assert.ok(b!==undefined);n+=(b&127)*2**shift;if(!(b&128))return n;shift+=7;}throw Error('invalid uint32 LEB');}
const exports=[];while(at<wasm.length){const id=wasm[at++],size=leb(),end=at+size;assert.ok(end<=wasm.length);
 if(id===7){const count=leb();for(let i=0;i<count;i++){const size=leb(),name=wasm.subarray(at,at+size).toString('utf8');at+=size;const kind=wasm[at++],index=leb();exports.push({name,kind,index});}}
 at=end;
}
assert.equal(exports.find(e=>e.name==='__psc1_service_nat_half').index,1);
const publicIndex=names.indexOf('psCompilerWasmServiceCandidate');assert.ok(publicIndex>=0);
assert.equal(exports.find(e=>e.name==='psCompilerWasmServiceCandidate').index,runtime.length+publicIndex);
const resolve=index=>index<runtime.length?runtime[index]:names[index-runtime.length]||'generated-closure:'+index;
const input=path.resolve(root,'G2-self.request.json');assert.equal(sha(fs.readFileSync(input)),request.requestSha256);
const out=path.resolve('dist/direct-wasm-stack');fs.mkdirSync(out,{recursive:true});
if(request.resolveOnly){
 const resolved=request.resolveOnly.map(index=>({index,name:resolve(index),
  ir:candidate.specializedIr[4][index-runtime.length]}));

 let recursiveListSpines=[];
 if(request.inventoryNonTailListSpines){
  for(let d=0;d<candidate.specializedIr[4].length;d++){
   const decl=candidate.specializedIr[4][d],self=decl[0],params=decl[2],calls=[];
   const listIndices=params.map((p,i)=>[p,i]).filter(([p])=>p[1]?.[0]==='named'&&p[1][1].startsWith('List$spec$'));
   if(!listIndices.length)continue;
   function walk(e,tail=false,lambdaDepth=0){
    if(!Array.isArray(e))return;
    const tag=e[0];
    if(tag==='call'){
     if(e[1]?.[0]==='var'&&e[1][1]===self&&!tail&&lambdaDepth===0){
      const changed=listIndices.filter(([p,i])=>!(e[3]?.[i]?.[0]==='var'&&e[3][i][1]===p[0]));
      if(changed.length)calls.push({changedListParameters:changed.map(([p])=>p[0]),arity:e[3]?.length});
     }
     walk(e[1],false,lambdaDepth);for(const a of e[3]||[])walk(a,false,lambdaDepth);
    }else if(tag==='letE'){walk(e[3],false,lambdaDepth);walk(e[4],tail,lambdaDepth);}
    else if(tag==='ifE'){walk(e[1],false,lambdaDepth);walk(e[2],tail,lambdaDepth);walk(e[3],tail,lambdaDepth);}
    else if(tag==='matchE'){walk(e[3],false,lambdaDepth);for(const a of e[4]||[])walk(a[2],tail,lambdaDepth);}
    else if(tag==='lambda')walk(e[3],true,lambdaDepth+1);
    else if(tag==='intrinsic')for(const a of e[3]||[])walk(a,false,lambdaDepth);
    else if(tag==='projection')walk(e[3],false,lambdaDepth);
    else if(tag==='record')for(const f of e[3]||[])walk(f[1],false,lambdaDepth);
    else if(tag==='constructor')for(const f of e[4]||[])walk(f[1],false,lambdaDepth);
   }
   walk(decl[4],true);
   if(calls.length)recursiveListSpines.push({index:d+runtime.length,name:self,
    listParameters:listIndices.map(([p])=>p),nonTailSelfSites:calls.length,calls,bodyBytes:JSON.stringify(decl[4]).length});
  }
 }
 const receipt={schema:'psc1-retained-wasm-function-map/1',testedCommit:process.env.GITHUB_SHA,
  source:request,sourceSha256:m.sourceSha256,binarySha256:sha(wasm),exportAnchorsVerified:true,
  runtimeFunctions:runtime.length,sourceFunctions:names.length,compilerExecution:false,qualification:false,resolved,recursiveListSpines,
  inventoryScope:'heuristic explicit saturated non-tail self calls with changed List parameters; no execution/performance claim'};
 fs.writeFileSync(path.join(out,'resolved.json'),JSON.stringify(receipt,null,2)+'\n');
 const inventorySummary={schema:receipt.schema,testedCommit:receipt.testedCommit,
  source:receipt.source,sourceSha256:receipt.sourceSha256,binarySha256:receipt.binarySha256,
  exportAnchorsVerified:true,compilerExecution:false,qualification:false,
  resolved:resolved.map(({index,name})=>({index,name})),totalCandidates:recursiveListSpines.length,
  inventoryScope:receipt.inventoryScope,
  declarationSpines:recursiveListSpines.filter(r=>r.listParameters.some(p=>/PsDeclaration|PsVerifiedIrDeclaration/.test(JSON.stringify(p[1]))))
    .map(r=>({index:r.index,name:r.name,listParameters:r.listParameters.map(p=>p[0]),sites:r.nonTailSelfSites,bodyBytes:r.bodyBytes})),
  otherFirst60:recursiveListSpines.filter(r=>!r.listParameters.some(p=>/PsDeclaration|PsVerifiedIrDeclaration/.test(JSON.stringify(p[1]))))
    .slice(0,60).map(r=>({index:r.index,name:r.name,sites:r.nonTailSelfSites}))};
 fs.writeFileSync(path.join(out,'inventory-summary.json'),JSON.stringify(inventorySummary,null,2)+'\n');
 console.log('PSC1_RETAINED_WASM_FUNCTION_MAP: '+JSON.stringify(inventorySummary));process.exit(0);
}

const preload=path.join(out,'trace-limit.mjs');fs.writeFileSync(preload,'Error.stackTraceLimit=16384;\n');
assert.equal(fs.existsSync('.lake/build/bin/psc1_target_service_seed'),false);
const limits=compilerRequestLimit('performance-240s','G2-self');
const result=boundedRun(process.execPath,['--import',preload,path.resolve('scripts/generated-target-runner.mjs'),
 artifact,request.serviceSha256,input,path.join(out,'G2-self.candidate.json'),'performance-240s'],
 {...limits,logDirectory:path.join(out,'process')});
verifyArtifact(artifact,request.serviceSha256);assert.equal(sha(fs.readFileSync(input)),request.requestSha256);
const frames=[...result.stderr.matchAll(/wasm-function\[(\d+)\]/g)].map(m=>({index:Number(m[1]),name:resolve(Number(m[1]))}));
const counts=new Map();for(const frame of frames)counts.set(frame.name,(counts.get(frame.name)||0)+1);
const receipt={schema:'psc1-retained-wasm-stack-diagnosis/1',testedCommit:process.env.GITHUB_SHA,
 source:request,sourceSha256:m.sourceSha256,binarySha256:sha(wasm),runtimeFunctions:runtime.length,sourceFunctions:names.length,
 exportAnchorsVerified:true,qualification:false,executionStackSizeChanged:false,reportedFrameLimit:16384,
 execution:{elapsedMs:result.elapsedMs,status:result.status,signal:result.signal,error:result.error,maxRssKiB:result.maxRssKiB,peakTreeRssKiB:result.peakTreeRssKiB},
 frameCount:frames.length,frameCounts:[...counts].sort((a,b)=>b[1]-a[1]),firstFrames:frames.slice(0,30),lastFrames:frames.slice(-80)};
fs.writeFileSync(path.join(out,'receipt.json'),JSON.stringify(receipt,null,2)+'\n');
fs.writeFileSync(path.join(out,'function-map.json'),JSON.stringify({runtime,names},null,2)+'\n');
console.log('PSC1_RETAINED_WASM_STACK_DIAGNOSIS: '+JSON.stringify(receipt));
