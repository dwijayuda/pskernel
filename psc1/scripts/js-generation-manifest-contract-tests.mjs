// Constructed identity data tests only; these objects grant no publication.
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import { assertJsGeneration } from '../host-tools/js-generation-manifest.mjs';
const sha=value=>crypto.createHash('sha256').update(JSON.stringify(value)).digest('hex');
const legacy=['lean-modules','ps-integer-unicode','lean-handler-pattern','lean-ordinary-loop',
 'wrong-body','missing-import','checked-partial','verified'];
const current=[...legacy,'ps-list-literal','malformed-list'];
function fixture(version,ids){
 const observations=ids.map(id=>({id})),sourceInventory=[],hostModuleInventory=[];
 const expected=Object.fromEntries(['sourceClosureDigest','serviceSha256','admissionsSha256',
  'originalIrSha256','specializedIrSha256','checkerSha256','runnerSha256','nodeSha256',
  'nativeSeedSha256'].map(key=>[key,'a'.repeat(64)]));
 Object.assign(expected,{generationSchema:version,sourceInventorySha256:sha(sourceInventory),
  corpusObservationsSha256:sha(observations),hostControllerSha256:sha(hostModuleInventory)});
 const manifest={...expected,schema:version,generation:1,
  logicalCheckerCommit:'eb6cafb7290e8bd5f2937522d8d804f58f02bafc',
  target:'js',grammar:'lean',assurance:'ordinary-checked',behaviorallyVerified:false,
  sourceInventory,hostModuleInventory,observations,publicNames:['psCompilerJsServiceCandidate'],
  producer:{kind:'native-stage0',sha256:expected.nativeSeedSha256}};
 return {manifest,expected};
}
const v1='psc1-js-generation/4.35.0-v1',v2='psc1-js-generation/4.35.0-v2';
for(const [version,ids]of [[v1,legacy],[v2,current]]){
 const {manifest,expected}=fixture(version,ids);assert.equal(assertJsGeneration(manifest,expected),true);
 for(const changed of [ids.slice(1),[...ids,ids[0]],[...ids.slice(0,-1),'unknown-case']]){
  const invalid=fixture(version,changed);
  assert.throws(()=>assertJsGeneration(invalid.manifest,invalid.expected),/CORPUS_CHANGED/);
 }
 assert.throws(()=>assertJsGeneration({...manifest,behaviorallyVerified:true},expected),/SCHEMA/);
}
const old=fixture(v1,legacy),now=fixture(v2,current);
assert.throws(()=>assertJsGeneration(old.manifest,{...old.expected,generationSchema:v2}),/SCHEMA/);
assert.throws(()=>assertJsGeneration(now.manifest,{...now.expected,generationSchema:v1}),/SCHEMA/);
const mixed=fixture(v1,current);
assert.throws(()=>assertJsGeneration(mixed.manifest,mixed.expected),/CORPUS_CHANGED/);
const {generationSchema,...oldCaller}=old.expected;
assert.equal(assertJsGeneration(old.manifest,oldCaller),true,'preserve historical caller contract');
for(const invalid of ['unknown','',null,false,1])
 assert.throws(()=>assertJsGeneration(now.manifest,{...now.expected,generationSchema:invalid}),/SCHEMA/);
console.log('PSC1_GENERATION_MANIFEST_CONTRACT: exact legacy/current cases, no missing/duplicate/unknown cases or downgrade');
