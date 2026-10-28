// Cross-environment index. Each child receipt already validates actual isolated execution.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
const root=path.resolve(process.argv[2]??'dist/independent-environments');
const sha=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');
const expected=[
 {id:'ubuntu-24.04-x64',platform:'linux-x64'},
 {id:'ubuntu-22.04-x64',platform:'linux-x64'},
 {id:'ubuntu-24.04-arm64',platform:'linux-arm64'},
];
const prefix='psc1-independent-qualified-',suffix='-'+process.env.GITHUB_RUN_ID+'-'+process.env.GITHUB_SHA;
const names=fs.readdirSync(root).sort();
assert.deepEqual(names,expected.map(row=>prefix+row.id+suffix).sort(),'exact environment artifact directories required');
const rows=[],receipts=[];
for(const environment of expected){
 const name=prefix+environment.id+suffix,directory=path.join(root,name);
 const bytes=fs.readFileSync(path.join(directory,'summary.json')),receipt=JSON.parse(bytes);
 assert.equal(receipt.schema,'psc1-independent-development-evidence/2');
 assert.equal(receipt.status,'qualified-linux-independent-compiler-development');
 assert.equal(receipt.testedCommit,process.env.GITHUB_SHA);assert.equal(receipt.runId,process.env.GITHUB_RUN_ID);
 assert.equal(receipt.environmentId,environment.id);assert.equal(receipt.platform,environment.platform);
 const archiveName='psc1-independent-'+environment.platform+'.tar.gz';
 assert.equal(receipt.bootstrap.tarball,archiveName);
 const archive=fs.readFileSync(path.join(directory,archiveName));
 assert.equal(archive.length,receipt.bootstrap.bytes);assert.equal(sha(archive),receipt.bootstrap.sha256);
 assert.equal(fs.readFileSync(path.join(directory,'SHA256SUMS'),'utf8'),
  sha(archive)+'  '+archiveName+'\n'+sha(bytes)+'  summary.json\n');
 assert.equal(receipt.assurances.independentLogicalAdmissionEveryBuild,true);
 assert.equal(receipt.assurances.modifiedBehaviorObservedAfterSelfRebuild,true);
 assert.equal(receipt.assurances.sameSourceFixedPoints,true);
 assert.equal(receipt.assurances.changedSourceModules,3);
 assert.equal(receipt.assurances.frontendCompilerObservationsPerGeneration,6);
 assert.equal(receipt.assurances.relocatedCheckedPublication,true);
 assert.equal(receipt.assurances.readOnlyOutputParentRefused,true);
 assert.deepEqual(Object.keys(receipt.phases).sort(),['baseline','changed','smoke']);
 for(const phase of Object.values(receipt.phases))assert.equal(phase.status,'passed');
 rows.push({environmentId:environment.id,platform:environment.platform,artifactName:name,
  summarySha256:sha(bytes),archive:{name:archiveName,bytes:archive.length,sha256:sha(archive)},
  toolchainSha256:receipt.bootstrap.toolchainSha256,
  privateRuntimeSha256:receipt.bootstrap.privateRuntimeSha256,checkerSha256:receipt.bootstrap.checkerSha256,
  environment:receipt.bootstrap.environment,phases:receipt.phases,
  generations:receipt.generations});
 receipts.push(receipt);
}
const first=receipts[0];
for(const receipt of receipts.slice(1)){
 assert.deepEqual(receipt.authoritativeSource,first.authoritativeSource,'canonical input bytes must agree across environments');
 assert.deepEqual(receipt.changedSource,first.changedSource,'changed workspace bytes must agree across environments');
 for(let index=0;index<first.generations.length;index++){
  assert.equal(receipt.generations[index].label,first.generations[index].label);
  assert.deepEqual(receipt.generations[index].identities,first.generations[index].identities,
   'actual compiler/admission/IR output differs across qualified environments');
 }
}
const result={schema:'psc1-independent-environments-qualification/1',status:'passed',
 testedCommit:process.env.GITHUB_SHA,runId:process.env.GITHUB_RUN_ID,
 environments:rows,commonSource:first.authoritativeSource,
 commonGenerations:first.generations.map(row=>({label:row.label,identities:row.identities})),
 originalAndTransformedIrAcrossArchitectures:true,freshAdmissionEveryBuild:true,
 actualPublicationChecksPerEnvironment:true,formalCompilerPreservation:false,
 operatingSystemsBeyondListedEnvironmentsQualified:false};
fs.writeFileSync(path.join(root,'environments.json'),JSON.stringify(result,null,2)+'\n',{flag:'wx'});
console.log('PSC1_INDEPENDENT_ENVIRONMENTS: '+JSON.stringify(result));
