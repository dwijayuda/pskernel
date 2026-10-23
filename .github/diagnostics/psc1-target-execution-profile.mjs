// Read exact generated artifacts and sample actual TS G2; no candidate adoption.
import assert from 'node:assert/strict';import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';import {spawnSync} from 'node:child_process';
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const files=[];function scan(d){for(const e of fs.readdirSync(d,{withFileTypes:true})){const p=path.join(d,e.name);if(e.isDirectory())scan(p);else if(e.isFile())files.push(p);}}scan('input');
fs.mkdirSync('diagnosis',{recursive:true});
function artifact(target,expected){
 const file=files.find(p=>p.endsWith('/G1-service/artifact.json')&&JSON.parse(fs.readFileSync(p,'utf8')).target===target);
 assert.ok(file);assert.equal(sha(fs.readFileSync(file)),expected);const m=JSON.parse(fs.readFileSync(file,'utf8')),directory=path.dirname(file);
 const verify=()=>{assert.equal(sha(fs.readFileSync(file)),expected);for(const f of m.files){assert.match(f.path,/^[a-zA-Z0-9_.-]+$/);const p=path.join(directory,f.path);assert.ok(fs.lstatSync(p).isFile()&&!fs.lstatSync(p).isSymbolicLink());const b=fs.readFileSync(p);assert.equal(b.length,f.bytes);assert.equal(sha(b),f.sha256);}};
 verify();return{m,directory,verify};
}
const rust=artifact('rust','ec0b0e6b3ddd90f8bc237e65f581a3e64f850b0d9de00b74a09580bbeee8a8fd');
const rustSource=fs.readFileSync(path.join(rust.directory,'module.rs'),'utf8');
for(const name of ['__psr_psJsonStringCharsAccWithFuel_u36_worker','psJsonStringToChars','psJsonStringCharsAccWithFuel','psJsonStringCharsWithFuel','psJsonStringAtEnd','psJsonStringNext','psJsonStringGet']){
 const lines=rustSource.split('\n').filter(l=>new RegExp('\\bfn '+name+'(?:[<( ])').test(l));
 console.log('PSC1_RUST_OWNED_SOURCE: '+JSON.stringify({name,sourceSha256:sha(rustSource),matches:lines.map(l=>({bytes:l.length,source:l.slice(0,16000)}))}));
}
const ts=artifact('ts','42e9b9e4d66267c419a9ceaa6d67bc652823b87496214c41b0b3a06ea551aa4e');
const request=files.find(p=>p.endsWith('/G2-self.request.json')&&p.includes('generated-ts-compiler'));assert.ok(request);
assert.equal(sha(fs.readFileSync(request)),'5373da197f242582478a55863abb9f15a01154b7775c02ff6b3fde8e38d237e6');
const qualification=JSON.parse(fs.readFileSync(path.join(path.dirname(ts.directory),'qualification.json'),'utf8'));
console.log('PSC1_TS_EXECUTING_RECEIPT: '+JSON.stringify({bootstrap:qualification.bootstrap,serviceArtifact:qualification.serviceArtifact,generations:qualification.generations.map(g=>({generation:g.generation,observations:g.observations})),sourceClosureDigest:qualification.sourceClosureDigest,events:qualification.events}));
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
 command:[process.execPath,'--prof','--logfile='+path.resolve('diagnosis/ts-g2-v8.log'),runner,path.resolve(ts.directory,ts.m.executable),path.resolve(request),output],
 directory,timeoutMs:1000,maxBuffer:32*1024*1024})],{encoding:'utf8',timeout:35000,killSignal:'SIGKILL',maxBuffer:1024*1024});
assert.equal(r.status,0,r.stderr);ts.verify();rust.verify();
assert.equal(sha(fs.readFileSync(request)),'5373da197f242582478a55863abb9f15a01154b7775c02ff6b3fde8e38d237e6');
console.log('PSC1_TS_EXECUTION_SAMPLE: '+JSON.stringify({result:JSON.parse(r.stdout),responseProduced:fs.existsSync(output),qualification:false,adoption:'not-run',admission:'not-run'}));
for(const name of fs.readdirSync('diagnosis').filter(n=>n.endsWith('.log'))){
 const p=path.resolve('diagnosis',name),profile=spawnSync(process.execPath,['--prof-process',p],{encoding:'utf8',timeout:30000,killSignal:'SIGKILL',maxBuffer:32*1024*1024});
 fs.writeFileSync(p+'.txt',profile.stdout||'');
 console.log('PSC1_TS_EXECUTION_CPU: '+JSON.stringify({file:name,status:profile.status,summary:(profile.stdout||'').split('\n').slice(0,150)}));
}
