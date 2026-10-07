import { artifactKey, canonicalArtifact, canonicalBytes, verifyArtifact } from './artifact-evidence.mjs';
import { semanticLock, sourceManifest } from './semantic-lock.mjs';
import { verifyCheckedSourceClosure } from './source-closure-artifact.mjs';

export const releaseLockProposalContract = 'psc-release-semantic-lock-proposal/1';
const fail = code => { throw new Error('PSC_RELEASE_LOCK_' + code); };
const copy = value => JSON.parse(canonicalBytes(value));
const record = (value, domain, contract) => {
  if (!(value?.bytes instanceof Uint8Array) || !value.identity) fail('ARTIFACT');
  verifyArtifact(value.bytes, value.identity);
  if (domain && value.identity.domain !== domain) fail('DOMAIN');
  if (contract && value.identity.contract !== contract) fail('CONTRACT');
  return value;
};
const text = value => {
  if (typeof value !== 'string' || !value || value.length > 4096) fail('TEXT');
  return value;
};

/** Build a V1 semantic-lock proposal from exact artifacts already produced or
 * explicitly selected by the release process. No semantic context is inferred.
 * Behavioral/theory/evidence inputs may describe pending assurance, but the
 * lock pins their exact bytes instead of turning them into proof.
 */
export function createReleaseSemanticLock({
  packageName,
  version,
  sourceClosure,
  resolveArtifact,
  semanticIdentity,
  semanticProfile,
  trustManifest,
  structuralInterface,
  behavioralInterface,
  theoryManifest,
  runtimeSemantics,
  verifiedIr,
  targetAbi,
  evidencePolicy,
  assumptions = [],
  capabilities = [],
  toolchains = [],
  dependencies = [],
  resourceLimits,
}) {
  text(packageName); text(version);
  if (typeof resolveArtifact !== 'function') fail('RESOLVER');
  record(sourceClosure, 'source-closure', 'psc-source-closure/1');
  const checkedClosure = verifyCheckedSourceClosure(sourceClosure, { resolveArtifact });
  const closureValue = JSON.parse(sourceClosure.bytes);
  const sources = sourceManifest(closureValue.files);
  const required = {
    semanticIdentity: record(semanticIdentity),
    semanticProfile: record(semanticProfile),
    trustManifest: record(trustManifest, 'trust-manifest', 'psc-trust-manifest/1'),
    structuralInterface: record(structuralInterface),
    behavioralInterface: record(behavioralInterface),
    theoryManifest: record(theoryManifest),
    runtimeSemantics: record(runtimeSemantics),
    verifiedIr: record(verifiedIr),
    targetAbi: record(targetAbi),
    evidencePolicy: record(evidencePolicy),
  };
  if (!Array.isArray(assumptions) || !Array.isArray(capabilities) ||
      !Array.isArray(toolchains) || !Array.isArray(dependencies)) fail('ARRAY');
  const assumptionIds = assumptions.map(item => record(item).identity);
  const capabilityValues = capabilities.map(text);
  if (new Set(capabilityValues).size !== capabilityValues.length) fail('CAPABILITY_DUPLICATE');
  const tools = toolchains.map(item => {
    if (!item || Object.keys(item).sort().join(',') !== 'artifact,role') fail('TOOLCHAIN');
    return { role: text(item.role), artifact: record(item.artifact).identity };
  });
  if (new Set(tools.map(item => item.role)).size !== tools.length) fail('TOOLCHAIN_DUPLICATE');
  const deps = dependencies.map(item => {
    if (!item || Object.keys(item).sort().join(',') !== 'behavioralInterfaceId,package,structuralInterfaceId')
      fail('DEPENDENCY');
    artifactKey(item.structuralInterfaceId); artifactKey(item.behavioralInterfaceId); text(item.package);
    return copy(item);
  });
  if (new Set(deps.map(item => item.package)).size !== deps.length) fail('DEPENDENCY_DUPLICATE');

  const lock = semanticLock({
    contract: 'psc-semantic-lock/1',
    semanticIdentityId: required.semanticIdentity.identity,
    trustManifestId: required.trustManifest.identity,
    roots: [packageName],
    packages: [{
      name: packageName,
      version,
      sourceManifestId: sources.identity,
      structuralInterfaceId: required.structuralInterface.identity,
      behavioralInterfaceId: required.behavioralInterface.identity,
      semanticProfileId: required.semanticProfile.identity,
      theoryManifestId: required.theoryManifest.identity,
      runtimeSemanticsId: required.runtimeSemantics.identity,
      verifiedIrId: required.verifiedIr.identity,
      targetAbiId: required.targetAbi.identity,
      evidencePolicyId: required.evidencePolicy.identity,
      assumptions: assumptionIds,
      capabilities: capabilityValues,
      toolchains: tools,
      dependencies: deps,
    }],
  }, resourceLimits);

  const artifacts = new Map();
  for (const item of [sourceClosure, sources, ...Object.values(required), ...assumptions,
      ...toolchains.map(item => item.artifact)]) {
    artifacts.set(artifactKey(item.identity), Buffer.from(item.bytes));
  }
  for (const file of closureValue.files) {
    const bytes = Buffer.from(resolveArtifact(file.artifact));
    verifyArtifact(bytes, file.artifact);
    artifacts.set(artifactKey(file.artifact), bytes);
  }
  return Object.freeze({
    contract: releaseLockProposalContract,
    lock,
    sourceManifest: sources,
    sourceClosureId: sourceClosure.identity,
    sourceFiles: checkedClosure.fileCount,
    artifacts,
    authority: 'audit-record-only',
    semanticClaimsVerified: false,
    releaseAccepted: false,
  });
}
