// Execute only on GitHub Actions Linux. No independent acceptance authority.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';
import {resolveTypeScriptCli,typeScriptProfileArgs} from './typescript-cli.mjs';
import {createRegularCoreIngress} from '../packages/pskernel-min/host/ingress.mjs';
assert.equal(process.platform,'linux');
assert.equal(process.env.GITHUB_ACTIONS,'true');
assert.match(process.env.GITHUB_SHA||'',/^[0-9a-f]{40}$/);
const abiOnly=process.argv.includes('--abi-only');
const dir='dist/pskernel-min/compiler-preservation';
fs.mkdirSync(dir,{recursive:true});
fs.writeFileSync(path.join(dir,'package.json'),'{"type":"module"}\n');
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
function run(command,args,input){
 const result=spawnSync(command,args,{input,encoding:'utf8',timeout:240000,maxBuffer:32*1024*1024});
 assert.equal(result.error,undefined,String(result.error));
 assert.equal(result.status,0,result.stdout+'\n'+result.stderr);
 return result.stdout;
}
const nativeLog=run('lake',['env','lean','--run','scripts/MinKernelCompilerPreservation.lean']);
fs.writeFileSync(path.join(dir,'native.log'),nativeLog);
const oracle=JSON.parse(fs.readFileSync(path.join(dir,'native.json')));
assert.equal(oracle.probes.length,400);
assert.equal(oracle.stageIrAccepted,true);
assert.equal(oracle.arityRefusals,30);
assert.equal(oracle.strictIrRefusals,4);
assert.equal(oracle.binaryStageRefusals,30);
assert.equal(oracle.recognizerRefusals,30);
assert.equal(oracle.recognizerCases,10);
const admissions=fs.readFileSync(path.join(dir,'whole.admissions.json'));
// The source API emits one NDJSON transport LF. The byte profile requires EOF.
assert.equal(admissions.at(-1),10,'pinned source transport LF');
const canonicalAdmissions=admissions.subarray(0,admissions.length-1);
assert.equal(canonicalAdmissions.at(-1),125,'canonical packet closes at EOF');
fs.writeFileSync(path.join(dir,'whole.canonical.admissions.json'),canonicalAdmissions);
run(process.execPath,[resolveTypeScriptCli(),...typeScriptProfileArgs([
 path.join(dir,'direct.ts'),path.join(dir,'stages.ts'),path.join(dir,'whole.ts'),'--target','ES2022','--module','ES2022',
 '--moduleResolution','bundler','--strict','--skipLibCheck','--noEmitOnError','--pretty','false'])]);
const direct=await import(pathToFileURL(path.resolve(dir,'direct.js')).href);
const stages=await import(pathToFileURL(path.resolve(dir,'stages.js')).href);
const whole=await import(pathToFileURL(path.resolve(dir,'whole.js')).href);
assert.equal(direct.probes.length,400);
for(let i=0;i<oracle.probes.length;i++){
 const want=oracle.probes[i],got=direct.probes[i]();
 assert.equal(typeof got,want.type,'representation '+i);
 assert.equal(String(got),want.value,'native/generated '+i);
}
assert.equal(stages.captureProbe,2n);
assert.equal(direct.literalProbes.length,3);
assert.deepEqual(direct.literalProbes.map(f=>f()),[undefined,false,true]);
assert.equal(stages.combinedProbe(11n),18n);
const large=(1n<<256n)+12345n;
assert.equal(stages.curryProbe(large)(5n)(true),large+5n);
assert.equal(stages.curryProbe(2n)(5n)(false),0n);
assert.equal(stages.shadowProbe(71n)(23n),23n);
const traces=direct.traced.map(f=>f());
assert.deepEqual(traces.map(x=>x.trace),[...Array(8).fill('LR'),'L','LR','LR','L']);
assert.equal(oracle.wholeProbes.length,294);
let wholeCalls=0;
for(const row of oracle.wholeProbes){
 const args=row.arguments.map(x=>typeof x==='boolean'?x:BigInt(x));
 const got=whole[row.export](...args);
 assert.equal(typeof got,'bigint',row.export+' representation');
 assert.equal(String(got),row.value,row.export+' actual native/generated');
 wholeCalls++;
}
assert.equal(wholeCalls,294);
if(abiOnly){
 const fast={schema:'psc1-r5-fast-abi/1',head:process.env.GITHUB_SHA,platform:process.platform,
  node:process.version,scalarProbes:400,wholeSourceCalls:wholeCalls,literalAbiProbes:3,
  checkedStructuralIrDeclarations:4,operandTraceProbes:traces.length,
  boundary:'Finite engine and native-source ABI checks only; official and R4B byte admissions run in the portability job.'};
 fs.writeFileSync(path.join(dir,'fast-abi.json'),JSON.stringify(fast,null,2)+'\n');
 console.log('PSC1_R5_FAST_ABI_PASS '+JSON.stringify(fast));process.exit(0);
}
const official=JSON.parse(run('.lake/build/bin/psc1_independent_checker',['--check'],admissions));
assert.equal(official.accepted,true);
assert.equal(official.leanVersion,'4.35.0');
assert.equal(official.leanCommit,'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
const canonicalOfficial=JSON.parse(run('.lake/build/bin/psc1_independent_checker',['--check'],canonicalAdmissions));
assert.equal(canonicalOfficial.accepted,true);
assert.equal(canonicalOfficial.leanVersion,'4.35.0');
assert.equal(canonicalOfficial.leanCommit,'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
const generated=await import(pathToFileURL(path.resolve('dist/pskernel-min/regular-ingress/vectors.js')).href);
const byteCheck=createRegularCoreIngress(generated);
const framed=byteCheck(new Uint8Array(admissions));
assert.equal(framed.accepted,false,'transport LF remains outside the byte profile');
assert.equal(framed.delegated,false);
const owned=byteCheck(new Uint8Array(canonicalAdmissions));
fs.writeFileSync(path.join(dir,'byte-admission.json'),JSON.stringify({
 originalTransport:{accepted:framed.accepted,code:framed.code,delegated:framed.delegated,bytes:admissions.length,sha256:sha(admissions)},
 canonical:{accepted:owned.accepted,code:owned.code,delegated:owned.delegated,bytes:canonicalAdmissions.length,sha256:sha(canonicalAdmissions)},
 transform:'Remove exactly one terminal transport LF; preserve every preceding byte.',
 officialOriginal:official.accepted,officialCanonical:canonicalOfficial.accepted},null,2)+'\n');
assert.equal(owned.accepted,true,'R4B exact canonical source packet: '+owned.code);
assert.equal(owned.delegated,false);
const policy=JSON.parse(fs.readFileSync(path.join(dir,'source-policy.json')));
assert.equal(policy.sourceAccepted,true);assert.equal(policy.targetAccepted,true);
assert.equal(policy.originalIrAccepted,true);assert.equal(policy.providerChecked,false);
assert.equal(policy.semanticContractQualified,false);assert.equal(policy.strictSh1Qualified,false);
assert.equal(policy.moduleCount,1);assert.equal(policy.originModuleCount,1);
const ir=JSON.parse(fs.readFileSync(path.join(dir,'whole.ir.json')));
assert.equal(ir[0],'psc1-ir/1');
assert.ok(ir[4].length>=6);
const sourceNames=['psR5Add','psR5Sub','psR5Choose','psR5Three','psR5Capture','psR5UseClosure'];
for(const name of sourceNames)assert.equal(ir[4].filter(d=>d[0]===name).length,1,'exact source IR declaration '+name);
const originalIrAbi=ir[4].map(d=>({name:d[0],typeParameters:d[1],parameters:d[2],resultType:d[3]}));
const origins=JSON.parse(fs.readFileSync(path.join(dir,'origins.json')));
assert.equal(origins.length,1);
assert.equal(origins[0].batches.length,6);
const stageIr=JSON.parse(fs.readFileSync(path.join(dir,'stages.ir.json')));
assert.equal(stageIr[0],'psc1-ir/1');assert.equal(stageIr[4].length,4);
const paths=['direct.ts','direct.js','stages.ts','stages.js','stages.ir.json','whole.ts','whole.js','whole.admissions.json','whole.canonical.admissions.json','byte-admission.json','whole.ir.json','origins.json','source.lean','native.json'];
const files=paths.map(file=>{const bytes=fs.readFileSync(path.join(dir,file));return {file,bytes:bytes.length,sha256:sha(bytes)}});
assert.equal(sha(fs.readFileSync('packages/pskernel-min/src/Ps/MinKernel/Tests/CompilerScalar.lean')),
 sha(fs.readFileSync(path.join(dir,'source.lean'))),'exact same physical source');
const sources=['packages/pskernel-min/src/Ps/MinKernel/Tests/CompilerScalar.lean','proofs/pskernel-min/CompilerPreservation.lean','scripts/MinKernelCompilerPreservation.lean',
 'scripts/minkernel-compiler-preservation.mjs','scripts/minkernel-compiler-preservation-guard.mjs',
 'proofs/pskernel-min/CompilerPreservationTrust.lean',
 'packages/erasure/src/Ps/Erasure/Expr.lean','packages/backend-ts/src/Ps/BackendTs/Expr.lean',
 'packages/backend-ts/src/Ps/BackendTs/Type.lean','packages/backend-ts/src/Ps/BackendTs/RuntimeSupport.lean'];
const sourceFiles=sources.map(file=>{const bytes=fs.readFileSync(file);return {file,bytes:bytes.length,sha256:sha(bytes)}});
const receipt={schema:'psc1-r5-compiler-preservation-execution/1',head:process.env.GITHUB_SHA,
 platform:process.platform,node:process.version,scalarProbes:400,wholeSourceCalls:wholeCalls,
 literalAbiProbes:3,checkedStructuralIrDeclarations:4,captureProbe:true,combinedCaptureCurryProbe:true,curryProbes:3,operandTraceProbes:traces.length,arityRefusals:oracle.arityRefusals,
 strictIrRefusals:oracle.strictIrRefusals,binaryStageRefusals:oracle.binaryStageRefusals,
 recognizerRefusals:oracle.recognizerRefusals,recognizerCases:oracle.recognizerCases,official:{accepted:official.accepted,version:official.leanVersion,commit:official.leanCommit},
 originalTransportPacket:{bytes:admissions.length,sha256:sha(admissions),officialAccepted:official.accepted,
  ownedRefused:!framed.accepted,code:framed.code,delegated:framed.delegated},
 ownedNewSourcePacket:{accepted:owned.accepted,delegated:owned.delegated,bytes:canonicalAdmissions.length,sha256:sha(canonicalAdmissions),officialAccepted:canonicalOfficial.accepted,
  framing:'Exactly one terminal source-API transport LF removed; all other bytes preserved'},
 policy,originalIrAbi,files,sourceFiles,resourceUsage:process.resourceUsage(),
 boundary:'Actual sub-stage theorems, template correspondence and finite engine/ABI tests. No full compiler or ECMAScript preservation theorem; no production promotion.'};
fs.writeFileSync(path.join(dir,'execution.json'),JSON.stringify(receipt,null,2)+'\n');
console.log('PSC1_R5_COMPILER_PRESERVATION_PASS '+JSON.stringify(receipt));
