import assert from 'node:assert/strict';
import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';
import {pathToFileURL} from 'node:url';import {spawnSync} from 'node:child_process';
const sha=x=>crypto.createHash('sha256').update(x).digest('hex');
assert.equal(process.version,'v22.23.3');
const commit=spawnSync('git',['rev-parse','HEAD'],{encoding:'utf8'}).stdout.trim();
assert.equal(commit,'66f1e752cfbdc491d9b2974c849825e8a4193227');
const {readOwnedCompilerSources}=await import(pathToFileURL(path.resolve('host-tools/compiler-source-inputs.mjs')));
const {compilerSourceClosureDigest}=await import(pathToFileURL(path.resolve('host-tools/compiler-host-protocol.mjs')));
const {runTool}=await import(pathToFileURL(path.resolve('host-tools/generated-target-tools.mjs')));
const sources=readOwnedCompilerSources('Ps.BackendTs.CompilerService').map(({module,text})=>({module,kind:'lean',text}));
const digest=compilerSourceClosureDigest(sources);
const directory=path.resolve('dist/encoder-shapes');fs.mkdirSync(directory,{recursive:true});
const input=path.join(directory,'G1-bootstrap.request.json'),output=path.join(directory,'G1-bootstrap.candidate.json');
const wire=JSON.stringify(['psc1-compiler-service/1','G1-bootstrap',digest,'lean','ordinary-checked','Ps.BackendTs.CompilerService',sources.map(s=>[s.module,s.text])]);
fs.writeFileSync(input,wire);
const seed=path.resolve('.lake/build/bin/psc1_target_service_seed'),seedSha=sha(fs.readFileSync(seed));
const result=runTool(seed,['ts',input,output],{logDirectory:directory});
assert.equal(sha(fs.readFileSync(seed)),seedSha);assert.equal(sha(fs.readFileSync(input)),sha(wire));
const candidate=JSON.parse(fs.readFileSync(output));assert.equal(candidate.status,'candidate');assert.equal(candidate.sourceClosureDigest,digest);
const prefixes=['psIrEncodeTypeWithFuel','psIrEncodeExprWithFuel'];
function count(value,tag){return Array.isArray(value)?(value[0]===tag?1:0)+value.reduce((n,x)=>n+count(x,tag),0):0;}
function calls(value,depth=0,out=[]){
 if(!Array.isArray(value))return out;
 if(value[0]==='call'&&Array.isArray(value[1])&&value[1][0]==='var')
  out.push({name:value[1][1],arguments:value[3]?.length,lambdaDepth:depth});
 for(const x of value)if(Array.isArray(x))calls(x,depth+(value[0]==='lambda'?1:0),out);
 return out;
}
const graphs={};for(const graph of ['originalIr','specializedIr']){
 graphs[graph]=candidate[graph][4].filter(d=>prefixes.some(n=>d[0]===n||d[0].startsWith(n+'Worker')||d[0].startsWith(n+'$')||d[0].startsWith(n+'_')))
  .map(d=>({name:d[0],parameters:d[2],resultType:d[3],bodyLambdas:count(d[4],'lambda'),calls:calls(d[4]),body:d[4]}));
}
const receipt={schema:'psc1-encoder-shape-diagnostic/1',sourceCommit:commit,sourceClosureDigest:digest,sourceModules:sources.length,requestSha256:sha(wire),candidateSha256:sha(fs.readFileSync(output)),sourceSha256:sha(candidate.source),seedSha256:seedSha,seedEvent:result.event,graphs,qualification:false,admission:'not-run; use actual independent qualification pipeline',execution:'native G1 seed only; no target or G2 replay'};
fs.writeFileSync(path.join(directory,'receipt.json'),JSON.stringify(receipt,null,2)+'\n');
for(const [graph,rows] of Object.entries(graphs))console.log('PSC1_ENCODER_SHAPE_SUMMARY: '+JSON.stringify({graph,workers:rows.map(({body,...rest})=>rest)}));
console.log('PSC1_ENCODER_SHAPE_IR: '+JSON.stringify(graphs));
console.log('PSC1_ENCODER_SHAPE_IDENTITY: '+JSON.stringify({...receipt,graphs:undefined}));
