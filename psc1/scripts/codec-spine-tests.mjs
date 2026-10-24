// Real checked codec source workload; no handwritten replacement compiler.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {readOwnedCompilerSources} from '../host-tools/compiler-source-inputs.mjs';
import {createCompilerHostSession,compilerSourceClosureDigest} from '../host-tools/compiler-host-protocol.mjs';
import {sha,buildTarget,observeArtifact,runTool} from '../host-tools/generated-target-tools.mjs';
const directory=path.resolve('dist/codec-spine');fs.mkdirSync(directory,{recursive:true});
const base=readOwnedCompilerSources('Ps.Bridge.CheckedAdmissions');
const helper=`import Ps.Bridge.CheckedAdmissions
def codecMakeSpine (depth : Nat) (mode : Nat) (value : PsExpr) : PsExpr :=
  match depth with
  | Nat.zero => value
  | Nat.succ rest =>
      let next : PsExpr :=
        if Nat.beq mode 0 then PsExpr.app value (PsExpr.bvar 0)
        else if Nat.beq mode 1 then PsExpr.lam PsName.anonymous (PsExpr.bvar 1) value PsBinderInfo.explicit
        else if Nat.beq mode 2 then PsExpr.forallE PsName.anonymous (PsExpr.bvar 1) value PsBinderInfo.implicit
        else if Nat.beq mode 3 then PsExpr.letE PsName.anonymous (PsExpr.bvar 1) (PsExpr.lit (PsLiteral.natural 7)) value
        else PsExpr.proj PsName.anonymous 0 value;
      codecMakeSpine rest mode next
`;
const probe=`import CodecProbeInternal
def codecProbe (depth : Nat) (mode : Nat) : String :=
  match psEncodeCodecExpr (codecMakeSpine depth mode (PsExpr.lit (PsLiteral.string "λ🙂"))) with
  | Except.error _ => "refused"
  | Except.ok value => value
`;
const seed=path.resolve('.lake/build/bin/psc1_unified_service_seed');
const checker=path.resolve('.lake/build/bin/psc1_independent_checker');
const records=[];
for(const kind of ['legacy','current']){
 const sources=base.map(row=>({module:row.module,kind:'lean',text:row.text}));
 if(kind==='legacy'){
  const row=sources.find(row=>row.module==='Ps.Bridge.CheckedAdmissions');
  const frozen=fs.readFileSync('test/CodecSpineReference.lean','utf8');
  const original=frozen.slice(frozen.indexOf('def psEncodeCodecExpr'),frozen.indexOf('\nend PsCodecSpineReference'));
  const start=row.text.indexOf('-- Explicit return frames preserve the original opaque append tree exactly.');
  const end=row.text.indexOf('\ndef psEncodeCodecNames',start);
  assert.ok(start>0&&end>start);row.text=row.text.slice(0,start)+original+row.text.slice(end);
 }
 sources.push({module:'CodecProbeInternal',kind:'lean',text:helper},{module:'CodecProbe',kind:'lean',text:probe});
 const digest=compilerSourceClosureDigest(sources),id='codec-spine-'+kind;
 const wire=['psc1-unified-compiler-service/2','rust',['psc1-compiler-service/1',id,digest,'lean','ordinary-checked','CodecProbe',sources.map(row=>[row.module,row.text])]];
 const request=path.join(directory,kind+'.request.json'),output=path.join(directory,kind+'.candidate.json');
 fs.writeFileSync(request,JSON.stringify(wire));runTool(seed,['rust',request,output],{logDirectory:path.join(directory,kind+'-seed')});
 const candidate=JSON.parse(fs.readFileSync(output));assert.equal(candidate.status,'candidate',JSON.stringify(candidate));
 assert.equal(candidate.sourceClosureDigest,digest);assert.deepEqual(candidate.publicNames,['codecProbe']);
 const session=createCompilerHostSession({requestId:id,target:'rust',sources,canonicalAdmissions:candidate.admissionRequest.admissions,checkerExecutable:checker});
 const admitted=session.admit(JSON.stringify(candidate.admissionRequest));assert.equal(admitted.accepted,true);
 const consumer=`let mut observations=Vec::<String>::new();
for mode in 0u32..5 { for depth in [0u32,1,7,32] {
 observations.push(codecProbe(PsNat::from(depth),PsNat::from(mode)));
}}
println!("{:?}",observations);
`;
 const artifact=buildTarget({target:'rust',source:candidate.source,directory:path.join(directory,kind),consumer,publicNames:['codecProbe']});
 const observed=observeArtifact(artifact);
 records.push({kind,closure:digest,requestSha256:sha(fs.readFileSync(request)),candidateSha256:sha(fs.readFileSync(output)),sourceSha256:sha(candidate.source),admissionsSha256:admitted.admissionsDigest,artifactSha256:artifact.sha256,event:observed.event,observations:observed.observation});
 if(kind==='current'){
  const deep=`let lengths:Vec<String>=(0u32..5).map(|mode| codecProbe(PsNat::from(10000u32),PsNat::from(mode)).len().to_string()).collect();
println!("{:?}",lengths);
`;
  const scale=buildTarget({target:'rust',source:candidate.source,directory:path.join(directory,'scale'),consumer:deep,publicNames:['codecProbe']});
  const result=observeArtifact(scale);assert.equal(result.observation.length,5);assert.ok(result.observation.every(n=>Number(n)>200000));
  records.push({kind:'deep-10000-five-spines',artifactSha256:scale.sha256,event:result.event,byteLengths:result.observation});
 }
}
assert.deepEqual(records[1].observations,records[0].observations);
const result={schema:'psc1-codec-spine-regression/1',testedCommit:process.env.GITHUB_SHA,checkerCommit:'eb6cafb7290e8bd5f2937522d8d804f58f02bafc',passed:true,defaultStack:true,newFuelLimit:false,records};
fs.writeFileSync(path.join(directory,'qualification.json'),JSON.stringify(result,null,2)+'\n');
console.log('PSC1_CODEC_SPINE: '+JSON.stringify(result));
