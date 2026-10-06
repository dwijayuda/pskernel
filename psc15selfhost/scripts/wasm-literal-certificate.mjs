import { artifactKey, canonicalArtifact, canonicalBytes, verifyArtifact } from './artifact-evidence.mjs';
import { validateWasmLiteralBinary } from './wasm-literal-binary-validator.mjs';

/** A built-in offline relation checker over two independently pinned artifacts.
 * A certificate requests replay; it cannot supply a different implementation,
 * binary, expectation, or a broader source-preservation interpretation.
 */
export function wasmLiteralCertificateChecker({ binary, expectation, resourceLimits = {} }) {
  const limits = JSON.parse(canonicalBytes(resourceLimits));
  const binaryLimit = limits.maxBytes ?? 16 * 1024 * 1024;
  const expectationLimit = limits.maxExpectationBytes ?? 8 * 1024 * 1024;
  if (!Number.isSafeInteger(binaryLimit) || binaryLimit < 0 || !Number.isSafeInteger(expectationLimit) || expectationLimit < 0 ||
      !(binary?.bytes instanceof Uint8Array) || binary.bytes.length > binaryLimit ||
      !(expectation?.bytes instanceof Uint8Array) || expectation.bytes.length > expectationLimit) throw new Error('PSC_WASM_CERTIFICATE_RESOURCE_EXHAUSTED');
  binary = { bytes: Buffer.from(binary.bytes), identity: JSON.parse(canonicalBytes(binary.identity)) };
  expectation = { bytes: Buffer.from(expectation.bytes), identity: JSON.parse(canonicalBytes(expectation.identity)) };
  verifyArtifact(binary.bytes, binary.identity); verifyArtifact(expectation.bytes, expectation.identity);
  if (binary.identity.domain !== 'wasm-binary' || binary.identity.contract !== 'webassembly-core/1' ||
      expectation.identity.domain !== 'wasm-literal-expectation' || expectation.identity.contract !== 'psc-wasm-literal-expectation/1') throw new Error('PSC_WASM_CERTIFICATE_ARTIFACT_CONTRACT');
  const payload = { binaryId: binary.identity, expectationId: expectation.identity };
  const subject = canonicalArtifact({ contract: 'psc-wasm-literal-binary-subject/1', ...payload },
    'validation-subject', 'psc-wasm-literal-binary-subject/1');
  const claimClass = 'wasm-closed-i32-literal-export-behavior';
  const checker = Object.freeze({ claimClass,
    identity: { contract: 'psc-wasm-literal-binary-checker/1', implementation: 'built-in-bounded-independent-decoder',
      sourcePreservation: 'not-implied' },
    async verify(bytes, requested) {
      if (artifactKey(requested.identity) !== artifactKey(subject.identity) ||
          !Buffer.from(requested.bytes).equals(subject.bytes) || !Buffer.from(bytes).equals(canonicalBytes(payload))) {
        return { kind: 'rejectedInvalid', code: 'wasm-literal-certificate-subject' };
      }
      const result = validateWasmLiteralBinary(binary.bytes, expectation, limits);
      if (result.kind !== 'accepted') return result;
      return { kind: 'accepted', claimClass, subjectId: subject.identity, evidence: result };
    },
  });
  // Separate copies prevent a caller from mutating the closure's subject/IDs.
  return { checker, subject: { bytes: Buffer.from(subject.bytes), identity: JSON.parse(canonicalBytes(subject.identity)) },
    payload: JSON.parse(canonicalBytes(payload)) };
}
