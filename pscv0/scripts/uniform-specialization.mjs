import { artifactId, artifactKey, canonicalBytes, verifyArtifact } from './artifact-evidence.mjs';
import { decodeComparatorJson } from './comparator-export.mjs';
import { decodeIrArtifact } from './ir-artifact.mjs';

export const uniformSpecializationContract = 'psc-uniform-specialized-ir/1';
export const closedJsRepresentationProfile = 'psc-js-closed-instances/1';
export const uniformJsRepresentationProfile = 'psc-js-uniform-values/1';
const fail = code => { throw new Error('PSC_UNIFORM_SPECIALIZATION_' + code); };

/** An explicit representation selection, distinct from closed monomorphization.
 * The envelope identifies the policy; the payload remains exact validated
 * generic RuntimeIR. Identity does not prove target lowering or representation
 * adequacy and cannot replace a fresh source-invariant check.
 */
export function uniformSpecializationArtifact(value, { maxBytes = 128 * 1024 * 1024 } = {}) {
  if (!Number.isSafeInteger(maxBytes) || maxBytes <= 0) fail('RESOURCE_POLICY');
  const bytes = Buffer.from(value);
  const root = decodeComparatorJson(bytes, { maxBytes, maxDepth: 512, maxNodes: 2000000 });
  if (!Array.isArray(root) || root.length !== 3 || root[0] !== uniformSpecializationContract ||
      root[1] !== uniformJsRepresentationProfile) fail('PROFILE');
  const raw = canonicalBytes(root[2]);
  const module = decodeIrArtifact(raw, { maxBytes });
  if (module[1].length) fail('IMPORTS_UNSUPPORTED');
  return { bytes, identity: artifactId(bytes, 'uniform-specialized-ir', uniformSpecializationContract) };
}

export function verifyUniformSpecialization(input, output, { maxBytes = 128 * 1024 * 1024 } = {}) {
  if (input?.identity?.domain !== 'verified-ir' || input.identity.contract !== 'psc-runtime-ir-json/1') fail('INPUT_KIND');
  if (!Number.isSafeInteger(maxBytes) || maxBytes <= 0 || input.identity.byteLength > maxBytes || output?.identity?.byteLength > maxBytes) fail('RESOURCE_POLICY');
  verifyArtifact(input.bytes, input.identity);
  verifyArtifact(output.bytes, output.identity);
  const reconstructed = uniformSpecializationArtifact(output.bytes, { maxBytes });
  if (artifactKey(reconstructed.identity) !== artifactKey(output.identity)) fail('OUTPUT_KIND');
  const root = decodeComparatorJson(output.bytes, { maxBytes, maxDepth: 512, maxNodes: 2000000 });
  if (!canonicalBytes(root[2]).equals(Buffer.from(input.bytes))) fail('PAYLOAD_CHANGED');
  return Object.freeze({ contract: 'psc-uniform-specialization-correspondence/1',
    profile: uniformJsRepresentationProfile, inputId: input.identity, outputId: output.identity,
    relation: 'exact-generic-runtime-ir-identity-with-uniform-representation-selection',
    bytesPreserved: true, strictInputValidityVerified: false,
    targetRepresentationAdequacyProved: false, globalPreservationProved: false, authority: 'audit-record-only' });
}
