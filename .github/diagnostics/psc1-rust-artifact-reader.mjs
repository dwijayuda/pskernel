// Read-only evidence extraction. Artifact contents are data, never executed.
import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const files=[];function scan(dir){for(const e of fs.readdirSync(dir,{withFileTypes:true})){const p=path.join(dir,e.name);if(e.isDirectory())scan(p);else if(e.isFile())files.push(p);}}scan('input');
for(const file of files){
 const name=path.basename(file),bytes=fs.readFileSync(file);
 if(name==='tool.stderr.txt'||name==='tool.stdout.txt'){
  const text=bytes.toString('utf8'),lines=text.split('\n'),errors=lines.filter(l=>/^error(?:\[|:)/.test(l));
  console.log('PSC1_RUST_TOOL_LOG: '+JSON.stringify({file,bytes:bytes.length,sha256:sha(bytes),
   errors:errors.slice(0,30).map(l=>l.slice(0,500)),errorCount:errors.length,
   warningCount:lines.filter(l=>/^warning:/.test(l)).length,
   head:lines.slice(0,65).map(l=>l.slice(0,400))}));
 }
 if(name==='Cargo.lock')console.log('PSC1_RUST_RECORDED_LOCK: '+JSON.stringify({file,sha256:sha(bytes),text:bytes.toString('utf8')}));
 if(name==='qualification.json'){
  const q=JSON.parse(bytes);console.log('PSC1_RUST_BOOTSTRAP_IDENTITY: '+JSON.stringify({
   testedCommit:q.testedCommit,sourceClosureDigest:q.sourceClosureDigest,sourceModules:q.sourceModules,
   bootstrap:q.bootstrap,status:q.status,generations:q.generations,events:q.events,
   failure:q.failure?.slice(0,500)}));
 }
 if(['module.rs','main.rs','module.ts','module.js','module.d.ts','module.js.map'].includes(name))console.log('PSC1_RUST_GENERATED_SOURCE: '+JSON.stringify({file,bytes:bytes.length,sha256:sha(bytes),lines:bytes.toString('utf8').split('\n').length}));
}

for(const file of files){
 const name=path.basename(file);
 if(name==='tool-events.jsonl')console.log('PSC1_TARGET_TOOL_EVENTS: '+JSON.stringify({file,events:fs.readFileSync(file,'utf8').split('\n').filter(Boolean).map(x=>JSON.parse(x))}));
 if(name==='G1-bootstrap.candidate.json'){
  const q=JSON.parse(fs.readFileSync(file,'utf8'));
  console.log('PSC1_TARGET_RETAINED_CANDIDATE: '+JSON.stringify({status:q.status,target:q.target,
   sourceClosureDigest:q.sourceClosureDigest,sourceBytes:Buffer.byteLength(q.source||''),sourceSha256:sha(q.source||''),
   admissionsSha256:sha(q.admissionRequest?.admissions||''),originalIrSha256:sha(JSON.stringify(q.originalIr)),
   specializedIrSha256:sha(JSON.stringify(q.specializedIr)),publicNames:q.publicNames,
   originalDeclarations:q.originalIr?.[4]?.length,specializedDeclarations:q.specializedIr?.[4]?.length}));
 }
}

for(const file of files){
 const name=path.basename(file);
 if(['module.rs','module.ts'].includes(name)){
  const lines=fs.readFileSync(file,'utf8').split('\n');
  const longest=lines.map((line,i)=>({line:i+1,chars:line.length,
   declaration:line.match(/^(?:(?:pub|export) )?(?:fn|function\\*?|const)\\s+([^\\s<(]+)/)?.[1]||null}))
   .sort((a,b)=>b.chars-a.chars).slice(0,25);
  console.log('PSC1_GENERATED_LARGEST_LINES: '+JSON.stringify({file,longest}));
 }
 if(name==='G1-bootstrap.candidate.json'){
  const q=JSON.parse(fs.readFileSync(file,'utf8'));
  function measure(value){let arrays=0,depth=0,stack=[[value,0]];while(stack.length){const[x,d]=stack.pop();if(Array.isArray(x)){arrays++;depth=Math.max(depth,d);for(const child of x)if(Array.isArray(child))stack.push([child,d+1]);}}return{arrays,depth};}
  for(const kind of ['originalIr','specializedIr']){
   const largest=q[kind][4].map(d=>({name:d[0],typeParameters:d[1].length,parameters:d[2].length,bodyBytes:JSON.stringify(d[4]).length,...measure(d[4])}))
    .sort((a,b)=>b.arrays-a.arrays).slice(0,25);
   console.log('PSC1_GENERATED_LARGEST_IR: '+JSON.stringify({target:q.target,kind,largest}));
  }
 }
}

for(const file of files.filter(f=>path.basename(f)==='G1-bootstrap.candidate.json')){
 const q=JSON.parse(fs.readFileSync(file,'utf8')),decls=q.specializedIr[4],index=new Map(decls.map(d=>[d[0],d]));
 for(const mode of ['variables','all-string-overapproximation']){
  const live=new Set([...q.publicNames,...decls.filter(d=>d[2].length===0).map(d=>d[0])]),work=[...live];
  for(let i=0;i<work.length;i++){
   const d=index.get(work[i]);if(!d)continue;
   const stack=[d[4]];
   while(stack.length){
    const x=stack.pop();if(!Array.isArray(x))continue;
    const references=mode==='variables'?(x[0]==='var'?[x[1]]:[]):x.filter(y=>typeof y==='string');
    for(const name of references)if(index.has(name)&&!live.has(name)){live.add(name);work.push(name);}
    for(const y of x)if(Array.isArray(y))stack.push(y);
   }
  }
  const removed=decls.filter(d=>!live.has(d[0])),totalBytes=decls.reduce((n,d)=>n+JSON.stringify(d[4]).length,0);
  console.log('PSC1_DIAGNOSTIC_FUNCTION_REACHABILITY: '+JSON.stringify({target:q.target,mode,claim:'read-only estimate, no transformation or qualification',
   total:decls.length,retained:decls.length-removed.length,removed:removed.length,
   bodyBytes:totalBytes,removedBodyBytes:removed.reduce((n,d)=>n+JSON.stringify(d[4]).length,0),
   zeroArityRetained:decls.filter(d=>d[2].length===0).length,
   largestRemoved:removed.map(d=>({name:d[0],parameters:d[2].length,bytes:JSON.stringify(d[4]).length}))
    .sort((a,b)=>b.bytes-a.bytes).slice(0,15)}));
 }
}
