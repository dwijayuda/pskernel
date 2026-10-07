import { canonicalArtifact, verifyArtifact, artifactKey } from './artifact-evidence.mjs';
import { decodeIrArtifact, irEncodingContract } from './ir-artifact.mjs';

export const runtimeInterfaceContract = 'psc-runtime-interface-json/1';

/** Independent projection of archived VerifiedIR bytes. This checks the
 * signature/layout projection, not validator soundness or behavioral adequacy.
 */
export function runtimeInterfaceArtifact(verifiedIr, limits = {}) {
  verifyArtifact(verifiedIr.bytes, verifiedIr.identity);
  if (verifiedIr.identity.domain !== 'verified-ir' || verifiedIr.identity.contract !== irEncodingContract)
    throw new Error('PSC_RUNTIME_INTERFACE_INPUT_CONTRACT');
  const module = decodeIrArtifact(verifiedIr.bytes, limits);
  const value = [runtimeInterfaceContract, 'psc-runtime-semantics/1', 'psc-runtime-values/1',
    module[1], module[2], module[3], module[4].map(declaration => declaration.slice(0, 4))];
  return canonicalArtifact(value, 'runtime-interface', runtimeInterfaceContract);
}

export function verifyRuntimeInterfaceProjection(verifiedIr, proposed, limits = {}) {
  const expected = runtimeInterfaceArtifact(verifiedIr, limits);
  verifyArtifact(proposed.bytes, proposed.identity);
  if (artifactKey(proposed.identity) !== artifactKey(expected.identity) ||
      !Buffer.from(proposed.bytes).equals(expected.bytes)) throw new Error('PSC_RUNTIME_INTERFACE_PROJECTION');
  return Object.freeze({ contract: 'psc-runtime-interface-projection/1', inputId: verifiedIr.identity,
    interfaceId: proposed.identity, fingerprintContract: runtimeInterfaceContract,
    semanticKey: artifactKey(proposed.identity), scope: 'exact-runtime-signatures-layouts-and-imports',
    behavioralReuse: false, kernelAuthority: false });
}
