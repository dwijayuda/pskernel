// Deterministic fictional data for focused lock/capsule tests, never a release lock.
import { canonicalArtifact, artifactKey } from './artifact-evidence.mjs';
import { semanticLock, sourceManifest } from './semantic-lock.mjs';

export function semanticLockFixture() {
  const artifacts = [];
  const add = (value, domain, contract = domain + '/1') => {
    const artifact = canonicalArtifact(value, domain, contract); artifacts.push(artifact); return artifact;
  };
  const meaning = add({ fixture: 'integer-equality-only' }, 'semantic-identity');
  const trust = add({ fixture: 'no-release-trust-claim' }, 'trust-manifest');
  const source = add({ program: 'fixture' }, 'source');
  const manifest = sourceManifest([{ path: 'Fixture.ps', artifact: source.identity }]); artifacts.push(manifest);
  const field = role => add({ fixture: role }, role).identity;
  const pkg = { name: 'fixture', version: '1', sourceManifestId: manifest.identity,
    structuralInterfaceId: field('structural-interface'), behavioralInterfaceId: field('behavioral-interface'),
    semanticProfileId: field('semantic-profile'), theoryManifestId: field('theory-manifest'),
    runtimeSemanticsId: field('runtime-semantics'), verifiedIrId: field('verified-ir'),
    targetAbiId: field('target-abi'), evidencePolicyId: field('evidence-policy'),
    assumptions: [], capabilities: [], toolchains: [{ role: 'checker', artifact: field('checker') }], dependencies: [] };
  const fields = { contract: 'psc-semantic-lock/1', semanticIdentityId: meaning.identity,
    trustManifestId: trust.identity, roots: [pkg.name], packages: [pkg] };
  const lock = semanticLock(fields); artifacts.push(lock);
  const policy = { expectedLockId: lock.identity, expectedSemanticIdentityId: meaning.identity,
    allowedAssumptions: [], allowedCapabilities: [], requiredToolchainRoles: ['checker'] };
  const resolveArtifact = id => artifacts.find(item => artifactKey(item.identity) === artifactKey(id))?.bytes;
  return { artifacts, fields, lock, policy, resolveArtifact, add, source, manifest };
}
