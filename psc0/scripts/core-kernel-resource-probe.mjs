// Diagnose one existing rejected canonical admissions stream at a fixed,
// bounded alternate fuel value. Never participates in build acceptance.
import { existsSync, readFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import path from 'node:path';

const source = process.argv[2] ?? 'dist/diagnostics/core-admissions-rejected.json';
const resolved = path.resolve(source);
if (!existsSync(resolved)) {
  console.log('PSC0_CORE_FUEL_DIAGNOSTIC: no failed admissions corpus available');
  process.exit(0);
}
const input = readFileSync(resolved);
if (input.length > 16 * 1024 * 1024) throw new Error('PSC0_CORE_DIAGNOSTIC_INPUT_TOO_LARGE');
const binary = path.resolve('.lake/build/bin/psc_kernel_core_provider' +
  (process.platform === 'win32' ? '.exe' : ''));
const run = spawnSync(binary, ['--check', '--diagnostic-high-fuel'], {
  input, encoding: 'utf8', timeout: 60000, killSignal: 'SIGKILL',
  windowsHide: true, maxBuffer: 1024 * 1024,
});
if (run.error || run.status !== 0) {
  console.log(JSON.stringify({ kind: 'psc0-core-high-fuel-probe', status: 'transport-failed',
    reason: String(run.error?.code ?? run.signal ?? run.status),
    sha256: createHash('sha256').update(input).digest('hex') }));
  process.exit(0);
}
let result;
try { result = JSON.parse(run.stdout); }
catch { throw new Error('PSC0_CORE_DIAGNOSTIC_INVALID_RESPONSE'); }
if (result.provider !== 'pskernel-core-native' || result.protocol !== 'pskernel-core/1' ||
    typeof result.accepted !== 'boolean') {
  throw new Error('PSC0_CORE_DIAGNOSTIC_WRONG_PROVIDER');
}
console.log(JSON.stringify({ kind: 'psc0-core-high-fuel-probe', fuel: 1048576,
  accepted: result.accepted, errorKind: result.errorKind ?? null,
  declarationIndex: result.declarationIndex ?? null,
  message: typeof result.message === 'string' ? result.message.slice(0, 512) : null,
  sha256: createHash('sha256').update(input).digest('hex'), inputBytes: input.length }));
