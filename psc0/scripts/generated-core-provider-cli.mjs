// Bounded, non-authoritative generated-JS PSKernel Core research runner.
// Reads canonical admissions from stdin and reports a single decision.
// It never falls back to native PSKernel Core or Lean-WASM.
import path from 'node:path';
import { checkGeneratedKernelFile } from './generated-core-provider.mjs';

const [kernelPath, preludePath, mode] = process.argv.slice(2);
if (!kernelPath || !preludePath || !['--check', '--selftest'].includes(mode)) {
  throw new Error('usage: generated-core-provider-cli.mjs <kernel.js> <prelude.json> --check|--selftest');
}
let source = JSON.stringify({ format: 'proofscript-checked-admissions', version: 2, admissions: [] });
if (mode === '--check') {
  source = '';
  let total = 0;
  for await (const chunk of process.stdin) {
    total += Buffer.byteLength(chunk);
    if (total > 16 * 1024 * 1024) throw new Error('PSC0_GENERATED_CORE_INPUT_LIMIT');
    source += chunk.toString();
  }
}
let result;
try {
  result = await checkGeneratedKernelFile(path.resolve(kernelPath), source, path.resolve(preludePath));
  if (!result || typeof result.accepted !== 'boolean') throw new Error('PSC0_GENERATED_CORE_RESULT_SHAPE');
} catch (error) {
  result = { accepted: false, errorKind: 'provider-internal-error',
    message: String(error instanceof Error ? error.message : error).slice(0, 2000) };
}
process.stdout.write(JSON.stringify({
  protocol: 'pskernel-core-generated/1', provider: 'pskernel-core-js-candidate',
  profile: 'lean4.34-core', leanVersion: '4.34.0',
  accepted: result.accepted,
  ...(result.accepted ? { declarationCount: result.declarationCount ?? 0 } :
    { errorKind: result.errorKind ?? 'provider-internal-error',
      message: result.message ?? 'invalid error',
      ...(Number.isSafeInteger(result.declarationIndex) ? { declarationIndex: result.declarationIndex } : {}) }),
}) + '\n');
// Semantic rejections are exit 0; the caller MUST check accepted:boolean.
