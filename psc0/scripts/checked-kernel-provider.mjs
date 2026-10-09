import { accessSync, constants, existsSync, readFileSync, realpathSync, statSync } from 'node:fs';
import { createHash } from 'node:crypto';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { checkedKernelIdentity, coreCheckedIdentity } from './checked-kernel-identity.mjs';
import { checkCoreAdmissions, defaultCoreProviderBinary } from './checked-kernel-core.mjs';
import { assertCanonicalAdmissionsEnvelope, kernelContractV1 } from './kernel-contract.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const nativeSuffix = process.platform === 'win32' ? '.exe' : '';
const hash = bytes => createHash('sha256').update(bytes).digest('hex');

export const defaultCheckedKernel = 'pskernel-core';
export const checkedKernelSelectors = Object.freeze(['pskernel-core', 'lean434-wasm', 'lean434']);

// This pin identifies the unchanged PR84 provider independently of the local
// kernel source. PR89's Lean 4.35 Arena replay binary has a different protocol.
export const coreNativeArtifactPins = Object.freeze({
  'linux-x64': Object.freeze({
    expectedBinarySha256: '88f2d20ea733742d48724ecbdc903271e18bcfcccc8682be596a676aef68e3ec',
    dependencies: Object.freeze([]),
    verificationRun: 37925722635,
  }),
  'win32-x64': Object.freeze({
    expectedBinarySha256: '8264a5e8551a1040d81956fa5b2a7f429355b365df06b9b705e20df8640419e2',
    dependencies: Object.freeze([]),
    verificationRun: 37993071033,
  }),
});

const descriptors = Object.freeze({
  'pskernel-core': Object.freeze({
    selector: 'pskernel-core', package: '@proofscript/pskernel-core',
    execution: 'native', ...coreCheckedIdentity,
    sourceCommit: '963030dc2d154008fccc82e7c8ed29331f138799',
    sourceTree: '38c8c55bd2b214753e56c58c15c4901c32c01b86',
    sourceTreePath: 'psc0',
    repositoryTree: '80927150cbd6a5518762b4cc56e51ea24df8f374',
    kernelContract: kernelContractV1.id,
    contractSha256: kernelContractV1.sha256,
    resourcePolicy: Object.freeze({ fuel: 131072, maxTimeoutMs: 60000 }),
  }),
  'lean434-wasm': Object.freeze({
    selector: 'lean434-wasm',
    package: '@proofscript/pskernel-lean-wasm',
    execution: 'wasm-node',
    sourceCommit: '1b21b2483df7e8de7542873c24eaff2501539b1b',
    verificationRun: 37014379617,
  }),
  lean434: Object.freeze({
    selector: 'lean434',
    package: '@proofscript/pskernel-lean',
    execution: 'native',
    sourceCommit: '88b18bbcec82bad02cb3db8ee5b5b96cae91ae86',
    verificationRun: 36522373312,
  }),
});

export function checkedKernelDescriptor(selector = defaultCheckedKernel) {
  if (!Object.hasOwn(descriptors, selector)) {
    throw new Error('PSC2_CHECKED_KERNEL_UNSUPPORTED: ' + selector);
  }
  if (selector === 'pskernel-core') {
    const key = process.platform + '-' + process.arch;
    if (!Object.hasOwn(coreNativeArtifactPins, key)) {
      throw new Error('PSC0_KERNEL_CORE_PLATFORM: qualified native artifacts are linux/x64 and win32/x64');
    }
    return Object.freeze({
      ...descriptors[selector], ...coreNativeArtifactPins[key],
      platform: process.platform, architecture: process.arch,
    });
  }
  return descriptors[selector];
}

function assertSemanticIdentity(result, selector) {
  for (const [field, expected] of Object.entries(checkedKernelIdentity(selector))) {
    if (result?.[field] !== expected) {
      throw new Error('PSC2_CHECKED_PROVIDER_IDENTITY: ' + field);
    }
  }
  if (typeof result?.accepted !== 'boolean') {
    throw new Error('PSC2_CHECKED_PROVIDER_RESULT');
  }
}

function bindCoreBinary(configuredPath) {
  if (typeof configuredPath !== 'string' || !path.isAbsolute(configuredPath)) {
    throw new Error('PSC0_KERNEL_CORE_PATH: require an absolute supervisor or release path');
  }
  const expected = checkedKernelDescriptor('pskernel-core');
  let binaryPath;
  let binarySha256;
  try {
    binaryPath = realpathSync(configuredPath);
    if (!statSync(binaryPath).isFile()) throw new Error('Provider must be a regular file');
    accessSync(binaryPath, constants.R_OK | constants.X_OK);
    binarySha256 = hash(readFileSync(binaryPath));
  } catch (cause) {
    throw new Error('PSC0_KERNEL_CORE_ARTIFACT_UNAVAILABLE', { cause });
  }
  if (binarySha256 !== expected.expectedBinarySha256) {
    throw new Error('PSC0_KERNEL_CORE_ARTIFACT_MISMATCH: ' + binarySha256);
  }
  return Object.freeze({ binaryPath, binarySha256, runtimeDependencies: expected.dependencies });
}

/**
 * Host-only provider selection. The supervisor/release supplies nativeBinaryPath;
 * project and extension messages must never supply options or provider code.
 * Keep the executable and its installation outside extension-writable paths.
 */
export async function checkAdmissionsWithKernel(
  admissions,
  selector = defaultCheckedKernel,
  options = {},
) {
  if (typeof admissions !== 'string') throw new TypeError('Expected canonical admissions text');
  let descriptor = checkedKernelDescriptor(selector);
  const timeoutMs = options.timeoutMs ?? 60000;
  let result;

  if (selector === 'pskernel-core') {
    assertCanonicalAdmissionsEnvelope(admissions);
    // Passing the path explicitly prevents the unchanged historical transport
    // from consulting PSC_KERNEL_CORE_PROVIDER_BIN or searching project paths.
    const binding = bindCoreBinary(options.nativeBinaryPath ?? defaultCoreProviderBinary);
    // Keep the native child's working directory outside the caller project.
    result = checkCoreAdmissions(admissions, {
      binaryPath: binding.binaryPath, timeoutMs,
      workingDirectory: path.dirname(binding.binaryPath),
    });
    // A changed or unavailable artifact cannot yield a retained checked receipt.
    const after = bindCoreBinary(binding.binaryPath);
    if (after.binaryPath !== binding.binaryPath || after.binarySha256 !== binding.binarySha256) {
      throw new Error('PSC0_KERNEL_CORE_ARTIFACT_CHANGED');
    }
    descriptor = Object.freeze({
      ...descriptor, ...binding, canonicalAdmissionsSha256: hash(Buffer.from(admissions, 'utf8')),
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
    const binaryPath = options.nativeBinaryPath ?? (
      !process.env.PSC_LEAN_KERNEL_PROVIDER_BIN && existsSync(developmentBinary)
        ? developmentBinary
        : undefined
    );
    result = provider.checkCanonicalAdmissions(admissions, {
      timeoutMs,
      ...(binaryPath ? { binaryPath } : {}),
    });
  }

  assertSemanticIdentity(result, selector);
  return Object.freeze({ result: Object.freeze(result), descriptor });
}
