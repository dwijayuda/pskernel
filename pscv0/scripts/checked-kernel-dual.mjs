import { createHash } from 'node:crypto';
import { checkAdmissionsWithKernel, defaultCheckedKernel } from './checked-kernel-provider.mjs';
import { assertCanonicalAdmissionsEnvelope } from './kernel-contract.mjs';
import { checkedKernelIdentity } from './checked-kernel-identity.mjs';

// The reference provider reports host/resource failures under kernel-rejection.
// Only genuine semantic rejections at a valid admission index establish parity.
export function semanticDecision(result, admissionCount) {
  if (result?.accepted === true && !('errorKind' in result) && !('declarationIndex' in result)) return 'accepted';
  const message = result?.message;
  // Lean uses `other` for these two well-defined invalid-expression cases too.
  // Keep unknown `other` failures inconclusive instead of assuming rejection.
  const knownOther = typeof message === 'string' && (
    message.endsWith('(other:type checker does not support loose bound variables, replace them with free variables before invoking it)') ||
    /\(other:invalid reference to undefined universe level parameter '[^']*'\)$/u.test(message)
  );
  if (result?.accepted !== false || result.errorKind !== 'kernel-rejection' ||
      !Number.isSafeInteger(result.declarationIndex) || result.declarationIndex < 0 ||
      result.declarationIndex >= admissionCount || typeof result.message !== 'string' ||
      /timeout|exhaust|recursion|interrupt|memory|stack|budget/iu.test(result.message) ||
      (result.message.includes('other:') && !knownOther)) {
    return 'inconclusive';
  }
  return `rejected:${result.declarationIndex}`;
}

export function assertProviderParity(primary, secondary, admissionCount) {
  const left = semanticDecision(primary, admissionCount);
  const right = semanticDecision(secondary, admissionCount);
  if (left === 'inconclusive' || right === 'inconclusive') {
    throw new Error(`PSC2_DUAL_CHECK_INCONCLUSIVE: ${left} / ${right}`);
  }
  if (left !== right) throw new Error(`PSC2_DUAL_CHECK_DISAGREEMENT: ${left} / ${right}`);
  return left;
}

export async function checkAdmissionsWithDual(
  admissions, primary = defaultCheckedKernel, secondary = 'pskernel-core', options = {},
) {
  if (!([primary, secondary].includes('pskernel-core') &&
      [primary, secondary].some(value => value === 'lean434' || value === 'lean434-wasm'))) {
    throw new Error('PSC2_DUAL_CHECK_PAIR: require PSKernel Core and an official Lean provider');
  }
  const payload = assertCanonicalAdmissionsEnvelope(admissions);
  const left = await checkAdmissionsWithKernel(admissions, primary, options);
  const right = await checkAdmissionsWithKernel(admissions, secondary, options);
  const decision = assertProviderParity(left.result, right.result, payload.admissions.length);
  return Object.freeze({
    result: left.result,
    descriptor: left.descriptor,
    parity: Object.freeze({
      schemaVersion: 1,
      canonicalAdmissionsSha256: createHash('sha256').update(admissions).digest('hex'),
      admissionCount: payload.admissions.length,
      primary: { selector: primary, ...checkedKernelIdentity(primary) },
      secondary: { selector: secondary, ...checkedKernelIdentity(secondary) },
      decision,
    }),
    providerSecurity: Object.freeze({
      primary: left.providerSecurity,
      secondary: right.providerSecurity,
    }),
  });
}
