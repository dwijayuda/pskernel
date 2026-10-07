import assert from 'node:assert/strict';
import { test } from 'node:test';
import path from 'node:path';
import { artifactKey, canonicalArtifact } from './artifact-evidence.mjs';
import { checkedSourceClosureArtifacts } from './source-closure-artifact.mjs';
import { createReleaseSemanticLock } from './release-semantic-lock.mjs';
import { verifySemanticLock } from './semantic-lock.mjs';

const artifact = (value, domain, contract) => canonicalArtifact(value, domain, contract);

function fixture() {
  const root=path.resolve('/release');
  const source=checkedSourceClosureArtifacts({
    root, entry:path.join(root,'Main.ps'), kind:'ps', closureSha256:'2'.repeat(64),
    ordered:[{path:path.join(root,'Main.ps'),source:'const answer: Nat := { 42 }\n'}],
  });
  const sourceBlobs=new Map(source.files.map(item=>[artifactKey(item.identity),item.bytes]));
  const context={
    semanticIdentity:artifact({language:'proofscript',profile:'release'},'semantic-identity','psc-semantic-identity/1'),
    semanticProfile:artifact({profile:'release'},'semantic-profile','psc-semantic-profile/1'),
    trustManifest:artifact({contract:'psc-trust-manifest/1',closure:'fixture'},'trust-manifest','psc-trust-manifest/1'),
    structuralInterface:artifact({structural:'fixture'},'runtime-interface','psc-runtime-interface-json/1'),
    behavioralInterface:artifact({behavioral:'pending'},'behavioral-interface','psc-behavioral-interface/1'),
    theoryManifest:artifact({theory:'external'},'theory-manifest','psc-theory-manifest/1'),
    runtimeSemantics:artifact({runtime:'psc-runtime-semantics/1'},'runtime-semantics','psc-runtime-semantics/1'),
    verifiedIr:artifact({ir:'psc-verified-ir/1'},'verified-ir-contract','psc-verified-ir/1'),
    targetAbi:artifact({abi:'fixture'},'target-abi','fixture-target-abi/1'),
    evidencePolicy:artifact({policy:'pending-preservation'},'evidence-policy','psc-release-evidence-policy/1'),
    compiler:artifact({compiler:'fixture'},'tool-inputs','fixture-compiler/1'),
  };
  return {source,sourceBlobs,context};
}

test('release lock derives source manifest from exact checked source closure and replays V1', async()=>{
  const f=fixture();
  const proposal=createReleaseSemanticLock({
    packageName:'fixture',version:'1.0.0',sourceClosure:f.source.closure,
    resolveArtifact:id=>f.sourceBlobs.get(artifactKey(id)),
    semanticIdentity:f.context.semanticIdentity,semanticProfile:f.context.semanticProfile,
    trustManifest:f.context.trustManifest,structuralInterface:f.context.structuralInterface,
    behavioralInterface:f.context.behavioralInterface,theoryManifest:f.context.theoryManifest,
    runtimeSemantics:f.context.runtimeSemantics,verifiedIr:f.context.verifiedIr,
    targetAbi:f.context.targetAbi,evidencePolicy:f.context.evidencePolicy,
    toolchains:[{role:'compiler',artifact:f.context.compiler}],
  });
  assert.equal(proposal.authority,'audit-record-only');
  assert.equal(proposal.releaseAccepted,false);
  assert.equal(proposal.sourceFiles,1);
  const checked=await verifySemanticLock(proposal.lock,{
    resolveArtifact:id=>proposal.artifacts.get(artifactKey(id)),
    expectedLockId:proposal.lock.identity,
    expectedSemanticIdentityId:f.context.semanticIdentity.identity,
    allowedAssumptions:[],allowedCapabilities:[],requiredToolchainRoles:['compiler'],
  });
  assert.equal(checked.integrityVerified,true);
  assert.equal(checked.semanticClaimsVerified,false);
  assert.equal(checked.sourceFiles,1);
  assert.deepEqual(checked.packageOrder,['fixture']);
});

test('release lock refuses missing source bytes and does not infer missing semantic inputs',()=>{
  const f=fixture();
  assert.throws(()=>createReleaseSemanticLock({
    packageName:'fixture',version:'1.0.0',sourceClosure:f.source.closure,
    resolveArtifact:()=>Buffer.from('tampered'),
    semanticIdentity:f.context.semanticIdentity,semanticProfile:f.context.semanticProfile,
    trustManifest:f.context.trustManifest,structuralInterface:f.context.structuralInterface,
    behavioralInterface:f.context.behavioralInterface,theoryManifest:f.context.theoryManifest,
    runtimeSemantics:f.context.runtimeSemantics,verifiedIr:f.context.verifiedIr,
    targetAbi:f.context.targetAbi,evidencePolicy:f.context.evidencePolicy,
  }),/ARTIFACT_BYTES/);
  assert.throws(()=>createReleaseSemanticLock({
    packageName:'fixture',version:'1.0.0',sourceClosure:f.source.closure,
    resolveArtifact:id=>f.sourceBlobs.get(artifactKey(id)),
    semanticIdentity:f.context.semanticIdentity,semanticProfile:f.context.semanticProfile,
    trustManifest:f.context.trustManifest,structuralInterface:f.context.structuralInterface,
    behavioralInterface:f.context.behavioralInterface,theoryManifest:f.context.theoryManifest,
    runtimeSemantics:f.context.runtimeSemantics,verifiedIr:f.context.verifiedIr,
    targetAbi:undefined,evidencePolicy:f.context.evidencePolicy,
  }),/ARTIFACT/);
});
