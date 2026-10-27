// Genuine native PSC1 frontend/IR/backend candidate and independent Lean admission.
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {compilerSourceClosureDigest,createCompilerHostSession} from '../../host-tools/compiler-host-protocol.mjs';
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const producer=path.resolve('.lake/build/bin/psc1_modular_pilot');
const checker=path.resolve('.lake/build/bin/psc1_independent_checker');
const pins=[producer,checker].map(file=>({file,sha256:sha(fs.readFileSync(file))}));
const directory=fs.mkdtempSync(path.join(os.tmpdir(),'psc1-modular-native-'));
try{
  const sources=[
    {module:'Ps.Foundation.Name',kind:'lean',text:fs.readFileSync('packages/foundation/src/Ps/Foundation/Name.lean','utf8')},
    {module:'Pilot.Consumer',kind:'lean',text:fs.readFileSync('test/modular/Consumer.lean','utf8')}
  ];
  const digest=compilerSourceClosureDigest(sources),requestId='modular-native-probe';
  const request=['psc1-modular-pilot/1',requestId,digest,'lean','checked','Pilot.Consumer',sources.map(s=>[s.module,s.text])];
  const file=path.join(directory,'request.json');fs.writeFileSync(file,JSON.stringify(request),{flag:'wx',mode:0o600});
  const logs=path.join(directory,'process');
  const execution=spawnSync('python3',['host-tools/process/bounded-process.py',JSON.stringify({
    command:['prlimit','--as=4294967296','--stack=8388608','--cpu=240','--',producer,file],
    directory:logs,timeoutMs:240000,maxBuffer:32*1024*1024
  })],{encoding:'utf8',timeout:245000,maxBuffer:1024*1024});
  assert.equal(execution.error,undefined);assert.equal(execution.status,0,execution.stdout+execution.stderr);
  const report=JSON.parse(execution.stdout),stderr=fs.readFileSync(path.join(logs,'tool.stderr.txt'),'utf8');
  assert.equal(report.error,null,stderr);assert.equal(report.status,0,stderr);
  const text=fs.readFileSync(path.join(logs,'tool.stdout.txt'),'utf8'),candidate=JSON.parse(text);
  assert.equal(candidate.protocol,'psc1-modular-pilot-candidate/1');assert.equal(candidate.admission,'not-run');
  assert.equal(candidate.candidateOnly,true);assert.equal(candidate.requestId,requestId);
  assert.equal(candidate.sourceClosureDigest,digest);
  const session=createCompilerHostSession({requestId,target:'js',sources,canonicalAdmissions:candidate.admissions,checkerExecutable:checker});
  const receipt=session.admit(JSON.stringify(candidate.admissionRequest));assert.equal(receipt.accepted,true);
  for(const pin of pins)assert.equal(sha(fs.readFileSync(pin.file)),pin.sha256);
  fs.mkdirSync('dist/modular',{recursive:true});
  fs.writeFileSync('dist/modular/native-candidate.json',text);
  fs.writeFileSync('dist/modular/native-receipt.json',JSON.stringify({testedCommit:process.env.GITHUB_SHA,pins,report,receipt},null,2)+'\n');
  console.log('PSC1_MODULAR_NATIVE_PROBE '+JSON.stringify({status:'passed',original:candidate.originalIr[4].length,
    transformed:candidate.transformedIr[4].length,units:candidate.units,js:candidate.js.map(a=>({unit:a.unit,exports:a.exports})),
    ts:candidate.ts.map(a=>({unit:a.unit,exports:a.exports})),report,receipt}));
}finally{fs.rmSync(directory,{recursive:true,force:true});}
