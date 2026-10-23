// Profile the current bounded-token compiler: final 30 seconds of a 220-second G2 replay, not the end of the 1800-second request.
import assert from 'node:assert/strict';import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';import {spawnSync} from 'node:child_process';
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const files=[];function scan(d){for(const e of fs.readdirSync(d,{withFileTypes:true})){const p=path.join(d,e.name);if(e.isDirectory())scan(p);else if(e.isFile())files.push(p);}}scan('input');
fs.mkdirSync('diagnosis',{recursive:true});
console.log('PSC1_PROFILE_SOURCE: current bounded-token TS artifact; final 30 seconds of bounded 220s replay; diagnostic only');
function artifact(target,expected){
 const file=files.find(p=>p.endsWith('/G1-service/artifact.json')&&JSON.parse(fs.readFileSync(p,'utf8')).target===target);
 assert.ok(file);assert.equal(sha(fs.readFileSync(file)),expected);const m=JSON.parse(fs.readFileSync(file,'utf8')),directory=path.dirname(file);
 const verify=()=>{assert.equal(sha(fs.readFileSync(file)),expected);for(const f of m.files){assert.match(f.path,/^[a-zA-Z0-9_.-]+$/);const p=path.join(directory,f.path);assert.ok(fs.lstatSync(p).isFile()&&!fs.lstatSync(p).isSymbolicLink());const b=fs.readFileSync(p);assert.equal(b.length,f.bytes);assert.equal(sha(b),f.sha256);}};
 verify();return{m,directory,verify};
}
const ts=artifact('ts','3d491fac102424409c9359f702b1b61354bc3acd9aacbe00668200e941c4ca65');
const request=files.find(p=>p.endsWith('/G2-self.request.json')&&p.includes('generated-ts-compiler'));assert.ok(request);
assert.equal(sha(fs.readFileSync(request)),'50cedd8dd842d2d64723696097fff3c200b560ff1996cba7f929d1ddc227cf08');
const qualification=JSON.parse(fs.readFileSync(path.join(path.dirname(ts.directory),'qualification.json'),'utf8'));
assert.equal(qualification.sourceClosureDigest,'b5e496cc6734849116a7dd113257853d755271b20a44f419750993cd99069217');
assert.equal(ts.m.sourceSha256,qualification.bootstrap.sourceSha256);
console.log('PSC1_TS_EXECUTING_RECEIPT: '+JSON.stringify({bootstrap:qualification.bootstrap,serviceArtifact:qualification.serviceArtifact,generations:qualification.generations.map(g=>({generation:g.generation,observations:g.observations})),sourceClosureDigest:qualification.sourceClosureDigest,events:qualification.events,targetPlans:qualification.targetPlans}));

const originalFile=path.resolve(ts.directory,ts.m.executable),original=fs.readFileSync(originalFile,'utf8');
const invokeMatcher=/function\* __ps\$invoke\(fn, \.\.\.args\) \{\s*return \(yield \{ fn, args, tail: false \}\);\s*\}/;
const tailMatcher=/function\* __ps\$tail\(fn, \.\.\.args\) \{\s*return \(yield \{ fn, args, tail: true \}\);\s*\}/;
assert.equal((original.match(new RegExp(invokeMatcher.source,'g'))||[]).length,1);
assert.equal((original.match(new RegExp(tailMatcher.source,'g'))||[]).length,1);
const replacement="class __ps$Call {\n constructor(fn,args,tail){this.fn=fn;this.args=args;this.tail=tail;this.state=0;}\n next(value){\n  if(this.state===0){this.state=1;const request={fn:this.fn,args:this.args,tail:this.tail};this.fn=undefined;this.args=undefined;return {value:request,done:false};}\n  if(this.state===1){this.state=2;return {value,done:true};}\n  return {value:undefined,done:true};\n }\n return(value){this.state=2;this.fn=undefined;this.args=undefined;return {value,done:true};}\n throw(error){this.state=2;this.fn=undefined;this.args=undefined;throw error;}\n [Symbol.iterator](){return this;}\n}\nfunction __ps$invoke(fn,...args){return new __ps$Call(fn,args,false);}\nfunction __ps$tail(fn,...args){return new __ps$Call(fn,args,true);}\n";
const modified=original.replace(invokeMatcher,()=>replacement).replace(tailMatcher,()=>'');
// Compare the complete finite request-iterator protocol against the original generators.
const oldInvoke=function*(fn,...args){return (yield {fn,args,tail:false});};
const oldTail=function*(fn,...args){return (yield {fn,args,tail:true});};
const factory=new Function(replacement+';return {invoke:__ps$invoke,tail:__ps$tail};')();
const payloads=[undefined,null,17n,'value',{field:3}];
let protocolComparisons=0;
const fn=()=>42;
for(const tail of [false,true]){
 for(const first of ['next','return','throw'])for(const second of ['next','return','throw'])for(const third of ['next','return','throw']){
  for(const payload of payloads){
   const old=(tail?oldTail:oldInvoke)(fn,1,'x'),current=(tail?factory.tail:factory.invoke)(fn,1,'x');
   assert.equal(old[Symbol.iterator](),old);assert.equal(current[Symbol.iterator](),current);
   for(const method of [first,second,third,'next']){
    const observe=it=>{try{return {returned:it[method](payload)};}catch(error){return {thrown:error};}};
    assert.deepEqual(observe(current),observe(old));protocolComparisons++;
   }
  }
 }
}
console.log('PSC1_ITERATOR_PROTOCOL: '+JSON.stringify({protocolComparisons,states:'initial,yielded,closed',operations:'next,return,throw',inputs:'same function/argument identities and unknown payloads'}));
const candidate=path.resolve(ts.directory,'diagnostic-call-iterator.js');fs.writeFileSync(candidate,modified);
const runner=path.resolve('diagnosis/replay.mjs');
fs.writeFileSync(runner,[
"import fs from 'node:fs';import{pathToFileURL}from'node:url';",
"const api=await import(pathToFileURL(process.argv[2]).href);",
"const input=fs.readFileSync(process.argv[3],'utf8');",
"const output=api.psCompilerTsServiceCandidate(input);",
"if(typeof output!=='string'||Buffer.byteLength(output)>134217728)throw Error('response bound');",
"fs.writeFileSync(process.argv[4],output);"].join('\n'));
const requests=files.filter(p=>/\/G1-(?!bootstrap)[^/]+\.request\.json$/.test(p)&&p.includes('generated-ts-compiler')).sort();
assert.equal(requests.length,10);
const results=[];
for(let round=0;round<2;round++){
 for(const input of requests){
  const id=path.basename(input,'.request.json'),row={round,id};
  for(const mode of (round===0?['original','callIterator']:['callIterator','original'])){
   const directory=path.resolve('diagnosis',String(round),id,mode),output=path.join(directory,'response.json');
   const r=spawnSync('python3',['.github/diagnostics/bounded-process.py',JSON.stringify({
    command:[process.execPath,runner,mode==='original'?originalFile:candidate,path.resolve(input),output],
    directory,timeoutMs:240000,maxBuffer:32*1024*1024})],{encoding:'utf8',timeout:245000,killSignal:'SIGKILL',maxBuffer:1024*1024});
   assert.equal(r.status,0,r.stderr);const execution=JSON.parse(r.stdout);
   assert.equal(execution.status,0,JSON.stringify(execution));assert.equal(execution.error,null);
   row[mode]={...execution,responseSha256:sha(fs.readFileSync(output))};
  }
  assert.equal(row.original.responseSha256,row.callIterator.responseSha256);
  console.log('PSC1_CALL_ITERATOR_REPLAY: '+JSON.stringify(row));results.push(row);
 }
}
ts.verify();
const receipt={schema:'psc1-ts-call-iterator-diagnostic/1',originalManifestSha256:sha(fs.readFileSync(path.join(ts.directory,'artifact.json'))),
 originalExecutableSha256:sha(original),derivedExecutableSha256:sha(modified),workload:'ten actual stored G1 compiler corpus requests; each twice; alternating fresh-process order',
 originalElapsedMs:results.reduce((s,r)=>s+r.original.elapsedMs,0),candidateElapsedMs:results.reduce((s,r)=>s+r.callIterator.elapsedMs,0),
 results,qualification:false,adoption:'not-run',admission:'not-run',scope:'unadopted runtime hypothesis only; no G2 performance claim'};
fs.writeFileSync('diagnosis/call-iterator-receipt.json',JSON.stringify(receipt,null,2)+'\n');
console.log('PSC1_CALL_ITERATOR_DIAGNOSTIC: '+JSON.stringify(receipt));
