import { createHash } from 'node:crypto';

const EXPECTED = Object.freeze({
  protocol: 'pskernel-lean/1',
  provider: 'lean4-cpp',
  leanVersion: '4.34.0',
  leanCommit: '293d5d0c0c3f3dded4688b3ccd6a33939ac5102b',
  profile: 'lean4.34-core',
});
const PACKAGES = Object.freeze({
  native: '@proofscript/pskernel-lean',
  wasm: '@proofscript/pskernel-lean-wasm',
});
const MAX_BYTES = 16 * 1024 * 1024;
const MAX_DECLARATIONS = 100000;

export function inspectAdmissionsEnvelope(source) {
  if (typeof source !== 'string' || Buffer.byteLength(source, 'utf8') > MAX_BYTES ||
      source.length === 0 || source.charCodeAt(0) === 0xfeff) {
    throw new Error('PSCV_ADMISSIONS_INPUT_INVALID');
  }
  let parsed;
  try { parsed = JSON.parse(source); }
  catch { throw new Error('PSCV_ADMISSIONS_INVALID_JSON'); }
  if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed) ||
      Object.keys(parsed).sort().join(',') !== 'admissions,format,version' ||
      parsed.format !== 'proofscript-checked-admissions' || parsed.version !== 2 ||
      !Array.isArray(parsed.admissions) || parsed.admissions.length > MAX_DECLARATIONS) {
    throw new Error('PSCV_ADMISSIONS_ENVELOPE_INVALID');
  }
  return Object.freeze({
    contract: 'proofscript-checked-admissions/2',
    byteLength: Buffer.byteLength(source, 'utf8'),
    declarationCount: parsed.admissions.length,
    sha256: createHash('sha256').update(source, 'utf8').digest('hex'),
  });
}

export function supportedKernelTransports() {
  return Object.freeze(['native', 'wasm']);
}

function verifyModuleIdentity(module, transport) {
  if (module.leanKernelProviderProtocol !== EXPECTED.protocol ||
      module.leanKernelProviderName !== EXPECTED.provider ||
      module.leanKernelProviderVersion !== EXPECTED.leanVersion ||
      module.leanKernelProviderCommit !== EXPECTED.leanCommit ||
      typeof module.checkCanonicalAdmissions !== 'function') {
    throw new Error('PSCV_KERNEL_MODULE_IDENTITY_MISMATCH:' + transport);
  }
}

function verifyKernelReply(reply, transport) {
  if (!reply || typeof reply !== 'object' || Array.isArray(reply)) {
    throw new Error('PSCV_KERNEL_REPLY_INVALID');
  }
  for (const [key, value] of Object.entries(EXPECTED)) {
    if (reply[key] !== value) throw new Error('PSCV_KERNEL_RESPONSE_IDENTITY_MISMATCH:' + key);
  }
  if (typeof reply.accepted !== 'boolean') {
    throw new Error('PSCV_KERNEL_RESPONSE_ACCEPTED_MISSING');
  }
  if (reply.accepted === false && typeof reply.errorKind !== 'string') {
    throw new Error('PSCV_KERNEL_RESPONSE_REJECTION_KIND_MISSING');
  }
  return Object.freeze({
    status: reply.accepted ? 'kernel-admissions-accepted' : 'kernel-admissions-rejected',
    transport,
    provider: Object.freeze({ ...EXPECTED }),
    rejectionKind: reply.accepted ? null : reply.errorKind,
  });
}

/**
 * Host-owned, pinned provider selection. This API accepts no injected checker
 * function, arbitrary package specifier, binary override or wasm launcher.
 * The provider's Node adapter and installed npm bytes are still inside TCB.
 * It does NOT establish PSCV source fidelity, proof closure or certification.
 */
export async function checkWithLeanKernel(source, { transport = 'native' } = {}) {
  const envelope = inspectAdmissionsEnvelope(source);
  const packageName = PACKAGES[transport];
  if (!packageName) throw new Error('PSCV_KERNEL_TRANSPORT_UNSUPPORTED');
  let module;
  try {
    module = await import(packageName);
  } catch (error) {
    if (error?.code === 'ERR_MODULE_NOT_FOUND') {
      throw new Error('PSCV_KERNEL_PACKAGE_NOT_INSTALLED:' + packageName, { cause: error });
    }
    throw error;
  }
  verifyModuleIdentity(module, transport);
  // Disable the native package's environment-defined executable override and
  // checkout fallbacks. Use only the bundled hash-verified release provider.
  const options = transport === 'native'
    ? { env: {}, allowSourceCheckoutFallback: false, timeoutMs: 30000, maxBuffer: MAX_BYTES }
    : { timeoutMs: 30000, maxBuffer: MAX_BYTES };
  const reply = await module.checkCanonicalAdmissions(source, options);
  const classification = verifyKernelReply(reply, transport);
  return Object.freeze({
    ...classification,
    admissions: envelope,
    claims: Object.freeze(['lean4.34-kernel-admission-decision']),
    pscvCertified: false,
    sourceFidelityEstablished: false,
    executableFidelityEstablished: false,
  });
}
