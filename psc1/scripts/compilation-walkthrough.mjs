// Actual current-source compilation and a reproducible maintainer exercise; no human claim.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';
import {boundedRun} from '../host-tools/generated-target-tools.mjs';
import {runIndependentChecker} from '../host-tools/compiler-host-protocol.mjs';
const sha=x=>crypto.createHash('sha256').update(x).digest('hex');
const output=path.resolve('dist/maintainability'),work=path.join(output,'walkthrough');
fs.mkdirSync(work,{recursive:true});fs.writeFileSync(path.join(work,'package.json'),'{"type":"module"}\n');
const compiler=path.resolve('.lake/build/bin/psc1'),checker=path.resolve('.lake/build/bin/psc1_independent_checker');
const pins=[compiler,checker].map(file=>({file,sha256:sha(fs.readFileSync(file))}));
const env={...process.env,PSC1_HOST_TOOLS:path.resolve('host-tools/artifacts.mjs'),LEAN_MAIN_USE_THREAD:'0',LEAN_NUM_THREADS:'0',LEAN_STACK_SIZE_KB:'8192'};
function run(command,args){return boundedRun(command,args,{timeoutMs:240000,timeoutPolicy:'standard-240s',env});}
function success(command,args){const r=run(command,args);assert.equal(r.error,null,r.stderr);assert.equal(r.status,0,r.stdout+r.stderr);return r;}
const originals={lean:'def invert (flag : Bool) : Bool := if flag then false else true\n',ps:'def invert(flag : Bool) : Bool := if (flag) { false } else { true }\n'};
const identities={lean:'def invert (flag : Bool) : Bool := flag\n',ps:'def invert(flag : Bool) : Bool := flag\n'};
const records=[],refusals=[];
function verify(source,input,out,kind,stage,expected){
 success(compiler,['build',input,'--target','js','--out',out]);
 const manifestFile=fs.realpathSync(out+'.bundle.json'),generation=path.dirname(manifestFile);
 const manifestBytes=fs.readFileSync(manifestFile),manifest=JSON.parse(manifestBytes);
 assert.equal(manifest.logicalChecker,'lean4:4.35.0');assert.equal(manifest.logicalCheckerCommit,'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
 assert.equal(manifest.assurance,'checked-logical');assert.equal(manifest.target,'js');
 for(const entry of manifest.files)assert.equal(sha(fs.readFileSync(path.join(generation,entry.path))),entry.sha256);
 const info=JSON.parse(fs.readFileSync(path.join(generation,'psc1-input.json')));
 assert.equal(info.behaviorallyVerified,false);assert.deepEqual(info.publicNames,['invert']);
 assert.ok(info.sources.some(row=>row.text===source),'exact captured input text');
 const graph=fs.readFileSync(path.join(generation,'admissions.json'),'utf8');
 const independent=runIndependentChecker(checker,graph);
 assert.equal(independent.leanCommit,manifest.logicalCheckerCommit);
 const artifact=fs.realpathSync(out);
 const code='const api=await import('+JSON.stringify(pathToFileURL(artifact).href)+'); console.log(JSON.stringify({names:Object.keys(api),values:[api.invert(false),api.invert(true)]}));';
 const observed=JSON.parse(success(process.execPath,['--input-type=module','-e',code]).stdout);
 assert.deepEqual(observed.names,['invert']);assert.deepEqual(observed.values,expected);
 const record={kind,stage,sourceSha256:sha(source),sourceClosureSha256:manifest.sourceClosureSha256,admissionsSha256:sha(graph),artifactSha256:sha(fs.readFileSync(artifact)),manifestSha256:sha(manifestBytes),generation,immutableArtifact:artifact,logicalAcceptance:true,strictIr:'required by actual production pipeline',behaviorallyVerified:false,observed};
 records.push(record);return record;
}
let status='running';
try{
 for(const kind of ['lean','ps']){
  const dir=path.join(work,kind);fs.mkdirSync(dir,{recursive:true});
  const input=path.join(dir,'Main.'+kind),out=path.join(dir,'module.mjs');
  fs.writeFileSync(input,originals[kind]);const before=verify(originals[kind],input,out,kind,'invert',[true,false]);
  fs.writeFileSync(input,identities[kind]);verify(identities[kind],input,path.join(dir,'identity.mjs'),kind,'small-source-change',[false,true]);
  fs.writeFileSync(input,kind==='lean'?'def invert (flag : Bool) : Bool := 42\n':'def invert(flag : Bool) : Bool := 42\n');
  const denied=run(compiler,['build',input,'--target','js','--out',out]);
  assert.equal(denied.error,null);assert.notEqual(denied.status,0);
  assert.equal(path.dirname(fs.realpathSync(out+'.bundle.json')),before.generation);
  assert.equal(sha(fs.readFileSync(fs.realpathSync(out))),before.artifactSha256);
  refusals.push({kind,id:'ill-typed-source',priorGenerationPreserved:true,stderr:denied.stderr});
  fs.writeFileSync(input,originals[kind]);
 }
 assert.throws(()=>runIndependentChecker(checker,'{not-canonical-json'));
 const exercise=path.join(work,'RuntimeNeedsMaintainer.lean');
 const prefix='import Ps.BackendWasm.Lower.RuntimeNeeds\n\n';
 fs.writeFileSync(exercise,prefix+'example : psWasmIntrinsicUsesNat PsVerifiedIrIntrinsic.stringLength = true := rfl\nexample : psWasmIntrinsicUsesString PsVerifiedIrIntrinsic.stringLength = true := rfl\n');
 success('lake',['env','lean',exercise]);
 const wrong=path.join(work,'RuntimeNeedsWrong.lean');
 fs.writeFileSync(wrong,prefix+'example : psWasmIntrinsicUsesNat PsVerifiedIrIntrinsic.stringLength = false := rfl\n');
 const rejected=run('lake',['env','lean',wrong]);assert.equal(rejected.error,null);assert.notEqual(rejected.status,0,'a wrong expected dependency must fail');
 for(const pin of pins)assert.equal(sha(fs.readFileSync(pin.file)),pin.sha256);
 status='passed';
 fs.writeFileSync(path.join(output,'exercise.json'),JSON.stringify({schema:'psc1-maintainer-exercise/1',testedCommit:process.env.GITHUB_SHA,status:'automated-rehearsal-passed',actualFreshCheckout:true,referenceRegression:'official Lean accepted',wrongAssertionRejected:true,smallSourceChanges:2,humanTrial:'pending-independent-human-participant',humanQualified:false,AIUsageForRehearsal:'authored by engineering agent; not an unassisted participant'},null,2)+'\n');
}finally{
 const receipt={schema:'psc1-compilation-walkthrough/1',testedCommit:process.env.GITHUB_SHA,branchHead:process.env.PSC1_BRANCH_HEAD,status,pins,records,refusals,compilerRequestSeconds:240,checkerRequestSeconds:120,semanticFuel:'unchanged',freshHumanUsability:'not-tested',formalPreservation:false};
 fs.writeFileSync(path.join(output,'walkthrough.json'),JSON.stringify(receipt,null,2)+'\n');
 const archive=spawnSync('tar',['czf',path.join(output,'walkthrough-evidence.tar.gz'),'-C',output,'walkthrough'],{encoding:'utf8',timeout:240000,maxBuffer:32*1024*1024});
 assert.equal(archive.status,0,archive.stderr);
 console.log('PSC1_COMPILATION_WALKTHROUGH: '+JSON.stringify({status,checkedBuilds:records.length,sourceRefusals:refusals.length,humanTrial:'pending'}));
}
