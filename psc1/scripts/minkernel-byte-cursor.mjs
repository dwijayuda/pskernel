// Project execution only on GitHub Actions Linux.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {readOwnedCompilerSources} from '../host-tools/compiler-source-inputs.mjs';
import {resolveTypeScriptCli,typeScriptProfileArgs} from './typescript-cli.mjs';
assert.equal(process.platform,'linux');assert.equal(process.env.GITHUB_ACTIONS,'true');
const abiOnly=process.argv.includes('--abi-only'),dir='dist/pskernel-min/byte-cursor';
fs.mkdirSync(path.join(dir,'vectors'),{recursive:true});fs.writeFileSync(path.join(dir,'package.json'),'{"type":"module"}\n');
const sha=data=>crypto.createHash('sha256').update(data).digest('hex');
function run(command,args,{timeout=240000}={}){
 const result=spawnSync(command,args,{encoding:'utf8',timeout,maxBuffer:32*1024*1024});
 assert.equal(result.error,undefined,String(result.error));assert.equal(result.status,0,result.stdout+'\n'+result.stderr);
 return result.stdout;
}
function expectedDigest(bytes){let value=0;for(const byte of bytes)value=(value*257+byte)%65521;return String(value);}
const rows=[];
function add(label,file,bytes,{command='digest',size=bytes.length,offset=0,remaining=size,invalid=false}={}){
 const expectedCalls=command==='read'?(offset<size?1:0):invalid?Math.min(1,remaining,size):Math.min(remaining,size);
 let expected;
 if(command==='read')expected=String(offset>=size?256:invalid?257:bytes[offset]);
 else expected=invalid&&size>0?'65521':remaining!==size?'65521':expectedDigest(bytes.subarray(0,size));
 rows.push({label,file,command,size,offset,remaining,invalid,expected,expectedCalls});
}
for(const size of [0,1,2,31,255,256,4096,65536,1048576]){
 const bytes=Uint8Array.from({length:size},(_,i)=>(i*73+19)%256);
 const file=path.join(dir,'vectors','pattern-'+size+'.bin');fs.writeFileSync(file,bytes);
 add('digest-'+size,file,bytes);
 add('read-eof-'+size,file,bytes,{command:'read',offset:size});
 if(size){add('read-first-'+size,file,bytes,{command:'read'});add('read-last-'+size,file,bytes,{command:'read',offset:size-1});}
}
const one=Uint8Array.of(17),oneFile=path.join(dir,'vectors','one.bin');fs.writeFileSync(oneFile,one);
add('range-read',oneFile,one,{command:'read',invalid:true});
add('range-digest',oneFile,one,{invalid:true});
add('incomplete-walk',oneFile,one,{command:'walk',remaining:0});
add('past-eof-walk',oneFile,one,{command:'walk',remaining:2});
add('exact-walk',oneFile,one,{command:'walk'});
if(!abiOnly){
 const file='dist/pskernel-min/closure/compiler-admissions.json';assert.ok(fs.existsSync(file),'full compiler transport required');
 const bytes=fs.readFileSync(file);assert.ok(bytes.length>2*1024*1024);
 add('complete-current-compiler-transport',file,bytes);
}
fs.writeFileSync(path.join(dir,'vectors.json'),JSON.stringify(rows));
const sources=readOwnedCompilerSources('Ps.MinKernel.Tests.ByteCursor');
fs.writeFileSync(path.join(dir,'inputs.json'),JSON.stringify(sources.map(x=>({moduleName:x.module.split('.'),source:x.text}))));
fs.writeFileSync(path.join(dir,'native.log'),run('/usr/bin/time',['-f','{"maxRSSKiB":%M,"userSec":%U,"systemSec":%S,"elapsedSec":%e}',
 '-o',path.join(dir,'native-resources.json'),'lake','env','lean','--run','scripts/MinKernelByteCursor.lean']));
const native=JSON.parse(fs.readFileSync(path.join(dir,'native.json')));
assert.equal(native.length,rows.length);for(let i=0;i<rows.length;i++){assert.equal(native[i].label,rows[i].label);assert.equal(native[i].actual,rows[i].expected);}
run(process.execPath,[resolveTypeScriptCli(),...typeScriptProfileArgs([path.join(dir,'cursor.ts'),'--target','ES2022','--module','ES2022',
 '--moduleResolution','bundler','--strict','--skipLibCheck','--noEmitOnError','--pretty','false'])]);
run(process.execPath,['--max-old-space-size=256','scripts/minkernel-byte-cursor-generated.mjs'],{timeout:120000});
const generated=JSON.parse(fs.readFileSync(path.join(dir,'generated.json')));assert.equal(generated.cases,rows.length);
const raw=fs.readFileSync(path.join(dir,'cursor.admissions.json'));assert.equal(raw.at(-1),10);
const canonical=raw.subarray(0,-1);fs.writeFileSync(path.join(dir,'cursor.canonical.admissions.json'),canonical);
let official=null;
if(!abiOnly){
 const answer=spawnSync('.lake/build/bin/psc1_independent_checker',['--check'],{input:canonical,encoding:'utf8',timeout:120000,maxBuffer:32*1024*1024});
 assert.equal(answer.error,undefined,String(answer.error));assert.equal(answer.status,0,answer.stdout+'\n'+answer.stderr);official=JSON.parse(answer.stdout);
 assert.equal(official.accepted,true);assert.equal(official.leanVersion,'4.35.0');assert.equal(official.leanCommit,'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
}
const policy=JSON.parse(fs.readFileSync(path.join(dir,'policy.json')));
for(const k of ['sourceAccepted','targetAccepted','originalIrAccepted'])assert.equal(policy[k],true);
for(const k of ['providerChecked','semanticContractQualified','strictSh1Qualified'])assert.equal(policy[k],false);
const receipt={schema:'psc1-r9-indexed-byte-decision/1',head:process.env.GITHUB_SHA,abiOnly,cases:rows.length,
 decision:'indexed-traversal-qualified; parser-and-admission-not-qualified',
 sourceIdentities:sources.map(x=>({module:x.module,path:x.path,bytes:Buffer.byteLength(x.text),sha256:sha(x.text)})),
 policy,official,nativeResources:JSON.parse(fs.readFileSync(path.join(dir,'native-resources.json'))),
 generated,files:['cursor.ts','cursor.js','cursor.ir.json','cursor.admissions.json','cursor.canonical.admissions.json','native.json'].map(file=>{
  const bytes=fs.readFileSync(path.join(dir,file));return{file,bytes:bytes.length,sha256:sha(bytes)};}),
 parentResourceUsage:process.resourceUsage(),
 boundary:'Private scalar byte-source traversal and reference span correspondence only. Physical adapter fidelity, full parser/arena refinement, foundation, declaration/universe semantics, compiler preservation and public minimal compiler admission remain open.'};
fs.writeFileSync(path.join(dir,abiOnly?'fast-receipt.json':'receipt.json'),JSON.stringify(receipt,null,2)+'\n');
console.log('PSC1_R9_BYTE_SOURCE_DECISION_PASS '+JSON.stringify({cases:rows.length,full:!abiOnly,head:receipt.head}));
