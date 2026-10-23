// Focused mechanism gate only: native candidate IR, never generation qualification.
import assert from 'node:assert/strict';import fs from 'node:fs';import path from 'node:path';
import {readOwnedCompilerSources} from '../host-tools/compiler-source-inputs.mjs';
import {compilerSourceClosureDigest} from '../host-tools/compiler-host-protocol.mjs';
import {runTool,sha} from '../host-tools/generated-target-tools.mjs';
const entry='Ps.BackendTs.CompilerService',sources=readOwnedCompilerSources(entry).map(({module,text})=>({module,kind:'lean',text}));
const digest=compilerSourceClosureDigest(sources),directory=path.resolve('dist/text-lookup-workers');
fs.mkdirSync(directory,{recursive:true});
const wire=JSON.stringify(['psc1-compiler-service/1','G1-bootstrap',digest,'lean','ordinary-checked',entry,sources.map(s=>[s.module,s.text])]);
const input=path.join(directory,'G1-bootstrap.request.json'),output=path.join(directory,'G1-bootstrap.candidate.json');
fs.writeFileSync(input,wire);const seed=path.resolve('.lake/build/bin/psc1_target_service_seed'),seedHash=sha(fs.readFileSync(seed));
const event=runTool(seed,['ts',input,output],{logDirectory:directory});
assert.equal(sha(fs.readFileSync(seed)),seedHash);assert.equal(sha(fs.readFileSync(input)),sha(wire));
const bytes=fs.readFileSync(output);assert.ok(bytes.length>0&&bytes.length<=128*1024*1024);
const c=JSON.parse(bytes);assert.equal(c.status,'candidate');assert.equal(c.sourceClosureDigest,digest);
const expected={psTextInsertApplied:2,psTextJoinApplied:4,psTsLookupApplied:2};
const lambdaCount=v=>Array.isArray(v)?(v[0]==='lambda'?1:0)+v.reduce((n,x)=>n+lambdaCount(x),0):0;
const witnesses=[];
for(const [name,arity] of Object.entries(expected)){
 const original=c.originalIr[4].find(d=>d[0]===name);assert.ok(original);assert.equal(original[2].length,arity);assert.notEqual(original[3][0],'function');
 const primary=c.specializedIr[4].find(d=>d[0]===name);assert.ok(primary);assert.equal(primary[2].length,arity);assert.notEqual(primary[3][0],'function');
 let helper=primary;
 if(primary[4][0]==='call'&&primary[4][1]?.[0]==='var'&&primary[4][1][1].startsWith(name+'_')){
  helper=c.specializedIr[4].find(d=>d[0]===primary[4][1][1]);assert.ok(helper);
  assert.equal(primary[4][3].length,arity);
 }else assert.ok(['matchE','ifE','letE'].includes(primary[4][0]),'expected direct data body or saturated forwarding worker');
 assert.equal(helper[2].length,arity);assert.notEqual(helper[3][0],'function');
 assert.equal(lambdaCount(helper[4]),0,'data worker rebuilt returned-function prefix');
 const selfCalls=[];function inspect(v){if(!Array.isArray(v))return;if(v[0]==='call'&&v[1]?.[0]==='var'&&v[1][1]===helper[0])selfCalls.push(v);for(const x of v)if(Array.isArray(x))inspect(x);}inspect(helper[4]);
 assert.ok(selfCalls.length>0);for(const call of selfCalls)assert.equal(call[3].length,arity,'recursive data call lost saturation');
 witnesses.push({name,arity,helper:helper[0],helperParameters:helper[2],helperResult:helper[3],helperBodyLambdas:0,body:helper[4]});
}
const receipt={schema:'psc1-text-lookup-worker-shapes/1',sourceCommit:process.env.GITHUB_SHA,sourceClosureDigest:digest,sourceModules:sources.length,requestSha256:sha(wire),candidateSha256:sha(bytes),sourceSha256:sha(c.source),seedHash,event:event.event,witnesses,qualification:false,admission:'not-run; genuine qualification separate'};
fs.writeFileSync(path.join(directory,'receipt.json'),JSON.stringify(receipt,null,2)+'\n');
console.log('PSC1_TEXT_LOOKUP_WORKER_SHAPES: '+JSON.stringify({...receipt,witnesses:witnesses.map(({body,...w})=>w)}));
