import assert from 'node:assert/strict';import fs from 'node:fs';import path from 'node:path';
import {execFileSync} from 'node:child_process';
import {sha,verifyArtifact} from '../../psc1/host-tools/generated-target-tools.mjs';
const target=process.argv[2],request=JSON.parse(fs.readFileSync('../.github/diagnostics/psc1-direct-g1-rebuild.json'));
assert.equal(request.schema,'psc1-direct-independent-g1-rebuild/1');
const expected=request.targets.find(r=>r.target===target);assert.ok(expected);
function walk(root){return fs.readdirSync(root,{withFileTypes:true}).flatMap(e=>{const f=path.join(root,e.name);assert.equal(e.isSymbolicLink(),false);return e.isDirectory()?walk(f):[f];});}
const reports=walk('../baseline/'+target).filter(f=>path.basename(f)==='qualification.json');assert.equal(reports.length,1);
const baseline=JSON.parse(fs.readFileSync(reports[0])),baseRoot=path.dirname(reports[0]);
assert.equal(baseline.testedCommit,request.qualifiedCommit);assert.equal(baseline.target,target);
assert.equal(baseline.status,'passed');assert.equal(baseline.correctnessQualification,'qualified');
assert.deepEqual(baseline.generations.map(g=>g.generation),[1,2,3]);
assert.equal(baseline.sourceClosureDigest,expected.sourceClosureDigest);
const output=path.resolve('dist/generated-'+target+'-compiler');
const rebuilt=JSON.parse(fs.readFileSync(path.join(output,'qualification.json')));
assert.equal(rebuilt.testedCommit,process.env.GITHUB_SHA);assert.equal(rebuilt.target,target);
assert.equal(rebuilt.status,'passed');assert.equal(rebuilt.correctnessQualification,'G1-only');
assert.deepEqual(rebuilt.generations.map(g=>g.generation),[1]);
assert.equal(rebuilt.sourceClosureDigest,expected.sourceClosureDigest);
assert.deepEqual(rebuilt.sourceInventory,baseline.sourceInventory,'owned source closure differs');
assert.equal(fs.existsSync('.lake/build/bin/psc1_target_service_seed'),false,'native compiler must be disabled after one seed');
const current=rebuilt.generations[0],codeFiles=target==='js'?['module.js']:['module.wasm.hex','module.wasm'];
const currentArtifact=path.join(output,'G1-service/artifact.json');
verifyArtifact(currentArtifact,current.artifactSha256);
const matches=[];
for(const generation of baseline.generations){
 assert.equal(generation.logicalAdmission,'accepted');assert.equal(generation.observations.length,10);
 assert.equal(current.logicalAdmission,'accepted');assert.equal(current.observations.length,10);
 for(const key of ['sourceClosureDigest','sourceSha256','admissionsSha256','originalIrSha256','specializedIrSha256'])
   assert.equal(current[key],generation[key],'clean rebuild mismatch '+key+' G'+generation.generation);
 assert.deepEqual(current.observations,generation.observations);
 const original=path.join(baseRoot,'G'+generation.generation+'-service');
 verifyArtifact(path.join(original,'artifact.json'),generation.artifactSha256);
 const files=codeFiles.map(file=>{
  const actual=sha(fs.readFileSync(path.join(output,'G1-service',file)));
  assert.equal(actual,sha(fs.readFileSync(path.join(original,file))),file+' bytes differ');
  return {file,sha256:actual};
 });
 matches.push({generation:generation.generation,files,independentAdmission:'accepted',observations:10});
}
const receipt={schema:request.schema,target,testedControlCommit:process.env.GITHUB_SHA,
 checkedOutCommit:execFileSync('git',['rev-parse','HEAD'],{encoding:'utf8'}).trim(),
 qualifiedCommit:request.qualifiedCommit,qualifiedRunId:request.qualifiedRunId,
 compilerSourceClosureDigest:expected.sourceClosureDigest,nativeLakeCacheRestored:false,
 nativeSeedSha256:rebuilt.nativeSeedSha256,independentCheckerSha256:rebuilt.tools.find(t=>t.file.endsWith('/psc1_independent_checker')).sha256,
 sourceInventoryEqual:true,freshG1:'passed-independent-admission-strict-IR-ten-cases',matches,
 qualificationScope:'Independent clean G1 source/executable reproduction of all three previously qualified generations; not a second G2/G3 execution.',
 fullIndependentG1G2G3Replay:'not-run',performance240s:'not-qualified-by-this-audit'};
const out='dist/direct-clean-g1/'+target;fs.mkdirSync(out,{recursive:true});
fs.writeFileSync(path.join(out,'receipt.json'),JSON.stringify(receipt,null,2)+'\n');
console.log('PSC1_DIRECT_INDEPENDENT_G1_REBUILD: '+JSON.stringify(receipt));
