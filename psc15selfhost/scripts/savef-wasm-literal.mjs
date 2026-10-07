import { readObservedFileBytes } from './observed-file-bytes.mjs';
import { fileURLToPath } from 'node:url';
import { artifactId, artifactKey, canonicalArtifact, canonicalBytes, verifyArtifact } from './artifact-evidence.mjs';
import { decodeComparatorJson } from './comparator-export.mjs';
import { knowledgeObject } from './savef-graph.mjs';
import { createKnowledgeReuseSession } from './savef-lifecycle.mjs';
import { createCertificateBoundary } from './certificate-boundary.mjs';
import { wasmLiteralCertificateChecker } from './wasm-literal-certificate.mjs';
import { validateWasmLiteralBinary } from './wasm-literal-binary-validator.mjs';

const claimId = 'wasm-closed-i32-literal-export-behavior';
const checkerId = 'psc-wasm-literal-reuse-checker/1';
const operationId = 'psc-reuse-wasm-literal-artifact/1';
const assumption = 'trusted-wasm-literal-validator-implementation';
const copy = value => JSON.parse(canonicalBytes(value));
const equalId = (left, right) => artifactKey(left) === artifactKey(right);
const fail = code => { throw new Error('PSC_WASM_REUSE_' + code); };
function snapshot(item, limit = 16 * 1024 * 1024) {
  if (!(item?.bytes instanceof Uint8Array) || item.bytes.length > limit) fail('RESOURCE_EXHAUSTED');
  const result = { identity: copy(item.identity), bytes: Buffer.from(item.bytes) };
  verifyArtifact(result.bytes, result.identity); return result;
}

/** Exact files implementing the registered operation and binary validator.
 * This is an observed implementation witness, not full runtime/input closure.
 */
async function implementationWitness() {
  const files = [];
  for (const name of ['savef-wasm-literal.mjs', 'wasm-literal-binary-validator.mjs', 'wasm-literal-certificate.mjs']) {
    const bytes = await readObservedFileBytes(fileURLToPath(new URL(name, import.meta.url)), 1024 * 1024);
    files.push({ bytes, identity: artifactId(bytes, 'host-source', 'psc-host-source/1'), name });
  }
  const manifest = canonicalArtifact({ contract: 'psc-wasm-literal-reuse-implementation/1',
    files: files.map(({ name, identity }) => ({ name, identity })), fullInputClosureEstablished: false,
    assumptions: ['trusted-host-module-loading', 'selected-host-runtime', 'shared-certificate-and-knowledge-boundaries'] },
    'implementation', 'psc-wasm-literal-reuse-implementation/1');
  return { manifest, files };
}

/** Packages a real checked binary relation for later fresh replay. No search
 * index is updated, no release license is inferred, and no reuse event exists.
 */
export async function createWasmLiteralKnowledge({ binary, expectation, license, semanticIdentity, scope, provenance = [] }) {
  binary = snapshot(binary); expectation = snapshot(expectation); license = snapshot(license);
  if (!Array.isArray(provenance) || provenance.length > 32) fail('PROVENANCE_LIMIT');
  provenance = provenance.map(item => snapshot(item));
  const selected = wasmLiteralCertificateChecker({ binary, expectation });
  const checked = validateWasmLiteralBinary(binary.bytes, expectation);
  if (checked.kind !== 'accepted') return checked;
  const implementation = await implementationWitness();
  const certificate = canonicalArtifact({ contract: 'psc-certificate/1', checkerId,
    subjectId: selected.subject.identity, payload: selected.payload }, 'certificate', 'psc-certificate/1');
  const observation = canonicalArtifact(checked, 'validation-observation', 'psc-wasm-literal-validation-observation/1');
  const spec = knowledgeObject({ contract: 'psc-knowledge-object/2', kind: 'specification',
    semanticIdentity, scope, authorityClass: 'advisory', dependencies: [], assumptions: [], claims: [],
    payload: expectation.identity, license: license.identity, evidence: [], provenance: provenance.map(item => item.identity),
    implementationWitnesses: [], resourceEvidence: [], supersedes: [], migrations: [] });
  const object = knowledgeObject({ contract: 'psc-knowledge-object/2', kind: 'artifact',
    semanticIdentity, scope, authorityClass: 'validation-authority',
    dependencies: [{ relation: 'specification', target: spec.identity }], assumptions: [assumption],
    claims: [{ claimId, status: 'validated', subjectId: selected.subject.identity, certificateId: certificate.identity }],
    payload: binary.identity, license: license.identity, evidence: [certificate.identity, observation.identity],
    provenance: provenance.map(item => item.identity),
    implementationWitnesses: [implementation.manifest.identity, ...implementation.files.map(item => item.identity)],
    resourceEvidence: [], supersedes: [], migrations: [] });
  return { kind: 'accepted', object, specification: spec,
    artifacts: [object, spec, binary, expectation, license, certificate, selected.subject, observation,
      implementation.manifest, ...implementation.files, ...provenance],
    claim: claimId, authority: 'replayable-validation-data', indexed: false, sourcePreservation: false, releaseAccepted: false };
}

export function wasmLiteralReuseTask(expectationId) {
  artifactKey(expectationId);
  return canonicalArtifact({ contract: 'psc-wasm-literal-reuse-task/1', expectationId },
    'reuse-task', 'psc-wasm-literal-reuse-task/1');
}

/** The caller independently selects the exact binary, expectation, knowledge
 * root and context. Retrieved knowledge cannot choose the checker or task.
 */
export async function createWasmLiteralReuseSession({ binary, expectation, knowledgeId, context, resolveArtifact }) {
  binary = snapshot(binary); expectation = snapshot(expectation); knowledgeId = copy(knowledgeId); context = copy(context);
  if (!Array.isArray(context.requiredClaims) || !context.requiredClaims.includes(claimId) ||
      !Array.isArray(context.allowedAssumptions) || !context.allowedAssumptions.includes(assumption)) fail('CONTEXT');
  const task = wasmLiteralReuseTask(expectation.identity);
  const implementation = await implementationWitness();
  const selected = wasmLiteralCertificateChecker({ binary, expectation });
  const boundary = createCertificateBoundary({ checkers: new Map([[checkerId, selected.checker]]) });
  function checkTask(proposed) {
    if (!equalId(proposed.identity, task.identity) || !Buffer.from(proposed.bytes).equals(task.bytes)) fail('TASK');
  }
  const session = createKnowledgeReuseSession({ context, resolveArtifact, certificateBoundary: boundary,
    claimPolicies: new Map([[claimId, { subjectId: selected.subject.identity, claimClass: claimId, checkerId }]]),
    assuranceBefore: { binaryBehavior: 'requires-fresh-validation', sourcePreservation: false },
    operations: new Map([[operationId, { identity: implementation.manifest.identity, useType: 'certificate',
      async run({ task: proposed, input, validity, resolveArtifact: resolveValidated }) {
        checkTask(proposed);
        if (!equalId(input.identity, expectation.identity) || !Buffer.from(input.bytes).equals(expectation.bytes) ||
            !validity.verifiedClaims.some(claim => equalId(claim.objectId, knowledgeId) &&
              claim.claimId === claimId && equalId(claim.subjectId, selected.subject.identity))) fail('VALIDITY');
        const knowledge = decodeComparatorJson(resolveValidated(knowledgeId));
        if (!equalId(knowledge.payload, binary.identity)) fail('PAYLOAD');
        return { identity: binary.identity, bytes: resolveValidated(binary.identity) };
      } }]]),
    async acceptOutput({ task: proposed, output, subject, uses }) {
      checkTask(proposed);
      if (!equalId(output.identity, binary.identity) || uses.some(use => !equalId(use.output.identity, output.identity)))
        return { kind: 'rejectedInvalid', code: 'wasm-reuse-output' };
      const validation = validateWasmLiteralBinary(output.bytes, expectation);
      if (validation.kind !== 'accepted') return validation;
      return { kind: 'accepted', subject, assuranceAfter: { binaryBehavior: claimId,
        binaryId: output.identity, expectationId: expectation.identity, sourcePreservation: false, releaseAccepted: false } };
    },
  });
  return Object.freeze({ operationId, task: snapshot(task), expectation: snapshot(expectation),
    implementation: implementation.manifest,
    acquire: () => session.acquire([knowledgeId]), apply: session.apply, accept: session.accept,
    measurements: session.measurements, revoke: session.revoke,
    close() { session.close(); boundary.close(); } });
}
