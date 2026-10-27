// Experimental host coordinator. Native output is data; only this captured
// session invokes the existing independent Lean checker before target use.
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import {createCompilerHostSession,compilerSourceClosureDigest} from '../compiler-host-protocol.mjs';
export const sha256=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');
export const packageVersion='0.1.0-psc1-modular-pilot.0';
export const packageNames=['@proofscript/modular-pilot-runtime','@proofscript/modular-pilot-names','@proofscript/modular-pilot-consumer'];
export const umbrellaName='@proofscript/modular-compiler-pilot';
export function moduleProfile(profile,sources){
  if(profile==='legacy')return{profile,version:packageVersion,packageNames:[...packageNames],
    protocol:'psc1-modular-pilot/1',candidateProtocol:'psc1-modular-pilot-candidate/1',schema:'psc1-modular-installed-cohort/1',maxSources:2};
  if(!['extended','partitioned'].includes(profile))fail('PROFILE');
  const names=['@proofscript/modular-pilot-runtime',...sources.map(source=>{
    if(source.module==='Ps.Foundation.Name')return '@proofscript/modular-pilot-names';
    if(source.module==='Pilot.Consumer')return '@proofscript/modular-pilot-consumer';
    return '@proofscript/modular-pilot-'+source.module.replaceAll('.','-').replaceAll('_','-').toLowerCase();
  })];
  if(names.some(name=>!/^@proofscript\/modular-pilot-[a-z0-9-]{1,114}$/.test(name))||
     new Set(names).size!==names.length)fail('PACKAGE_IDENTITY');
  const n=profile==='partitioned'?3:2;
  return{profile,version:'0.1.0-psc1-modular-pilot.'+(n-1),packageNames:names,
    protocol:'psc1-modular-pilot/'+n,candidateProtocol:'psc1-modular-pilot-candidate/'+n,schema:'psc1-modular-installed-cohort/'+n,maxSources:8};
}
const workspace=fileURLToPath(new URL('../../',import.meta.url));
const fail=code=>{throw Error('PSC1_MODULAR_'+code);};
export function run(executable,args,options={}){
  const result=spawnSync(executable,args,{encoding:'utf8',timeout:240000,maxBuffer:32*1024*1024,...options});
  if(result.error||result.status!==0)fail('PROCESS:'+executable+':'+(result.error?.message||result.stderr||result.stdout));
  return result.stdout;
}
export function compileSources({sources,profile='legacy',producer=path.join(workspace,'.lake/build/bin/psc1_modular_pilot'),
  checker=path.join(workspace,'.lake/build/bin/psc1_independent_checker'),requestId='modular-pilot'}){
  if(!Array.isArray(sources)||sources.length<2||sources.length>(profile==='legacy'?2:8)||sources.some(s=>!s||
    Object.keys(s).sort().join(',')!=='kind,module,text'||!['lean','ps'].includes(s.kind)||
    !/^[A-Za-z][A-Za-z0-9_.]{0,127}$/.test(s.module)||typeof s.text!=='string'||
    Buffer.from(s.text,'utf8').toString('utf8')!==s.text||s.text.startsWith('\uFEFF'))||
    sources.some(s=>s.kind!==sources[0].kind))fail('SOURCE_SCOPE');
  sources=JSON.parse(JSON.stringify(sources));
  let settings=moduleProfile(profile,sources);
  const digest=compilerSourceClosureDigest(sources),grammar=sources[0].kind;
  const request=[settings.protocol,requestId,digest,grammar,'checked',sources.at(-1).module,sources.map(s=>[s.module,s.text])];
  const bytes=Buffer.from(JSON.stringify(request));if(bytes.length>1024*1024)fail('INPUT_BOUND');
  const supervisor=fileURLToPath(new URL('../process/bounded-process.py',import.meta.url));
  const resources=[producer,checker,supervisor,'/usr/bin/prlimit'].map(file=>{
    if(!path.isAbsolute(file)||fs.realpathSync(file)!==file||!fs.lstatSync(file).isFile())fail('TOOL_PATH');
    return{file,sha256:sha256(fs.readFileSync(file))};
  });
  const verify=()=>{for(const pin of resources)if(sha256(fs.readFileSync(pin.file))!==pin.sha256)fail('TOOL_CHANGED');};
  const temporary=fs.mkdtempSync(path.join(os.tmpdir(),'psc1-modular-request-'));
  try{
    const requestFile=path.join(temporary,'request.json');fs.writeFileSync(requestFile,bytes,{flag:'wx',mode:0o600});
    const logs=path.join(temporary,'execution');
    const execution=JSON.parse(run('python3',[supervisor,JSON.stringify({
      command:['/usr/bin/prlimit','--as=4294967296','--stack=8388608','--cpu=240','--',producer,requestFile],
      directory:logs,timeoutMs:240000,maxBuffer:32*1024*1024
    })],{timeout:245000}));
    const stderr=fs.readFileSync(path.join(logs,'tool.stderr.txt'),'utf8');
    if(execution.error||execution.status!==0)fail('CANDIDATE:'+stderr);
    const raw=fs.readFileSync(path.join(logs,'tool.stdout.txt'));
    if(raw.length>32*1024*1024)fail('RESPONSE_BOUND');
    const candidate=JSON.parse(raw);
    for(const[key,value]of Object.entries({protocol:settings.candidateProtocol,requestId,
      sourceClosureDigest:digest,grammar,admission:'not-run',candidateOnly:true,
      leanVersion:'4.35.0',leanCommit:'eb6cafb7290e8bd5f2937522d8d804f58f02bafc',behaviorallyVerified:false}))
      assert.equal(candidate[key],value,'PSC1_MODULAR_CANDIDATE_'+key);
    if(profile==='partitioned'){
      const p=candidate.partition,names=candidate.packages;
      if(!p||!Array.isArray(names)||names.length<1||names.length>9||
        names[0]!=='@proofscript/modular-pilot-runtime'||new Set(names).size!==names.length||
        names.some(name=>!/^@proofscript\/modular-pilot-[a-z0-9-]{1,114}$/.test(name))||
        !Array.isArray(p.groups)||p.groups.length!==names.length||
        !Array.isArray(p.sourceToUnit)||p.sourceToUnit.length!==sources.length+1||
        p.sourceToUnit[0]!==0)fail('PARTITION_LAYOUT');
      assert.deepEqual(p.logicalPackages,settings.packageNames,'PSC1_MODULAR_LOGICAL_PACKAGES');
      const coverage=p.groups.flat();
      if(coverage.length!==sources.length+1||new Set(coverage).size!==coverage.length||
         coverage.some(n=>!Number.isSafeInteger(n)||n<0||n>sources.length)||
         p.groups.some((g,i)=>!Array.isArray(g)||g.length===0||g.some(n=>p.sourceToUnit[n]!==i))||
         p.sourceToUnit.some(n=>!Number.isSafeInteger(n)||n<0||n>=names.length))fail('PARTITION_COVERAGE');
      settings={...settings,packageNames:names,sourceToUnit:p.sourceToUnit,groups:p.groups,
        sourceModules:sources.map(s=>s.module)};
    }
    for(const target of ['js','ts']){
      if(!Array.isArray(candidate[target])||candidate[target].length!==settings.packageNames.length)fail('UNIT_COVERAGE');
      candidate[target].forEach((unit,index)=>{
        if(unit.unit!==index||typeof unit.source!=='string'||!unit.source||
          !Array.isArray(unit.imports)||!Array.isArray(unit.exports))fail('UNIT_SHAPE');
      });
    }
    if(profile!=='legacy'){
      assert.deepEqual(candidate.packages,settings.packageNames,'PSC1_MODULAR_PACKAGE_LAYOUT');
      assert.deepEqual(candidate.sourceModules,sources.map(s=>s.module),'PSC1_MODULAR_SOURCE_LAYOUT');
      if(!candidate.transformOrigins||!Array.isArray(candidate.specializedIr))fail('PROVENANCE');
    }
    for(const graph of [candidate.originalIr,candidate.transformedIr])
      if(!Array.isArray(graph)||graph.length!==5||graph[0]!=='psc1-ir/1')fail('IR_SHAPE');
    verify();assert.equal(sha256(fs.readFileSync(requestFile)),sha256(bytes));
    // Admission is for the one canonical Core graph shared by both emitters.
    // The existing JS request identity is retained; it is not a backend proof.
    const session=createCompilerHostSession({requestId,target:'js',sources,
      canonicalAdmissions:candidate.admissions,checkerExecutable:checker});
    const receipt=session.admit(JSON.stringify(candidate.admissionRequest));
    verify();assert.equal(sha256(fs.readFileSync(requestFile)),sha256(bytes));
    return Object.freeze({candidate,sources,settings,receipt,execution,resources,candidateSha256:sha256(raw),
      originalIrSha256:sha256(JSON.stringify(candidate.originalIr)),
      transformedIrSha256:sha256(JSON.stringify(candidate.transformedIr))});
  }finally{fs.rmSync(temporary,{recursive:true,force:true});}
}
