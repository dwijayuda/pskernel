// Project execution only on GitHub Actions Linux.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';
import {readOwnedCompilerSources} from '../host-tools/compiler-source-inputs.mjs';
import {resolveTypeScriptCli,typeScriptProfileArgs} from './typescript-cli.mjs';
assert.equal(process.platform,'linux');assert.equal(process.env.GITHUB_ACTIONS,'true');
const abiOnly=process.argv.includes('--abi-only');
const dir='dist/pskernel-min/compiler-caller';fs.mkdirSync(dir,{recursive:true});
fs.writeFileSync(path.join(dir,'package.json'),'{"type":"module"}\n');
const sha=data=>crypto.createHash('sha256').update(data).digest('hex');
function run(command,args,input){
 const r=spawnSync(command,args,{input,encoding:'utf8',timeout:240000,maxBuffer:32*1024*1024});
 assert.equal(r.error,undefined,String(r.error));assert.equal(r.status,0,r.stdout+'\n'+r.stderr);return r.stdout;
}
const sources=readOwnedCompilerSources('Ps.MinKernel.Tests.CompilerCaller');
fs.writeFileSync(path.join(dir,'inputs.json'),JSON.stringify(sources.map(x=>({moduleName:x.module.split('.'),source:x.text}))));
fs.writeFileSync(path.join(dir,'native.log'),run('lake',['env','lean','--run','scripts/MinKernelCompilerCaller.lean']));
run(process.execPath,[resolveTypeScriptCli(),...typeScriptProfileArgs([path.join(dir,'caller.ts'),'--target','ES2022','--module','ES2022','--moduleResolution','bundler','--strict','--skipLibCheck','--noEmitOnError','--pretty','false'])]);
const G=await import(pathToFileURL(path.resolve(dir,'caller.js')).href);
const rows=JSON.parse(fs.readFileSync(path.join(dir,'native.json')));assert.equal(rows.length,264);
for(const row of rows){const value=row.kind==='nat'?BigInt(row.value):row.value;
 const got=G[row.name](BigInt(row.depth),row.typeBinder,BigInt(row.fuel),value);assert.equal(got,row.expected,row.name);}
const raw=fs.readFileSync(path.join(dir,'caller.admissions.json'));assert.equal(raw.at(-1),10);
const canonical=raw.subarray(0,-1);fs.writeFileSync(path.join(dir,'caller.canonical.admissions.json'),canonical);
let official=null;
if(!abiOnly){
 official=JSON.parse(run('.lake/build/bin/psc1_independent_checker',['--check'],canonical));
 assert.equal(official.accepted,true);assert.equal(official.leanVersion,'4.35.0');
 assert.equal(official.leanCommit,'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
}
const policy=JSON.parse(fs.readFileSync(path.join(dir,'policy.json')));
for(const k of ['sourceAccepted','targetAccepted','originalIrAccepted'])assert.equal(policy[k],true);
for(const k of ['providerChecked','semanticContractQualified','strictSh1Qualified'])assert.equal(policy[k],false);
const receipt={schema:'psc1-min-compiler-caller/1',head:process.env.GITHUB_SHA,cases:rows.length,
 sourceIdentities:sources.map(x=>({module:x.module,path:x.path,bytes:Buffer.byteLength(x.text),sha256:sha(x.text)})),
 policy,official,files:['caller.ts','caller.js','caller.ir.json','caller.admissions.json','caller.canonical.admissions.json','native.json'].map(file=>{
 const data=fs.readFileSync(path.join(dir,file));return {file,bytes:data.length,sha256:sha(data)};}),
 resourceUsage:process.resourceUsage(),boundary:'Actual literal and type/proof-let recursive caller under explicit eligibility, pure Core literal/zeta relation and shared Core instantiation. Runtime binding, classifier/type soundness, independent substitution correctness, variables/calls and complete compiler preservation remain open.'};
fs.writeFileSync(path.join(dir,abiOnly?'fast-receipt.json':'receipt.json'),JSON.stringify(receipt,null,2)+'\n');
console.log('PSC1_CALLER_GENERATED_PASS '+JSON.stringify(receipt));
