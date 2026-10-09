import { existsSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { coreCheckedIdentity } from './checked-kernel-identity.mjs';
import { assertKernelContractDecision } from './kernel-contract.mjs';

export const defaultCoreProviderBinary = fileURLToPath(new URL(
  '../.lake/build/bin/psc_kernel_core_provider' + (process.platform === 'win32' ? '.exe' : ''),
  import.meta.url,
));

export function assertCoreProviderResponse(result) {
  assertKernelContractDecision(result);
  for (const [field, expected] of Object.entries(coreCheckedIdentity)) {
    if (result[field] !== expected) throw new Error(`PSC_KERNEL_CORE_IDENTITY: ${field}`);
  }
  if (result.accepted) {
    if ('errorKind' in result || 'declarationIndex' in result) throw new Error('PSC_KERNEL_CORE_CONTRADICTORY_RESPONSE');
  } else if (typeof result.message !== 'string' || ![
    'protocol-version', 'malformed-request', 'unsupported-core-form', 'prelude-mismatch',
    'provider-version-mismatch', 'kernel-rejection', 'resource-exhausted', 'provider-internal-error',
  ].includes(result.errorKind)) {
    throw new Error('PSC_KERNEL_CORE_INVALID_FAILURE');
  }
  return result;
}

export function checkCoreAdmissions(admissions, {
  binaryPath = process.env.PSC_KERNEL_CORE_PROVIDER_BIN ?? defaultCoreProviderBinary,
  timeoutMs = 60000,
  workingDirectory,
} = {}) {
  if (!Number.isSafeInteger(timeoutMs) || timeoutMs <= 0 || timeoutMs > 60000) {
    throw new Error('PSC_KERNEL_CORE_TIMEOUT_BUDGET: require 1..60000 ms');
  }
  if (!existsSync(binaryPath)) {
    throw new Error('PSC_KERNEL_CORE_PROVIDER_MISSING: build psc_kernel_core_provider or set PSC_KERNEL_CORE_PROVIDER_BIN');
  }
  const run = spawnSync(binaryPath, ['--check'], {
    input: admissions, encoding: 'utf8', windowsHide: true, cwd: workingDirectory,
    timeout: timeoutMs, killSignal: 'SIGKILL', maxBuffer: 16 * 1024 * 1024,
  });
  if (run.error || run.status !== 0) {
    throw new Error(`PSC_KERNEL_CORE_PROCESS_FAILED: ${run.error?.code ?? run.signal ?? run.status}`);
  }
  let result;
  try { result = JSON.parse(run.stdout); }
  catch { throw new Error('PSC_KERNEL_CORE_RESPONSE_INVALID_JSON'); }
  return assertCoreProviderResponse(result);
}
