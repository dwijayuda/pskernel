import assert from 'node:assert/strict';
import { test } from 'node:test';
import { artifactId, canonicalArtifact } from './artifact-evidence.mjs';
import { createCheckedBuildGraph } from './checked-build-evidence.mjs';
import { packObservedBuildArchive } from './observed-build-archive.mjs';
import { createEvidenceEnvelope } from './evidence-envelope.mjs';
import { createReleaseEvidenceBundle, verifyReleaseEvidenceBundle } from './release-evidence-bundle.mjs';

function fixture(){
  const admissions='{"fixture":"admissions"}\n';
  const coreId=artifactId(Buffer.from(admissions),'canonical-admissions','proofscript-checked-admissions/2');
  const cert=canonicalArtifact({contract:'pscv-cert/1',canonicalAdmissionsId:coreId},'pscv-cert','pscv-cert/1');
  const certified=canonicalArtifact({contract:'psc-certified-source/1',canonicalAdmissionsId:coreId,
    certificateId:cert.identity},'certified-source','psc-certified-source/1');
  const build=createCheckedBuildGraph({
    sourceKind:'ps',sources:['const answer: Nat := { 42 }'],admissions,
    typeScript:'export const answer: bigint = 42n;\n',
    javaScript:Buffer.from('export const answer = 42n;\n'),
    declarations:Buffer.from('export declare const answer: bigint;\n'),
    sourceMap:Buffer.from('{"version":3}\n'),
    compilerBytes:Buffer.from('fixture-compiler'),compilerKind:'fixture',
    typeScriptCompilerBytes:Buffer.from('fixture-tsc'),
    provider:{profile:'fixture-profile',provider:'fixture-provider',protocol:'fixture/1'},
    providerSecurity:{profile:'fixture-security'},
    kernelContract:{id:'fixture-kernel-contract/1',sha256:'0'.repeat(64)},
    hostSources:[],runtime:{implementation:'node',version:'fixture',platform:'fixture',arch:'fixture'},
    outputStem:'out',pscvCertificate:cert,certifiedSourceArtifact:certified,
  });
  const archive=packObservedBuildArchive(build);
  const envelope=createEvidenceEnvelope({
    executableArtifact:build.executableArtifact,pscvCert:cert.identity,certifiedSource:certified.identity,
    buildGraph:build.identity,buildArchive:archive.identity,
  });
  const bundle=createReleaseEvidenceBundle({envelope,buildArchive:archive});
  const definitions=build.graph.entries.filter(entry=>entry.identity.contract==='psc-pass-definition/1')
    .map(entry=>entry.canonicalValue);
  const assumptions=[...new Set(definitions.flatMap(definition=>definition.assumptionIds))];
  return {build,archive,envelope,bundle,assumptions};
}

test('release bundle replays observed build and envelope without upgrading assurance',async()=>{
  const f=fixture();
  const checked=await verifyReleaseEvidenceBundle(f.bundle,{
    expectedBundleId:f.bundle.identity,allowedAssumptions:f.assumptions,requireRuntimeInterface:false,
  });
  assert.equal(checked.kind,'accepted',checked.reason);
  assert.equal(checked.integrityVerified,true);
  assert.equal(checked.semanticClaimsVerified,false);
  assert.equal(checked.executablePreservation,'not-established');
  assert.equal(checked.releaseAccepted,false);
  assert.equal(checked.observedBuild.executions.length,f.build.graph.executions.length);
});

test('release bundle rejects wrong expected identity and tampered embedded archive',async()=>{
  const f=fixture();
  const wrong=canonicalArtifact({wrong:true},'release-evidence-bundle','psc-release-evidence-bundle/1');
  const denied=await verifyReleaseEvidenceBundle(f.bundle,{
    expectedBundleId:wrong.identity,allowedAssumptions:f.assumptions,requireRuntimeInterface:false,
  });
  assert.equal(denied.kind,'rejectedInvalid');
  const value=JSON.parse(f.bundle.bytes);
  value.buildArchive.data=Buffer.from('tampered').toString('base64');
  const forged=canonicalArtifact(value,'release-evidence-bundle','psc-release-evidence-bundle/1');
  const tampered=await verifyReleaseEvidenceBundle(forged,{
    expectedBundleId:forged.identity,allowedAssumptions:f.assumptions,requireRuntimeInterface:false,
  });
  assert.equal(tampered.kind,'rejectedInvalid');
});
