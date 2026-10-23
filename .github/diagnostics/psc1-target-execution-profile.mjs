// Sample the exact closed/lexer-normalized TS compiler's late actual G2; no adoption.
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
const ts=artifact('ts','1b4122ae54df5f684335e6df3752e0f4335769c641aa0756d0e2be236d55e29e');
const request=files.find(p=>p.endsWith('/G2-self.request.json')&&p.includes('generated-ts-compiler'));assert.ok(request);
assert.equal(sha(fs.readFileSync(request)),'1e70cf4ad642a393bb4084e2a330ea08e2332c3e51741cbb0b184d0ea852a711');
const qualification=JSON.parse(fs.readFileSync(path.join(path.dirname(ts.directory),'qualification.json'),'utf8'));
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
const r=spawnSync('python3',['.github/diagnostics/bounded-process.py',JSON.stringify({
 command:[process.execPath,'--prof','--logfile='+path.resolve('diagnosis/ts-g2-v8.log'),runner,path.resolve(ts.directory,ts.m.executable),path.resolve(request),output],
 directory,timeoutMs:220000,maxBuffer:32*1024*1024})],{encoding:'utf8',timeout:225000,killSignal:'SIGKILL',maxBuffer:1024*1024});
assert.equal(r.status,0,r.stderr);ts.verify();
assert.equal(sha(fs.readFileSync(request)),'1e70cf4ad642a393bb4084e2a330ea08e2332c3e51741cbb0b184d0ea852a711');
console.log('PSC1_TS_EXECUTION_SAMPLE: '+JSON.stringify({result:JSON.parse(r.stdout),responseProduced:fs.existsSync(output),qualification:false,adoption:'not-run',admission:'not-run'}));
for(const name of fs.readdirSync('diagnosis').filter(n=>n.endsWith('.log'))){
 const original=path.resolve('diagnosis',name),lines=fs.readFileSync(original,'utf8').split('\n');
 const ticks=lines.filter(l=>l.startsWith('tick,')).map(l=>l.split(','));
 const first=Number(ticks[0]?.[2]),last=Number(ticks.at(-1)?.[2]);
 assert.ok(last-first>150000000&&last-first<300000000,'tick timestamps must match bounded replay');
 const selected=lines.filter(l=>!l.startsWith('tick,')||Number(l.split(',')[2])>=last-30000000);
 const p=original+'.late.log';fs.writeFileSync(p,selected.join('\n'));
 console.log('PSC1_TS_LATE_TICKS: '+JSON.stringify({first,last,total:ticks.length,selected:selected.filter(l=>l.startsWith('tick,')).length,windowMicros:30000000,qualification:false}));
 const profile=spawnSync(process.execPath,['--prof-process',p],{encoding:'utf8',timeout:30000,killSignal:'SIGKILL',maxBuffer:32*1024*1024});
 fs.writeFileSync(p+'.txt',profile.stdout||'');
 console.log('PSC1_TS_EXECUTION_CPU: '+JSON.stringify({file:name,status:profile.status,summary:(profile.stdout||'').split('\n').slice(0,150)}));
}
