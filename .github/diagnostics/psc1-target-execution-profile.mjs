// Profile the current applied-erasure compiler: final 30 seconds of an up-to1750-second exact G2 replay; diagnostic only.
import assert from 'node:assert/strict';import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';import {spawnSync} from 'node:child_process';
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
const ts=artifact('ts','f594ea3fee41844add79b774b63df7dd80b8eead15fe265e830768173aa1329d');
const request=files.find(p=>p.endsWith('/G2-self.request.json')&&p.includes('generated-ts-compiler'));assert.ok(request);
assert.equal(sha(fs.readFileSync(request)),'ae97450bad8f2130d344b0ee98a63766e82849d2b7f897a2b700e7630bdeeb1e');
assert.equal(JSON.parse(fs.readFileSync(request,'utf8'))[1],'G2-self');
const qualification=JSON.parse(fs.readFileSync(path.join(path.dirname(ts.directory),'qualification.json'),'utf8'));
assert.equal(qualification.sourceClosureDigest,'9db57f58b183ff8267116b762a8f6a35b1d375301883abc6881987a53bca1abc');
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
const r=spawnSync('python3',['.github/diagnostics/psc1-selfhost-bounded-process.py',JSON.stringify({
 command:[process.execPath,'--prof','--logfile='+path.resolve('diagnosis/ts-g2-v8.log'),runner,path.resolve(ts.directory,ts.m.executable),path.resolve(request),output],
 directory,timeoutMs:1750000,timeoutPolicy:'g2g3-correctness-1800s',maxBuffer:32*1024*1024})],{encoding:'utf8',timeout:1755000,killSignal:'SIGKILL',maxBuffer:1024*1024});
assert.equal(r.status,0,r.stderr);ts.verify();
assert.equal(sha(fs.readFileSync(request)),'ae97450bad8f2130d344b0ee98a63766e82849d2b7f897a2b700e7630bdeeb1e');
const execution=JSON.parse(r.stdout);
console.log('PSC1_TS_EXECUTION_SAMPLE: '+JSON.stringify({result:execution,responseProduced:fs.existsSync(output),qualification:false,adoption:'not-run',admission:'not-run'}));
for(const name of fs.readdirSync('diagnosis').filter(n=>n.endsWith('.log'))){
 const original=path.resolve('diagnosis',name),lines=fs.readFileSync(original,'utf8').split('\n');
 const ticks=lines.filter(l=>l.startsWith('tick,')).map(l=>l.split(','));
 const first=Number(ticks[0]?.[2]),last=Number(ticks.at(-1)?.[2]);
 assert.ok(last-first>1000000&&last-first<1760000000,'tick timestamps must match at-most1750s replay');
 if(execution.error?.code==='ETIMEDOUT')assert.ok(last-first>1700000000,'deadline profile must reach late request window');
 const selected=lines.filter(l=>!l.startsWith('tick,')||Number(l.split(',')[2])>=last-30000000);
 const p=original+'.late.log';fs.writeFileSync(p,selected.join('\n'));
 console.log('PSC1_TS_LATE_TICKS: '+JSON.stringify({first,last,total:ticks.length,selected:selected.filter(l=>l.startsWith('tick,')).length,windowMicros:30000000,qualification:false}));
 const profile=spawnSync(process.execPath,['--prof-process',p],{encoding:'utf8',timeout:30000,killSignal:'SIGKILL',maxBuffer:32*1024*1024});
 fs.writeFileSync(p+'.txt',profile.stdout||'');
 console.log('PSC1_TS_EXECUTION_CPU: '+JSON.stringify({file:name,status:profile.status,stringEqual:(profile.stdout||'').split('\n').filter(l=>l.includes('StringEqual')),summary:(profile.stdout||'').split('\n').slice(0,85),bottomUp:(profile.stdout||'').split('\n').slice((profile.stdout||'').split('\n').findIndex(l=>l.includes('[Bottom up')), (profile.stdout||'').split('\n').findIndex(l=>l.includes('[Bottom up'))+240)}));
}
