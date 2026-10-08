import { artifactKey, canonicalArtifact, canonicalBytes, verifyArtifact } from './artifact-evidence.mjs';

const copy = value => JSON.parse(canonicalBytes(value));
const fail = code => { throw new Error('PSC_EVIDENCE_ENVELOPE_' + code); };
const id = value => { artifactKey(value); return copy(value); };

export function createEvidenceEnvelope({
  executableArtifact, pscvCert, certifiedSource, buildGraph, buildArchive,
  runtimeInterface, targetAdapters = [], providerInputs = [], typeScriptToolInputs, sourceResources, seedResources,
  transformationAssurance = 'trusted-implementation-global-preservation-unproved',
}) {
  if (!executableArtifact || !pscvCert || !certifiedSource || !buildGraph || !buildArchive) fail('REQUIRED');
  const value = {
    schemaVersion: 1,
    contract: 'psc-evidence-envelope/1',
    executableArtifact: id(executableArtifact),
    pscvCert: id(pscvCert),
    certifiedSource: id(certifiedSource),
    buildGraph: id(buildGraph),
    buildArchive: id(buildArchive),
    ...(runtimeInterface ? { runtimeInterface: id(runtimeInterface) } : {}),
    targetAdapters: targetAdapters.map(id),
    providerInputs: providerInputs.map(id),
    ...(typeScriptToolInputs ? { typeScriptToolInputs: id(typeScriptToolInputs) } : {}),
    resources: {
      ...(sourceResources ? { source: copy(sourceResources) } : {}),
      ...(seedResources ? { checkedSession: copy(seedResources) } : {}),
    },
    transformationAssurance,
    semanticAcceptance: 'source-kernel-checked',
    executablePreservation: 'not-established',
    authority: 'audit-record-only',
    releaseAccepted: false,
  };
  return canonicalArtifact(value, 'evidence-envelope', 'psc-evidence-envelope/1');
}

export async function verifyEvidenceEnvelope(record, { resolveArtifact, requireRuntimeInterface = false } = {}) {
  verifyArtifact(record.bytes, record.identity);
  if (record.identity.domain !== 'evidence-envelope' || record.identity.contract !== 'psc-evidence-envelope/1')
    fail('IDENTITY');
  const value = JSON.parse(record.bytes);
  if (!canonicalBytes(value).equals(Buffer.from(record.bytes)) || value.schemaVersion !== 1 ||
      value.contract !== 'psc-evidence-envelope/1' || value.authority !== 'audit-record-only' ||
      value.releaseAccepted !== false || value.executablePreservation !== 'not-established') fail('SCHEMA');
  if (typeof resolveArtifact !== 'function') fail('RESOLVER');
  const required = [value.executableArtifact, value.pscvCert, value.certifiedSource, value.buildGraph, value.buildArchive,
    ...(value.runtimeInterface ? [value.runtimeInterface] : []), ...(value.targetAdapters ?? []), ...(value.providerInputs ?? []),
    ...(value.typeScriptToolInputs ? [value.typeScriptToolInputs] : [])];
  if (requireRuntimeInterface && !value.runtimeInterface) fail('RUNTIME_INTERFACE_REQUIRED');
  for (const identity of required) {
    const bytes = await resolveArtifact(identity);
    verifyArtifact(bytes, identity);
  }
  return Object.freeze({
    kind: 'accepted',
    envelopeId: copy(record.identity),
    executableArtifact: copy(value.executableArtifact),
    semanticAcceptance: value.semanticAcceptance,
    executablePreservation: value.executablePreservation,
    authority: 'audit-record-only',
    releaseAccepted: false,
  });
}
