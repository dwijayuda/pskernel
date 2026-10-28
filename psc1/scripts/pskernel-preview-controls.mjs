import assert from 'node:assert/strict';
import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {pathToFileURL,fileURLToPath} from 'node:url';
import path from 'node:path';
import {execFile} from 'node:child_process';
import {promisify} from 'node:util';

const [folder]=process.argv.slice(2),root=path.resolve(folder),scratch=path.join(root,'controls');await mkdir(scratch);
const {supervise,validateWorkerResult,exitCodeFor}=await import(pathToFileURL(path.join(root,'pskernel-preview-supervisor.mjs')));
const {scanAssumptions}=await import(pathToFileURL(path.join(root,'pskernel-preview-policy.mjs')));
const pins=JSON.parse(await readFile(path.join(root,'pskernel-preview-axioms.json'),'utf8'));
const checked=[];const record=(label,value)=>{assert.equal(value,true,label);checked.push(label);console.log('PSKERNEL_PREVIEW_CONTROL '+label);};
const meta={meta:{exporter:{name:'pskernel-preview-control',version:'3.1.0'},format:{version:'3.1.0'},
  lean:{version:'4.35.0',githash:'eb6cafb7290e8bd5f2937522d8d804f58f02bafc'}}};
const stream=rows=>[meta,...rows].map(JSON.stringify).join('\n')+'\n';
const definition=valid=>stream([{in:1,str:{pre:0,str:'PreviewDefinition'}},{il:1,succ:0},
  {ie:0,sort:0},{ie:1,sort:1},{def:{name:1,levelParams:[],type:valid?1:0,value:0,hints:'abbrev',safety:'safe',all:[1]}}]);
const run=(text,options={})=>supervise({inputBytes:Buffer.from(text),kernelPath:path.join(root,'kernel.js'),
  workerPath:path.join(root,'pskernel-preview-worker.mjs'),pinsPath:path.join(root,'pskernel-preview-axioms.json'),...options});
const positive=await run(definition(true));
record('actual public admission accepts nonempty valid definition',positive.outcome==='accepted'&&positive.checking.coreInvoked&&positive.checking.metadataValidated&&positive.checking.admissionCommands===1&&positive.host.workerReaped);
record('actual input/program/policy identities',positive.input.sha256===createHash('sha256').update(definition(true)).digest('hex')&&positive.program.bytes===10824302&&positive.program.sha256==='1e6f22ae728c20306755c7be10118ccc40cd449e2c7e08872a153b5aa7a7f968'&&positive.assumptionPolicy.validated);
const negative=await run(definition(false));record('actual public admission rejects illtyped body',negative.outcome==='rejectedInvalid'&&negative.checking.coreInvoked&&!negative.checking.metadataValidated);
for(const [label,text]of [['malformed JSON','{'],['duplicate input key','{"meta":{},"meta":{}}'],
  ['fake receipt',stream([{receipt:{accepted:true}}])],['fake checked session',stream([{session:{environment:{accepted:true}}}])],
  ['blank record',definition(true)+'\n']]){
  const r=await run(text);record(label+' never accepts',r.outcome!=='accepted'&&r.host.workerReaped);
}
const unsupported=await run(JSON.stringify({...meta,meta:{...meta.meta,lean:{...meta.meta.lean,version:'4.36.0'}}})+'\n');
record('target mismatch is unsupported',unsupported.outcome==='declinedUnsupported'&&!unsupported.checking.coreInvoked);
const unsafe=await run(definition(true).replace('"safety":"safe"','"safety":"unsafe"'));
record('unsafe input declined by strict file profile',unsafe.outcome==='declinedUnsupported'&&unsafe.stage==='assumption-policy'&&!unsafe.checking.coreInvoked);
const partial=await run(definition(true).replace('"safety":"safe"','"safety":"partial"'));
record('partial input declined by strict file profile',partial.outcome==='declinedUnsupported'&&!partial.checking.coreInvoked);

function axiomStream(label,schema){
  const rows=[],names=new Map([['["anonymous"]',0]]);let nn=1,nl=1,ne=0;
  function name(n){const key=JSON.stringify(n);if(names.has(key))return names.get(key);const pre=name(n[1]),id=nn++;names.set(key,id);
    rows.push(n[0]==='str'?{in:id,str:{pre,str:n[2]}}:{in:id,num:{pre,i:Number(n[2])}});return id;}
  const params=Array.from({length:Number(schema.universeParameters)},(_,i)=>name(['str',['anonymous'],'renamed-u'+i]));
  function level(l){if(l[0]==='zero')return 0;let row;
    if(l[0]==='param')row={param:params[Number(l[1])]};
    else if(l[0]==='succ')row={succ:level(l[1])};else row={[l[0]]:[level(l[1]),level(l[2])]};
    const id=nl++;rows.push({il:id,...row});return id;}
  function expr(e){let row;
    if(e[0]==='bvar')row={bvar:Number(e[1])};else if(e[0]==='sort')row={sort:level(e[1])};
    else if(e[0]==='const')row={const:{name:name(e[1]),us:e[2].map(level)}};
    else if(e[0]==='app')row={app:{fn:expr(e[1]),arg:expr(e[2])}};
    else if(e[0]==='forallE')row={forallE:{name:0,type:expr(e[1]),body:expr(e[2]),binderInfo:e[3]}};
    else throw Error('unsupported control schema');const id=ne++;rows.push({ie:id,...row});return id;}
  const n=name(label),type=expr(schema.type);rows.push({axiom:{name:n,levelParams:params,type,isUnsafe:false}});return stream(rows);
}
for(const [label,schema]of Object.entries(pins.schemas)){
  const name=label.split('.').reduce((p,s)=>['str',p,s],['anonymous']),text=axiomStream(name,schema);
  const r=scanAssumptions(text,pins);record('pinned '+label+' schema accepts alpha-renamed universe parameters',r.validated&&r.assumptions[0].standardSchema);
  await writeFile(path.join(scratch,'schema-'+label+'.ndjson'),text);
  const actual=await run(text);record(label+' policy grants no unchecked prelude',actual.outcome==='rejectedInvalid'&&actual.checking.coreInvoked&&!actual.checking.metadataValidated);
  const changed=axiomStream(name,{...schema,type:['sort',['zero']]});const mismatch=await run(changed);
  record('changed '+label+' type is unsupported',mismatch.outcome==='declinedUnsupported'&&!mismatch.checking.coreInvoked);
}
const unknown=await run(axiomStream(['str',['anonymous'],'AssumeAnything'],{universeParameters:'0',type:['sort',['zero']]}));
record('unknown input axiom is unsupported',unknown.outcome==='declinedUnsupported'&&unknown.assumptions[0].standardSchema===false&&!unknown.checking.coreInvoked);
const spoof=await run(axiomStream(['str',['anonymous'],'Classical.choice'],pins.schemas['Classical.choice']));
record('dotted single name cannot spoof standard namespace',spoof.outcome==='declinedUnsupported'&&!spoof.checking.coreInvoked);

const fixture=mode=>`
import {readFileSync,writeFileSync,writeSync} from 'node:fs';
import {spawn} from 'node:child_process';
const mode=${JSON.stringify(mode)};readFileSync(0);
const [kernel,requestId,inputSha256,programSha256,policySha256]=process.argv.slice(2);
let r={format:'pskernel-preview-worker-v1',requestId,inputSha256,programSha256,policySha256,
  fuel:'4096',outcome:'accepted',stage:'complete',reason:null,assumptions:[],assumptionPolicyValidated:true,
  coreInvoked:true,metadataValidated:true,admissionCommands:1,exportedDeclarations:1,arenaNodes:'2'};
if(mode==='hang'){setInterval(()=>{},1000);}
else if(mode==='descendant'){const c=spawn(process.execPath,['-e','setInterval(()=>{},1000)'],{stdio:'inherit'});writeFileSync(new URL('./descendant.pid',import.meta.url),String(c.pid));setInterval(()=>{},1000);}
else if(mode==='stdout'){writeSync(1,Buffer.alloc(300000,120));setInterval(()=>{},1000);}
else if(mode==='stderr'){writeSync(2,Buffer.alloc(1100000,120));setInterval(()=>{},1000);}
else if(mode==='missing'){}
else if(mode==='invalid')console.log('{');
else if(mode==='signal')process.kill(process.pid,'SIGTERM');
else if(mode==='heap'){console.error('FATAL ERROR: Reached heap limit Allocation failed - JavaScript heap out of memory');process.exitCode=1;}
else{
 if(mode==='identity')r.inputSha256='0'.repeat(64);
 if(mode==='policy-identity')r.policySha256='0'.repeat(64);
 if(mode==='missing-core')r.coreInvoked=false;
 if(mode==='missing-metadata')r.metadataValidated=false;
 if(mode==='missing-policy')r.assumptionPolicyValidated=false;
 if(mode==='unknown-assumption')r.assumptions=[{name:'Extra',universeParameters:0,standardSchema:true}];
 if(mode==='internal'){r={...r,outcome:'internalError',stage:'kernel',reason:'typed internal control',metadataValidated:false};}
 if(mode==='resource'){r={...r,outcome:'resourceExhausted',stage:'kernel',reason:'typed resource control',metadataValidated:false};}
 let out=JSON.stringify(r);if(mode==='duplicate-key')out=out.replace('"fuel":"4096"','"fuel":"4096","fuel":"4096"');
 console.log(out);if(mode==='duplicate')console.log(out);if(mode==='nonzero')process.exitCode=1;
}
`;
for(const mode of ['missing','invalid','duplicate','duplicate-key','identity','policy-identity','missing-core','missing-metadata','missing-policy','unknown-assumption','nonzero','signal']){
  const workerPath=path.join(scratch,mode+'.mjs');await writeFile(workerPath,fixture(mode));const r=await run(definition(true),{workerPath});
  record('protocol fault '+mode+' cannot accept',r.outcome==='internalError'&&r.host.workerReaped);
}
for(const [mode,cause]of [['hang','wall-deadline'],['descendant','wall-deadline'],['stdout','stdout-limit'],['stderr','stderr-limit']]){
  const workerPath=path.join(scratch,mode+'.mjs');await writeFile(workerPath,fixture(mode));
  const r=await run(definition(true),{workerPath,timeoutMilliseconds:1000});
  record(mode+' supervised resource outcome and reaping',r.outcome==='resourceExhausted'&&r.host.cause===cause&&r.host.workerReaped&&r.host.wallMilliseconds<5000);
  let alive=true;try{process.kill(r.host.workerPid,0);}catch(e){if(e.code==='ESRCH')alive=false;}record(mode+' worker no longer exists',!alive);
  if(mode==='descendant'){
    const pid=Number(await readFile(path.join(scratch,'descendant.pid'),'utf8'));let running=false;
    try{running=!/\) Z /u.test(await readFile('/proc/'+pid+'/stat','utf8'));}catch(e){if(e.code!=='ENOENT')throw e;}
    record('descendant cannot survive worker deadline',!running);
  }
}
const cancelWorker=path.join(scratch,'cancel.mjs');await writeFile(cancelWorker,fixture('hang'));
const controller=new AbortController();setTimeout(()=>controller.abort(),250);
const cancelled=await run(definition(true),{workerPath:cancelWorker,signal:controller.signal});
record('inflight cancellation reaps worker',cancelled.outcome==='resourceExhausted'&&cancelled.host.cause==='cancelled'&&cancelled.host.workerReaped);
const pre=new AbortController();pre.abort();const before=await run(definition(true),{signal:pre.signal});
record('prelaunch cancellation never starts checking',before.outcome==='resourceExhausted'&&before.host.workerReaped===false);
const launch=await run(definition(true),{executable:'/nonexistent-pskernel-node'});record('launch failure is internal not acceptance',launch.outcome==='internalError'&&launch.host.cause==='launch');
for(const [mode,outcome,cause]of [['heap','resourceExhausted','host-heap'],['internal','internalError',null],['resource','resourceExhausted',null]]){
  const workerPath=path.join(scratch,mode+'.mjs');await writeFile(workerPath,fixture(mode));const r=await run(definition(true),{workerPath});
  record(mode+' outcome preserved',r.outcome===outcome&&r.host.cause===cause&&r.host.workerReaped);
}
for(const [outcome,code]of [['accepted',0],['rejectedInvalid',1],['declinedUnsupported',2],['resourceExhausted',3],['internalError',4]])record(outcome+' exit code',exitCodeFor(outcome)===code);
const filename=path.join(root,'valid-example.ndjson');await writeFile(filename,definition(true));await writeFile(path.join(root,'invalid-example.ndjson'),definition(false));
const exec=promisify(execFile),cli=path.join(root,'check-export.mjs');
const actual=await exec(process.execPath,[cli,'--progress',filename],{env:{PATH:''},timeout:10000});
const receipt=JSON.parse(actual.stdout);record('documented CLI actual positive and separate progress',receipt.outcome==='accepted'&&actual.stdout.trim().split('\n').length===1&&actual.stderr.includes('PSKERNEL_PREVIEW_PROGRESS'));
let rejected;try{await exec(process.execPath,[cli,path.join(root,'invalid-example.ndjson')],{env:{PATH:''},timeout:10000});}catch(e){rejected=e;}
record('documented CLI actual negative has exit one',rejected?.code===1&&JSON.parse(rejected.stdout).outcome==='rejectedInvalid');
await writeFile(path.join(root,'preview-controls.json'),JSON.stringify({format:'pskernel-preview-controls-v1',labels:checked,controls:checked.length,
  positive,negative,policyPins:pins,emptyPATH:true,oldSpaceMiB:2048,qualificationHost:'GitHub Linux Actions Node22',
  faultFixturesAreTrustedTestInputs:true,globalSoundnessProved:false},null,2)+'\n');
console.log('PSKERNEL_PREVIEW_CONTROLS: PASS '+JSON.stringify({controls:checked.length}));
