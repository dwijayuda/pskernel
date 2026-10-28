// R6 project execution is permitted only in GitHub Actions Linux.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';
import {readOwnedCompilerSources} from '../host-tools/compiler-source-inputs.mjs';
import {resolveTypeScriptCli,typeScriptProfileArgs} from './typescript-cli.mjs';
import {createRegularCoreIngress} from '../packages/pskernel-min/host/ingress.mjs';
assert.equal(process.platform,'linux');assert.equal(process.env.GITHUB_ACTIONS,'true');
assert.match(process.env.GITHUB_SHA||'',/^[0-9a-f]{40}$/);
const abiOnly=process.argv.includes('--abi-only'),dir='dist/pskernel-min/text-preservation';
fs.mkdirSync(dir,{recursive:true});fs.writeFileSync(path.join(dir,'package.json'),'{"type":"module"}\n');
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
function run(command,args,input){
 const r=spawnSync(command,args,{input,encoding:'utf8',timeout:240000,maxBuffer:32*1024*1024});
 assert.equal(r.error,undefined,String(r.error));assert.equal(r.status,0,r.stdout+'\n'+r.stderr);return r.stdout;
}
const actualSources=readOwnedCompilerSources('Ps.BackendTs.Type');
const fixtureSources=readOwnedCompilerSources('Ps.MinKernel.Tests.StringBridge');
for(const [kind,rows]of [['actual',actualSources],['fixture',fixtureSources]]){
 fs.writeFileSync(path.join(dir,kind+'.inputs.json'),JSON.stringify(rows.map(x=>({moduleName:x.module.split('.'),source:x.text}))));
}
fs.writeFileSync(path.join(dir,'native.log'),run('lake',['env','lean','--run','scripts/MinKernelTextPreservation.lean']));
run(process.execPath,[resolveTypeScriptCli(),...typeScriptProfileArgs([
 path.join(dir,'actual.ts'),path.join(dir,'fixture.ts'),'--target','ES2022','--module','ES2022',
 '--moduleResolution','bundler','--strict','--skipLibCheck','--noEmitOnError','--pretty','false'])]);
const G=await import(pathToFileURL(path.resolve(dir,'actual.js')).href);
const F=await import(pathToFileURL(path.resolve(dir,'fixture.js')).href);
const oracle=JSON.parse(fs.readFileSync(path.join(dir,'native.json')));
assert.equal(oracle.append.length,324);assert.equal(oracle.join.length,50);
const bytes=s=>Array.from(Buffer.from(s,'utf8'));
let appendCalls=0;
for(const row of oracle.append){
 for(const name of ['psR6ModernAppend','psR6LegacyAppend']){
  const actual=F[name](row.left,row.right);
  assert.equal(typeof actual,'string');assert.deepEqual(bytes(actual),row.bytes,name);
  appendCalls++;
 }
}
const list=values=>{let out=G.List.nil();for(let i=values.length-1;i>=0;i--)out=G.List.cons(values[i],out);return out;};
for(const row of oracle.join){
 const actual=G.psTsJoin(row.separator,list(row.fragments));assert.equal(typeof actual,'string');
 assert.deepEqual(bytes(actual),row.bytes,'actual psTsJoin');
}
const identities=rows=>rows.map(x=>({module:x.module,path:x.path,bytes:Buffer.byteLength(x.text),sha256:sha(x.text)}));
const files=['actual.ts','actual.js','actual.admissions.json','actual.ir.json','actual.policy.json',
 'fixture.ts','fixture.js','fixture.admissions.json','fixture.ir.json','fixture.policy.json','native.json']
 .map(file=>{const data=fs.readFileSync(path.join(dir,file));return {file,bytes:data.length,sha256:sha(data)}});
for(const stem of ['actual','fixture']){
 const policy=JSON.parse(fs.readFileSync(path.join(dir,stem+'.policy.json')));
 assert.equal(policy.sourceAccepted,true);assert.equal(policy.targetAccepted,true);assert.equal(policy.originalIrAccepted,true);
 assert.equal(policy.providerChecked,false);assert.equal(policy.semanticContractQualified,false);assert.equal(policy.strictSh1Qualified,false);
}
const receipt={schema:'psc1-r6-text-compatibility/1',head:process.env.GITHUB_SHA,platform:process.platform,node:process.version,
 phase:fs.readFileSync('proofs/pskernel-min/TextComposition.lean','utf8').includes('theorem join_utf8')?'composition':'decision',
 appendPairs:324,appendNativeGeneratedCalls:appendCalls,actualJoinCases:50,actualSources:identities(actualSources),
 fixtureSources:identities(fixtureSources),files,byteOracle:'Independent chronological List Nat byte concatenation; no String.append or psTsJoin in the expected fold.',
 boundary:'Native constructive byte theorem and finite generated compatibility; no complete compiler/ECMAScript or opaque-string theorem.'};
if(!abiOnly){
 const official=[];
 for(const stem of ['actual','fixture']){
  const packet=fs.readFileSync(path.join(dir,stem+'.admissions.json'));
  assert.equal(packet.at(-1),10,'source protocol LF');
  const canonical=packet.subarray(0,packet.length-1);fs.writeFileSync(path.join(dir,stem+'.canonical.admissions.json'),canonical);
  const answer=JSON.parse(run('.lake/build/bin/psc1_independent_checker',['--check'],canonical));
  assert.equal(answer.accepted,true,stem+' exact source official');assert.equal(answer.leanVersion,'4.35.0');
  assert.equal(answer.leanCommit,'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
  official.push({stem,accepted:answer.accepted,bytes:canonical.length,sha256:sha(canonical)});
 }
 const kernel=await import(pathToFileURL(path.resolve('dist/pskernel-min/regular-ingress/vectors.js')).href);
 const packet=new Uint8Array(fs.readFileSync(path.join(dir,'fixture.canonical.admissions.json')));
 const refused=createRegularCoreIngress(kernel)(packet);
 assert.equal(refused.accepted,false,'String-bearing declarations remain outside R4B');assert.equal(refused.delegated,false);
 receipt.official=official;receipt.minimalFixture={accepted:refused.accepted,code:refused.code,delegated:refused.delegated};
}
receipt.resourceUsage=process.resourceUsage();
fs.writeFileSync(path.join(dir,abiOnly?'fast-receipt.json':'receipt.json'),JSON.stringify(receipt,null,2)+'\n');
console.log('PSC1_R6_TEXT_'+(abiOnly?'FAST':'FULL')+'_PASS '+JSON.stringify(receipt));
