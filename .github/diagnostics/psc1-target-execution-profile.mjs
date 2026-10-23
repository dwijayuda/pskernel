// Inspect actual generated code and cache argument sizes: final 30 seconds of a 220-second G2 replay, not the end of the 1800-second request.
import assert from 'node:assert/strict';import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';import {spawnSync} from 'node:child_process';
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const files=[];function scan(d){for(const e of fs.readdirSync(d,{withFileTypes:true})){const p=path.join(d,e.name);if(e.isDirectory())scan(p);else if(e.isFile())files.push(p);}}scan('input');
fs.mkdirSync('diagnosis',{recursive:true});
console.log('PSC1_PROFILE_SOURCE: current applied-lookup TS artifact; final 30 seconds of bounded 220s replay; diagnostic only');
function artifact(target,expected){
 const file=files.find(p=>p.endsWith('/G1-service/artifact.json')&&JSON.parse(fs.readFileSync(p,'utf8')).target===target);
 assert.ok(file);assert.equal(sha(fs.readFileSync(file)),expected);const m=JSON.parse(fs.readFileSync(file,'utf8')),directory=path.dirname(file);
 const verify=()=>{assert.equal(sha(fs.readFileSync(file)),expected);for(const f of m.files){assert.match(f.path,/^[a-zA-Z0-9_.-]+$/);const p=path.join(directory,f.path);assert.ok(fs.lstatSync(p).isFile()&&!fs.lstatSync(p).isSymbolicLink());const b=fs.readFileSync(p);assert.equal(b.length,f.bytes);assert.equal(sha(b),f.sha256);}};
 verify();return{m,directory,verify};
}
const ts=artifact('ts','e3e93fc46e47ad6036769b6d98655e1a426cb3917bd6417a58254b65d0f9e29f');
const request=files.find(p=>p.endsWith('/G2-self.request.json')&&p.includes('generated-ts-compiler'));assert.ok(request);
assert.equal(sha(fs.readFileSync(request)),'cffb8230e123e8e9411de5e02133b0b8191dd2c8110f2e2c6a3c0c7651836c2f');
const qualification=JSON.parse(fs.readFileSync(path.join(path.dirname(ts.directory),'qualification.json'),'utf8'));
assert.equal(qualification.sourceClosureDigest,'8a875f219d60c3cb7b266569b5533dd96c4e891adbac7fbb02b1215f6fbdbccf');
assert.equal(ts.m.sourceSha256,qualification.bootstrap.sourceSha256);
console.log('PSC1_TS_EXECUTING_RECEIPT: '+JSON.stringify({bootstrap:qualification.bootstrap,serviceArtifact:qualification.serviceArtifact,generations:qualification.generations.map(g=>({generation:g.generation,observations:g.observations})),sourceClosureDigest:qualification.sourceClosureDigest,events:qualification.events,targetPlans:qualification.targetPlans}));

const modulePath=path.resolve(ts.directory,ts.m.executable),original=fs.readFileSync(modulePath,'utf8');
for(const name of ['function psStringEqFromWithFuel$worker','function psStringEqFrom','function* __ps$impl$psStringEq','function __ps$utf8']) {
 const start=original.indexOf(name);console.log('PSC1_STRINGEQ_SOURCE: '+JSON.stringify({name,start,source:original.slice(start,start+9000)}));
}
const modified=original.replace(/if \(__ps\$lastUtf8\?\.text === text\)/g,'if (__ps$cacheEq(__ps$lastUtf8?.text, text))').replace(/if \(__ps\$previousUtf8\?\.text === text\)/g,'if (__ps$cacheEq(__ps$previousUtf8?.text, text))');
assert.notEqual(modified,original);
const prefix=[
'const __ps$cacheStats={calls:0,equal:0,largeEqual:0,largeUnequal:0,lengthMismatch:0,max:0,buckets:{}};',
'function __ps$cacheEq(a,b){ const r=a===b; const s=__ps$cacheStats;s.calls++;if(r)s.equal++;if(a?.length!==b.length)s.lengthMismatch++;if(b.length>4096){if(r)s.largeEqual++;else s.largeUnequal++;}s.max=Math.max(s.max,b.length);const k=(r?"equal:":"unequal:")+(b.length<64?"small":b.length<4096?"medium":"large");s.buckets[k]=(s.buckets[k]??0)+1;if(s.calls%1000000===0)console.error("PSC1_CACHE_COUNTERS: "+JSON.stringify(s));return r;}',
].join('\n');
const diagnosticModule=path.resolve(ts.directory,'diagnostic.mjs');fs.writeFileSync(diagnosticModule,prefix+'\n'+modified);
const runner=path.resolve('diagnosis/runner.mjs');
fs.writeFileSync(runner,[
"import fs from 'node:fs';import{pathToFileURL}from'node:url';",
"const api=await import(pathToFileURL(process.argv[2]).href);",
"const input=fs.readFileSync(process.argv[3],'utf8');",
"const response=api.psCompilerTsServiceCandidate(input);",
"if(typeof response!=='string'||Buffer.byteLength(response)>134217728)throw Error('response bound');",
"fs.writeFileSync(process.argv[4],response);"].join('\n'));
const directory=path.resolve('diagnosis/execution'),output=path.resolve('diagnosis/unadopted-response.json');
const r=spawnSync('python3',['.github/diagnostics/bounded-process.py',JSON.stringify({
 command:[process.execPath,'--prof','--logfile='+path.resolve('diagnosis/ts-g2-v8.log'),runner,diagnosticModule,path.resolve(request),output],
 directory,timeoutMs:60000,maxBuffer:32*1024*1024})],{encoding:'utf8',timeout:65000,killSignal:'SIGKILL',maxBuffer:1024*1024});
assert.equal(r.status,0,r.stderr);ts.verify();
assert.equal(sha(fs.readFileSync(request)),'cffb8230e123e8e9411de5e02133b0b8191dd2c8110f2e2c6a3c0c7651836c2f');
console.log('PSC1_TS_EXECUTION_SAMPLE: '+JSON.stringify({result:JSON.parse(r.stdout),responseProduced:fs.existsSync(output),qualification:false,adoption:'not-run',admission:'not-run'}));

console.log('PSC1_CACHE_LOG: '+JSON.stringify(fs.readdirSync(directory).map(name=>({name,text:fs.readFileSync(path.join(directory,name),'utf8').slice(-24000)}))));
