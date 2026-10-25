// Actual process lifetime/integrity tests, independent of compiler semantics.
import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';
import assert from 'node:assert/strict';import {spawn} from 'node:child_process';import {pathToFileURL} from 'node:url';
import {runGeneratedRustCompiler} from '../host-tools/generated-rust-transport.mjs';
import {linuxProcessIdentity} from '../host-tools/generated-rust-guard.mjs';
const base=path.resolve('dist/generated-rust-transport');fs.mkdirSync(base,{recursive:true});const out=fs.mkdtempSync(path.join(base,'run-'));
const fixture=path.join(out,'fixture.mjs'),adapter=path.join(out,'adapter.mjs');
fs.writeFileSync(fixture,'#!'+process.execPath+'\n'+"import fs from 'node:fs';import {spawn} from 'node:child_process';\nconst [input,output]=process.argv.slice(2),r=JSON.parse(fs.readFileSync(input));\nif(r.mode==='normal')fs.writeFileSync(output,'{\"ok\":true}');\nelse if(r.mode==='mutate'){fs.appendFileSync(input,' ');fs.writeFileSync(output,'{\"ok\":true}');}\nelse if(r.mode==='symlink')fs.symlinkSync(r.outside,output);\nelse if(r.mode==='flood')fs.writeSync(1,Buffer.alloc(33*1024*1024,65));\nelse{\n const child=spawn(process.execPath,['-e','setInterval(()=>{},1000)'],{stdio:'ignore'});\n fs.writeFileSync(r.pidFile,JSON.stringify([process.pid,child.pid]));\n if(r.mode==='exit-with-child'){fs.writeFileSync(output,'{\"ok\":true}');process.exit(0);}\n process.on('SIGTERM',()=>{});setInterval(()=>{},1000);\n}\n");fs.chmodSync(fixture,0o755);
const hash=crypto.createHash('sha256').update(fs.readFileSync(fixture)).digest('hex');
const call=(request,extra={})=>runGeneratedRustCompiler({executable:fixture,executableSha256:hash,request:JSON.stringify(request),...extra});
const wait=ms=>new Promise(r=>setTimeout(r,ms));
async function until(f,ms=5000){const end=Date.now()+ms;while(Date.now()<end){if(f())return;await wait(50);}assert.ok(f(),'process cleanup deadline');}
let checks=0;
assert.deepEqual(JSON.parse(call({mode:'normal'})),{ok:true});checks++;
assert.throws(()=>call({mode:'normal'},{executableSha256:'0'.repeat(64)}));checks++;
assert.throws(()=>call({mode:'normal'},{timeoutMs:0}));checks++;
assert.throws(()=>call({mode:'normal'},{timeoutMs:240001}));checks++;
assert.throws(()=>call({mode:'mutate'}),/PSC1_RUST_REQUEST_CHANGED/);checks++;
const outside=path.join(out,'outside.txt');fs.writeFileSync(outside,'preserved');
assert.throws(()=>call({mode:'symlink',outside}));assert.equal(fs.readFileSync(outside,'utf8'),'preserved');checks++;
assert.throws(()=>call({mode:'flood'},{timeoutMs:5000}),/stdout-limit/);checks++;
const timed=path.join(out,'timed-pids.json');
assert.throws(()=>call({mode:'loop',pidFile:timed},{timeoutMs:1500}),/deadline/);
const timedPids=JSON.parse(fs.readFileSync(timed));await until(()=>timedPids.every(p=>linuxProcessIdentity(p)===null));checks++;
const exited=path.join(out,'exited-pids.json');
assert.deepEqual(JSON.parse(call({mode:'exit-with-child',pidFile:exited})),{ok:true});
const exitedPids=JSON.parse(fs.readFileSync(exited));await until(()=>exitedPids.every(p=>linuxProcessIdentity(p)===null));checks++;
const module=pathToFileURL(path.resolve('host-tools/generated-rust-transport.mjs')).href;
fs.writeFileSync(adapter,'import {runGeneratedRustCompiler} from '+JSON.stringify(module)+';\nrunGeneratedRustCompiler(JSON.parse(process.argv[2]));\n');
const owned=path.join(out,'owner-pids.json'),owner=spawn(process.execPath,[adapter,JSON.stringify({executable:fixture,executableSha256:hash,request:JSON.stringify({mode:'loop',pidFile:owned}),timeoutMs:15000})],{stdio:'ignore'});
try{
 await until(()=>fs.existsSync(owned));const pids=JSON.parse(fs.readFileSync(owned));
 const stat=fs.readFileSync('/proc/'+pids[0]+'/stat','utf8'),guardPid=Number(stat.slice(stat.lastIndexOf(')')+2).trim().split(/\s+/)[1]);
 owner.kill('SIGKILL');await until(()=>linuxProcessIdentity(owner.pid)===null);
 await until(()=>[...pids,guardPid].every(p=>linuxProcessIdentity(p)===null));checks++;
}finally{try{owner.kill('SIGKILL');}catch{}}
const receipt={schema:'psc1-rust-host-transport-regression/1',testedCommit:process.env.GITHUB_SHA,status:'passed',checks,
 normalRequestMs:240000,requestAndResponseMaxBytes:128*1024*1024,streamMaxBytes:32*1024*1024,
 tested:['execution','binary-integrity','timeout-policy-refusals','request-mutation','response-symlink','output-limit','deadline-process-group-cleanup','success-descendant-cleanup','caller-death-group-cleanup'],
 compilerQualification:false,scope:'Node-only Linux process/integrity boundary; compiler qualification is independent'};
fs.writeFileSync(path.join(out,'receipt.json'),JSON.stringify(receipt,null,2)+'\n');console.log('PSC1_RUST_HOST_TRANSPORT_TESTS: '+JSON.stringify(receipt));
