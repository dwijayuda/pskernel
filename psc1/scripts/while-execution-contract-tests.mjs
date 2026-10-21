import assert from 'node:assert/strict';
import {checkWhileExecution as check,whileChecks} from './check-while-execution.mjs';
const targets=['js','ts','rust','wasm-core','wasm-component','python','php'];
const commit='a'.repeat(40),head='b'.repeat(40),digest='c'.repeat(64);
const checkerCommit='eb6cafb7290e8bd5f2937522d8d804f58f02bafc';
const pairs=['lean','ps'].flatMap(syntax=>targets.map(target=>({syntax,target})));
const identity={passed:true,checkerCommit,admission:'independent-official-Lean',
 strictIr:'required-by-production-publication',
 ...Object.fromEntries(['sourceSha256','sourceClosureSha256','kernelAdmissionSha256','artifactSha256','manifestSha256'].map(k=>[k,digest]))};
const refusalNames=['default-refuses-unrestricted-while','verified-refuses-unrestricted-while',
 'total-owner','nested-while-body','nested-for-body','function-valued-result','generic-result','CompilerM-body'];
const data={schema:'psc1-ordinary-while-conformance/1',commit,branchHeadCommit:head,
 assurance:'ordinary-checked',behaviorallyVerified:false,nativeLean:{version:'4.35.0',commit:checkerCommit},
 oracleSha256:digest,failures:[],targetCount:7,sourceSyntaxes:['lean','ps'],loopChecks:whileChecks,longLoopIterations:100000,
 oracleFields:['whileCaptureFalse','whileCaptureTrue','whileCountFalse','whileCountTrue',
 'whileEarlyFalse','whileEarlyTrue','whileExceptFalseTag','whileExceptFalseValue','whileExceptTrueTag','whileExceptTrueValue',
 'whileFalseFalse','whileFalseTrue','whileForFalse','whileForTrue','whileSelfFalse','whileSelfTrue','whileSequentialFalse','whileSequentialTrue'],
 records:pairs.map(pair=>{const names=pair.target==='wasm-component'?['semantic']:[...whileChecks,'semantic'];
  return {...identity,...pair,assurance:'ordinary-checked',behaviorallyVerified:false,
   checks:names.map(n=>[n,true,true]),publicNames:names,partialDeclarations:['privateLoop']};}),
 divergence:pairs.map(p=>({...identity,...p,externalTimeoutMs:2000,exitCode:124,
  earlyReturnPreflight:true,unusedNonvalueCallEvaluated:true,publicNames:['spin']})),
 patternStrictness:pairs.map(p=>({...identity,...p,externalTimeoutMs:2000,exitCode:124,
  earlyReturnPreflight:true,unusedPatternRhsEvaluated:true,publicNames:['spin']})),
 rejections:['lean','ps'].flatMap(syntax=>refusalNames.map(name=>({syntax,name,passed:true,
  diagnostic:name==='default-refuses-unrestricted-while'?'PSC1_PREPARATION_FAILED':
   name==='verified-refuses-unrestricted-while'?'PSC1_VERIFIED_EXECUTION_UNAVAILABLE':
   name==='total-owner'?'unrestricted while requires an explicit partial declaration':
   'selected while requires Id or Except'})))};
assert.equal(check(data,{commit,head,checkerCommit}).consumers,14);
for(const mutate of [
 d=>d.commit=head,d=>d.branchHeadCommit=commit,d=>d.nativeLean.commit=head,
 d=>d.records.pop(),d=>d.records[1]=structuredClone(d.records[0]),
 d=>d.records[0].checks[0][1]=false,d=>d.records[0].checks.pop(),
 d=>d.records[0].publicNames.push('privateHelper'),d=>d.records[0].sourceSha256='',
 d=>d.records[0].kernelAdmissionSha256='',d=>d.records[0].strictIr='skipped',
 d=>d.divergence.pop(),d=>d.divergence[0].exitCode=0,d=>d.divergence[0].externalTimeoutMs=1000,
 d=>d.divergence[0].earlyReturnPreflight=false,d=>d.divergence[0].unusedNonvalueCallEvaluated=false,
 d=>d.patternStrictness[0].unusedPatternRhsEvaluated=false,d=>d.patternStrictness[1]=structuredClone(d.patternStrictness[0]),
 d=>d.rejections.pop(),d=>d.rejections[0].diagnostic='',d=>d.failures.push({error:'failed'}),
 d=>d.longLoopIterations=100,d=>d.behaviorallyVerified=true
]){const bad=structuredClone(data);mutate(bad);assert.throws(()=>check(bad,{commit,head,checkerCommit}));}
const minimum=structuredClone(data);minimum.targetCount=1;
for(const key of ['records','divergence','patternStrictness'])minimum[key]=minimum[key].filter(r=>r.target==='python');
assert.equal(check(minimum,{commit,head,checkerCommit,targets:['python']}).consumers,2);
assert.throws(()=>check(minimum,{commit,head,checkerCommit}));
console.log('PSC1_WHILE_EXECUTION_CONTRACT: PASS exact identity, complete unique matrices, source/kernel hashes, negative profiles and genuine external deadlines');
