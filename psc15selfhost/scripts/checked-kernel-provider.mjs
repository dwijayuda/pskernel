import { existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { checkedKernelIdentity, ownedCheckedIdentity } from './checked-kernel-identity.mjs';
import {
  assertCanonicalAdmissionsEnvelope,
  assertKernelContractDecision,
  kernelContractV1,
} from './kernel-contract.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const nativeSuffix = process.platform === 'win32' ? '.exe' : '';

export const defaultCheckedKernel = 'lean434-wasm';
export const checkedKernelSelectors = Object.freeze(['lean434-wasm', 'lean434', 'pskernel-core.old3']);

const descriptors = Object.freeze({
  'pskernel-core.old3': Object.freeze({
    selector: 'pskernel-core.old3', package: '@proofscript/pskernel-core.old3',
    execution: 'psc-generated-js', version: ownedCheckedIdentity.version,
    generatedKernelSha256: ownedCheckedIdentity.generatedKernelSha256,
    sourceManifestSha256: ownedCheckedIdentity.sourceManifestSha256,
    kernelContract: kernelContractV1.id,
    kernelContractSha256: kernelContractV1.sha256,
  }),
  'lean434-wasm': Object.freeze({
    selector: 'lean434-wasm',
    package: '@proofscript/pskernel-lean-wasm',
    execution: 'wasm-node',
    sourceCommit: '1b21b2483df7e8de7542873c24eaff2501539b1b',
    verificationRun: 37014379617,
    kernelContract: kernelContractV1.id,
    kernelContractSha256: kernelContractV1.sha256,
  }),
  lean434: Object.freeze({
    selector: 'lean434',
    package: '@proofscript/pskernel-lean',
    execution: 'native',
    sourceCommit: '1b21b2483df7e8de7542873c24eaff2501539b1b',
    verificationCommit: '3c49f7d8a9812175e143c6db15cc3e0e496d23e2',
    kernelContract: kernelContractV1.id,
    kernelContractSha256: kernelContractV1.sha256,
  }),
});

export function checkedKernelDescriptor(selector = defaultCheckedKernel) {
  const descriptor = descriptors[selector];
  if (!descriptor) throw new Error(`PSC2_CHECKED_KERNEL_UNSUPPORTED: ${selector}`);
  return descriptor;
}

function assertSemanticIdentity(result, selector) {
  assertKernelContractDecision(result);
  for (const [field, expected] of Object.entries(checkedKernelIdentity(selector))) {
    if (result?.[field] !== expected) {
      throw new Error(`PSC2_CHECKED_PROVIDER_IDENTITY: ${field}`);
    }
  }
}

export async function checkAdmissionsWithKernel(
  admissions,
  selector = defaultCheckedKernel,
  options = {},
) {
  if (typeof admissions !== 'string') throw new TypeError('Expected canonical admissions text');
  assertCanonicalAdmissionsEnvelope(admissions);
  const descriptor = checkedKernelDescriptor(selector);
  const timeoutMs = options.timeoutMs ?? 60000;
  let result;

  if (selector === 'pskernel-core.old3') {
    const provider = await import('./checked-owned-kernel.mjs');
    result = await provider.checkOwnedAdmissions(admissions, {
      timeoutMs,
      ...(options.maxSteps !== undefined ? { maxSteps: options.maxSteps } : {}),
    });
  } else if (selector === 'lean434-wasm') {
    const provider = await import('../packages/pskernel-lean-wasm/index.mjs');
    result = await provider.checkCanonicalAdmissions(admissions, {
      timeoutMs,
      ...(options.wasmLauncherPath ? { launcherPath: options.wasmLauncherPath } : {}),
      ...(options.wasmNodePath ? { nodePath: options.wasmNodePath } : {}),
    });
  } else if (selector === 'lean434') {
    const provider = await import('../packages/pskernel-lean/index.mjs');
    const developmentBinary = path.join(
      root,
      'lean-checked/.lake/build/bin/psc2_lean_kernel_provider' + nativeSuffix,
    );
    const slimSourceBinary = path.join(
      root,
      'packages/pskernel-lean/.lake/build/bin/psc2_lean_kernel_provider' + nativeSuffix,
    );
    const binaryPath = options.nativeBinaryPath ??
      process.env.PSC_LEAN_KERNEL_PROVIDER_BIN ??
      (existsSync(developmentBinary) ? developmentBinary : undefined) ??
      (existsSync(slimSourceBinary) ? slimSourceBinary : undefined);
    if (!binaryPath) {
      throw new Error(
        'PSC2_CHECKED_NATIVE_PROVIDER_MISSING: build the current native provider or set PSC_LEAN_KERNEL_PROVIDER_BIN; stale package prebuilts are not used by the default checked profile',
      );
    }
    result = provider.checkCanonicalAdmissions(admissions, {
      timeoutMs,
      binaryPath,
    });
  }

  assertSemanticIdentity(result, selector);
  return Object.freeze({ result, descriptor });
}
