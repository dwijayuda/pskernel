// Genuine checker differential tests. No mocked acceptance or compilation-only pass.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import crypto from 'node:crypto';import {spawnSync} from 'node:child_process';
const [reference,candidate,mode='native']=process.argv.slice(2);assert.ok(reference&&candidate);assert.ok(['native','wasm'].includes(mode));
const sha=b=>crypto.createHash('sha256').update(b).digest('hex'),root={k:'a'},name=v=>({k:'s',p:root,v}),nat={k:'const',n:name('Nat'),ls:[]};
const decl=(n,v,t=nat)=>({kind:'constant',declaration:{k:'definition',h:{k:'regular',h:'1'},lp:[],n:name(n),s:'safe',t,v}});
const wire=admissions=>JSON.stringify({protocol:'pskernel-lean/1',format:'proofscript-checked-admissions',version:2,admissions});
const one=decl('Kernel.Valid',{k:'nat',v:'1'}),bad=decl('Kernel.Bad',{k:'sort',l:{k:'z'}});
const unsafe=JSON.parse(JSON.stringify(one));unsafe.declaration.s='unsafe';
const meta=JSON.parse(JSON.stringify(one));meta.declaration.v={k:'mvar',i:0};
const badHeight=JSON.parse(JSON.stringify(one));badHeight.declaration.h.h='4294967296';
const fixtures=[
 {id:'nat-accept',input:wire([one]),accepted:true},
 {id:'large-nat-accept',input:wire([decl('Kernel.Huge',{k:'nat',v:String((1n<<256n)+1n)})]),accepted:true},
 {id:'kernel-type-rejection',input:wire([bad]),accepted:false,errorKind:'kernel-rejection'},
 {id:'duplicate-declaration-rejection',input:wire([one,one]),accepted:false,errorKind:'kernel-rejection'},
 {id:'unknown-constant-rejection',input:wire([decl('Kernel.Missing',{k:'const',n:name('NotDeclaredAnywhere'),ls:[]})]),accepted:false,errorKind:'kernel-rejection'},
 {id:'unsafe-refusal',input:wire([unsafe]),accepted:false},
 {id:'metavariable-refusal',input:wire([meta]),accepted:false},
 {id:'height-overflow-refusal',input:wire([badHeight]),accepted:false},
 {id:'malformed-json',input:'{',accepted:false,errorKind:'malformed-request'},
 {id:'wrong-format',input:'{"format":"wrong","version":2,"admissions":[]}',accepted:false},
 {id:'wrong-version',input:'{"format":"proofscript-checked-admissions","version":1,"admissions":[]}',accepted:false,errorKind:'protocol-version'},
 {id:'string-version',input:'{"format":"proofscript-checked-admissions","version":"2","admissions":[]}',accepted:false},
 {id:'unknown-admission',input:wire([{kind:'unknown',declaration:{}}]),accepted:false},
 {id:'truncated-structured-name',input:wire([decl('Kernel.Broken',{k:'const',n:{k:'s'},ls:[]})]),accepted:false}
];
function run(file,command,input,isWasm){const start=Date.now(),r=spawnSync(isWasm?process.execPath:file,isWasm?[file,command]:[command],{input,encoding:'utf8',timeout:120000,maxBuffer:32*1024*1024,killSignal:'SIGKILL'});assert.equal(r.error,undefined,String(r.error));assert.equal(r.status,0,r.stderr);const value=JSON.parse(r.stdout.trim());for(const [k,v]of Object.entries({protocol:'pskernel-lean/1',provider:'lean4-cpp',leanVersion:'4.35.0',leanCommit:'eb6cafb7290e8bd5f2937522d8d804f58f02bafc',profile:'lean4.35-core'}))assert.equal(value[k],v,k);return {value,elapsedMs:Date.now()-start};}
assert.deepEqual(run(reference,'--health').value,run(candidate,'--health',undefined,mode==='wasm').value);
const observations=[];for(const f of fixtures){const a=run(reference,'--check',f.input),b=run(candidate,'--check',f.input,mode==='wasm');assert.deepEqual(b.value,a.value,f.id);assert.equal(b.value.accepted,f.accepted,f.id);if(f.errorKind)assert.equal(b.value.errorKind,f.errorKind,f.id);observations.push({id:f.id,accepted:b.value.accepted,errorKind:b.value.errorKind,requestSha256:sha(f.input),referenceMs:a.elapsedMs,candidateMs:b.elapsedMs});}
const receipt={schema:'psc1-kernel435-differential/1',testedCommit:process.env.GITHUB_SHA,mode,status:'passed',platform:process.platform,arch:process.arch,referenceSha256:sha(fs.readFileSync(reference)),candidateSha256:sha(fs.readFileSync(candidate)),observations,checkerMs:120000,resourcePolicy:'unchanged finite admission heartbeat and recursion limits'};
fs.mkdirSync('dist/kernel435',{recursive:true});fs.writeFileSync('dist/kernel435/'+mode+'-'+process.arch+'.json',JSON.stringify(receipt,null,2)+'\n');console.log('PSC1_KERNEL435_DIFFERENTIAL: '+JSON.stringify(receipt));
