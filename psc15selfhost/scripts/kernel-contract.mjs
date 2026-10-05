import { createHash } from 'node:crypto';

export const kernelContractV1Canonical =
  'proofscript-kernel-contract/1\n' +
  'admissions=proofscript-checked-admissions/2\n' +
  'decision=accepted-boolean\n' +
  'failClosed=true\n';

export const kernelContractV1Sha256 = createHash('sha256')
  .update(kernelContractV1Canonical, 'utf8')
  .digest('hex');

export const kernelContractV1 = Object.freeze({
  id: 'proofscript-kernel-contract/1',
  admissionsFormat: 'proofscript-checked-admissions',
  admissionsVersion: 2,
  decision: 'accepted-boolean',
  failClosed: true,
  sha256: kernelContractV1Sha256,
});

export function assertCanonicalAdmissionsEnvelope(source) {
  if (typeof source !== 'string') {
    throw new TypeError('PSC2_KERNEL_CONTRACT_ADMISSIONS_TEXT');
  }
  let payload;
  try {
    payload = JSON.parse(source);
  } catch (cause) {
    throw new Error('PSC2_KERNEL_CONTRACT_ADMISSIONS_JSON', { cause });
  }
  if (payload === null || typeof payload !== 'object' || Array.isArray(payload)) {
    throw new Error('PSC2_KERNEL_CONTRACT_ADMISSIONS_OBJECT');
  }
  if (payload.format !== kernelContractV1.admissionsFormat) {
    throw new Error('PSC2_KERNEL_CONTRACT_ADMISSIONS_FORMAT');
  }
  if (payload.version !== kernelContractV1.admissionsVersion) {
    throw new Error('PSC2_KERNEL_CONTRACT_ADMISSIONS_VERSION');
  }
  if (!Array.isArray(payload.admissions)) {
    throw new Error('PSC2_KERNEL_CONTRACT_ADMISSIONS_ARRAY');
  }
  return payload;
}

export function assertKernelContractDecision(result) {
  if (result === null || typeof result !== 'object' || Array.isArray(result)) {
    throw new Error('PSC2_KERNEL_CONTRACT_RESULT_OBJECT');
  }
  if (typeof result.accepted !== 'boolean') {
    throw new Error('PSC2_KERNEL_CONTRACT_RESULT_ACCEPTED');
  }
  if (!result.accepted && typeof result.errorKind !== 'string') {
    throw new Error('PSC2_KERNEL_CONTRACT_RESULT_REJECTION');
  }
  return result;
}
