// Profile the current applied-erasure compiler: final 30 seconds of an up-to1750-second exact G2 replay; diagnostic only.
import assert from 'node:assert/strict';import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';import {spawn} from 'node:child_process';
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const files=[];function scan(d){for(const e of fs.readdirSync(d,{withFileTypes:true})){const p=path.join(d,e.name);if(e.isDirectory())scan(p);else if(e.isFile())files.push(p);}}scan('input');
fs.mkdirSync('diagnosis',{recursive:true});
console.log('PSC1_PROFILE_SOURCE: current applied-erasure TS artifact; final 30 seconds of up-to1750s actual G2 replay; extended policy only for this pinned G2 request; diagnostic only');
function artifact(target,expected){
 const file=files.find(p=>p.endsWith('/G1-service/artifact.json')&&JSON.parse(fs.readFileSync(p,'utf8')).target===target);
 assert.ok(file);assert.equal(sha(fs.readFileSync(file)),expected);const m=JSON.parse(fs.readFileSync(file,'utf8')),directory=path.dirname(file);
 const verify=()=>{assert.equal(sha(fs.readFileSync(file)),expected);for(const f of m.files){assert.match(f.path,/^[a-zA-Z0-9_.-]+$/);const p=path.join(directory,f.path);assert.ok(fs.lstatSync(p).isFile()&&!fs.lstatSync(p).isSymbolicLink());const b=fs.readFileSync(p);assert.equal(b.length,f.bytes);assert.equal(sha(b),f.sha256);}};
 verify();return{m,directory,verify};
}
const ts=artifact('ts','294fa864b22b32138696ed9dfd54a6e2ae94799ce381628b256dcc0d2d7c3cec');
const request=files.find(p=>p.endsWith('/G2-self.request.json')&&p.includes('generated-ts-compiler'));assert.ok(request);
assert.equal(sha(fs.readFileSync(request)),'e90eafca56433f509bb9e77d1e26e034f1de34accadac7bfb2d913893a7e8998');
assert.equal(JSON.parse(fs.readFileSync(request,'utf8'))[1],'G2-self');
const qualification=JSON.parse(fs.readFileSync(path.join(path.dirname(ts.directory),'qualification.json'),'utf8'));
assert.equal(qualification.sourceClosureDigest,'816b37f9e38262105edb4e8930da0cda34e53e9ba3b0338841fe99b5a6cd5a82');
assert.equal(ts.m.sourceSha256,qualification.bootstrap.sourceSha256);
console.log('PSC1_TS_EXECUTING_RECEIPT: '+JSON.stringify({bootstrap:qualification.bootstrap,serviceArtifact:qualification.serviceArtifact,generations:qualification.generations.map(g=>({generation:g.generation,observations:g.observations})),sourceClosureDigest:qualification.sourceClosureDigest,events:qualification.events,targetPlans:qualification.targetPlans}));
const runner=path.resolve('diagnosis/runner.mjs');
fs.writeFileSync(runner,[
"import fs from 'node:fs';import{pathToFileURL}from'node:url';",
"const api=await import(pathToFileURL(process.argv[2]).href);",
"const input=fs.readFileSync(process.argv[3],'utf8');",
"const response=api.psCompilerTsServiceCandidate(input);",
"if(typeof response!=='string'||Buffer.byteLength(response)>134217728)throw Error('response bound');",
"fs.writeFileSync(process.argv[4],response);"].join('\n'));

const directory=path.resolve('diagnosis/execution'),output=path.resolve('diagnosis/unadopted-response.json');
const resultFile=path.resolve('diagnosis/supervisor-result.json'),stderrFile=path.resolve('diagnosis/supervisor-stderr.txt');
const out=fs.openSync(resultFile,'w'),err=fs.openSync(stderrFile,'w'),startedAt=Date.now();
const child=spawn('python3',['.github/diagnostics/psc1-selfhost-bounded-process.py',JSON.stringify({
 command:[process.execPath,'--prof','--logfile='+path.resolve('diagnosis/ts-g2-v8.log'),runner,path.resolve(ts.directory,ts.m.executable),path.resolve(request),output],
 directory,timeoutMs:1750000,timeoutPolicy:'g2g3-correctness-1800s',maxBuffer:32*1024*1024})],{detached:true,stdio:['ignore',out,err]});
assert.ok(child.pid);child.unref();fs.closeSync(out);fs.closeSync(err);
fs.writeFileSync('diagnosis/state.json',JSON.stringify({startedAt,pid:child.pid,resultFile,stderrFile,output,request:path.resolve(request),requestSha256:sha(fs.readFileSync(request)),manifestFile:path.join(ts.directory,'artifact.json'),manifestSha256:'294fa864b22b32138696ed9dfd54a6e2ae94799ce381628b256dcc0d2d7c3cec',directory:ts.directory,manifest:ts.m,sourceClosureDigest:qualification.sourceClosureDigest,sourceSha256:ts.m.sourceSha256,qualification:false,admission:'not-run',adoption:'not-run',timeoutMs:1750000,timeoutPolicy:'g2g3-correctness-1800s'},null,2)+'\n');
console.log('PSC1_PROGRESSIVE_PROFILE_LAUNCHED: '+JSON.stringify({pid:child.pid,startedAt,qualification:false,requestSha256:sha(fs.readFileSync(request))}));
