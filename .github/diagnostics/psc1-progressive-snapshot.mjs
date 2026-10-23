import assert from 'node:assert/strict';import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';import {spawnSync} from 'node:child_process';
const sha=b=>crypto.createHash('sha256').update(b).digest('hex'),state=JSON.parse(fs.readFileSync('diagnosis/state.json'));
const phase=Number(process.argv[2]);assert.ok([240,600,1200,1750].includes(phase));
function result(){try{return JSON.parse(fs.readFileSync(state.resultFile,'utf8'));}catch{return null;}}
while(Date.now()<state.startedAt+phase*1000&&!result())await new Promise(r=>setTimeout(r,1000));
if(phase===1750){const until=Date.now()+6500;while(!result()&&Date.now()<until)await new Promise(r=>setTimeout(r,100));assert.ok(result(),'supervisor did not finish');}
assert.equal(sha(fs.readFileSync(state.request)),state.requestSha256);
assert.equal(sha(fs.readFileSync(state.manifestFile)),state.manifestSha256);
for(const f of state.manifest.files){const bytes=fs.readFileSync(path.join(state.directory,f.path));assert.equal(bytes.length,f.bytes);assert.equal(sha(bytes),f.sha256);}
const directory=path.resolve('diagnosis/phase-'+phase);fs.mkdirSync(directory,{recursive:true});
const logs=fs.readdirSync('diagnosis').filter(n=>n.endsWith('ts-g2-v8.log'));assert.equal(logs.length,1);
const original=path.resolve('diagnosis',logs[0]),lines=fs.readFileSync(original,'utf8').split('\n');if(lines.at(-1)!=='')lines.pop();
const ticks=lines.filter(l=>l.startsWith('tick,')).map(l=>l.split(',')),first=Number(ticks[0]?.[2]),last=Number(ticks.at(-1)?.[2]);assert.ok(last>first);
const selected=lines.filter(l=>!l.startsWith('tick,')||Number(l.split(',')[2])>=last-30000000),file=path.join(directory,'slice.log');fs.writeFileSync(file,selected.join('\n'));
const p=spawnSync(process.execPath,['--prof-process',file],{encoding:'utf8',timeout:30000,killSignal:'SIGKILL',maxBuffer:32*1024*1024});assert.equal(p.status,0,p.stderr);
fs.writeFileSync(path.join(directory,'cpu.txt'),p.stdout);
const rows=p.stdout.split('\n'),bottom=rows.findIndex(l=>l.includes('[Bottom up'));
const receipt={schema:'psc1-progressive-profile/1',phase,elapsedMs:Date.now()-state.startedAt,requestSha256:state.requestSha256,manifestSha256:state.manifestSha256,sourceClosureDigest:state.sourceClosureDigest,sourceSha256:state.sourceSha256,firstTick:first,lastTick:last,totalTicks:ticks.length,selectedTicks:selected.filter(l=>l.startsWith('tick,')).length,windowMicros:30000000,execution:result(),responseProduced:fs.existsSync(state.output),sourceFilesVerified:true,qualification:false,admission:'not-run',adoption:'not-run',cpu:{summary:rows.slice(0,90),stringEqual:rows.filter(l=>l.includes('StringEqual')),bottomUp:rows.slice(bottom,bottom+200)}};
fs.writeFileSync(path.join(directory,'receipt.json'),JSON.stringify(receipt,null,2)+'\n');
console.log('PSC1_PROGRESSIVE_PROFILE_SNAPSHOT: '+JSON.stringify(receipt));
