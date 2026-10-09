// Independent positive/negative conformance evidence for a generated JS
// PSKernel Core, tested against the actual native PSKernel Core provider.
// This lane uses a previously native-core-checked TypeScript source artifact,
// whose emitted JavaScript was strictly typechecked by pinned TypeScript 7.
// It is never a kernel soundness proof or a substitute checked provider.
import { createHash } from 'node:crypto';
import { existsSync } from 'node:fs';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { providerCorpus, envelope } from './pskernel-core-provider-corpus.mjs';
import { checkCoreAdmissions } from './checked-kernel-core.mjs';
import { checkedKernelIdentity } from './checked-kernel-identity.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const [jsArg, preludeArg, sourceArg, admissionsArg, receiptArg, reportArg] =
  process.argv.slice(2);
if ([jsArg, preludeArg, sourceArg, admissionsArg, receiptArg, reportArg]
  .some(value => !value)) {
  throw new Error('usage: generated-core-differential-corpus.mjs ' +
    '<generated-kernel.js> <prelude.json> <native-checked.ts> ' +
    '<native-checked.admissions.json> <native-checked.checked.json> ' +
    '<typescript7-benchmark-report.json>');
}
const locate = p => path.resolve(root, p);
const paths = [jsArg, preludeArg, sourceArg, admissionsArg, receiptArg, reportArg]
  .map(locate);
const sha256 = data => createHash('sha256').update(data).digest('hex');
const [js, preludeText, ts, admissions, receiptText, reportText] =
  await Promise.all(paths.map(p => readFile(p)));
const receipt = JSON.parse(receiptText.toString('utf8'));
const report = JSON.parse(reportText.toString('utf8'));
const candidateDigest = sha256(js);
const tsDigest = sha256(ts);
const admissionsDigest = sha256(admissions);
const expectedKernel = checkedKernelIdentity('pskernel-core');
if (receipt.kind !== 'psc2-checked-typescript' ||
    receipt.schemaVersion !== 3 ||
    receipt.emission !== 'typescript-only' ||
    receipt.compiler?.engine !== 'native-seed' ||
    receipt.sourceCount !== 79 ||
    receipt.typeScriptSha256 !== tsDigest ||
    receipt.canonicalAdmissionsSha256 !== admissionsDigest ||
    Object.entries(expectedKernel).some(([field, value]) =>
      receipt.provider?.[field] !== value)) {
  throw new Error('PSC0_GENERATED_DIFFERENTIAL_UNCHECKED_SOURCE');
}
if (report.kind !== 'psc0-kernel-transpiler-experiment' ||
    report.authoritative !== false ||
    report.engine !== 'ts7' ||
    report.version !== 'Version 7.0.2' ||
    report.strictTypechecked !== true ||
    report.pass !== true ||
    report.sourceSha256 !== tsDigest ||
    report.canonicalAdmissionsSha256 !== admissionsDigest ||
    report.javaScriptSha256 !== candidateDigest) {
  throw new Error('PSC0_GENERATED_DIFFERENTIAL_UNVERIFIED_JS');
}
const prelude = JSON.parse(preludeText.toString('utf8'));
if (!Array.isArray(prelude) || prelude.length === 0 ||
    prelude.length > 4096 || prelude.some(v => !v.nameWire ||
      !Array.isArray(v.levelParameterWires))) {
  throw new Error('PSC0_GENERATED_DIFFERENTIAL_INVALID_PRELUDE');
}
const name = p => path.relative(root, p).replaceAll(path.sep, '/');
const results = [];
const started = process.hrtime.bigint();
for (const fixture of providerCorpus) {
  const wire = envelope(fixture.admissions);
  const expectedAccepted = fixture.expected === 'accepted';
  const expectedIndex = expectedAccepted ? null :
    Number(fixture.expected.slice('rejected:'.length));
  if (!expectedAccepted && !Number.isSafeInteger(expectedIndex)) {
    throw new Error('PSC0_GENERATED_DIFFERENTIAL_INVALID_FIXTURE: ' + fixture.id);
  }
  const native = checkCoreAdmissions(wire, { timeoutMs: 120000 });
  if (native.accepted !== expectedAccepted ||
      (expectedIndex !== null && native.declarationIndex !== expectedIndex)) {
    throw new Error('PSC0_GENERATED_DIFFERENTIAL_NATIVE_CORPUS_DRIFT: ' + fixture.id +
      ' result=' + JSON.stringify(native));
  }
  const subprocess = spawnSync(process.execPath, [
    'scripts/generated-core-provider-cli.mjs', name(paths[0]), name(paths[1]), '--check',
  ], { cwd: root, input: wire, encoding: 'utf8',
    timeout: 300000, maxBuffer: 4 * 1024 * 1024, windowsHide: true,
    env: { ...process.env, NODE_OPTIONS: '--max-old-space-size=6144' } });
  if (subprocess.error || subprocess.status !== 0) {
    throw new Error('PSC0_GENERATED_DIFFERENTIAL_PROCESS: ' + fixture.id +
      ' result=' + String(subprocess.error?.code ?? subprocess.signal ?? subprocess.status) +
      ' stderr=' + String(subprocess.stderr).slice(-300));
  }
  let generated;
  try { generated = JSON.parse(subprocess.stdout); }
  catch { throw new Error('PSC0_GENERATED_DIFFERENTIAL_BAD_RESPONSE: ' + fixture.id); }
  if (generated.protocol !== 'pskernel-core-generated/1' ||
      generated.provider !== 'pskernel-core-js-candidate' ||
      generated.leanVersion !== expectedKernel.leanVersion ||
      generated.profile !== expectedKernel.profile ||
      typeof generated.accepted !== 'boolean') {
    throw new Error('PSC0_GENERATED_DIFFERENTIAL_IDENTITY_MISMATCH: ' + fixture.id);
  }
  if (generated.accepted !== expectedAccepted ||
      (expectedIndex !== null && generated.declarationIndex !== expectedIndex)) {
    throw new Error('PSC0_GENERATED_DIFFERENTIAL_DECISION_MISMATCH: ' + fixture.id +
      ' expected=' + fixture.expected + ' native=' + JSON.stringify(native) +
      ' generated=' + JSON.stringify(generated));
  }
  if (!expectedAccepted && ['provider-internal-error', 'resource-exhausted'].includes(generated.errorKind)) {
    throw new Error('PSC0_GENERATED_DIFFERENTIAL_INCONCLUSIVE_REJECTION: ' +
      fixture.id + ' ' + generated.errorKind + ' ' + generated.message);
  }
  results.push({
    fixture: fixture.id, expected: fixture.expected,
    accepted: generated.accepted,
    ...(!expectedAccepted ? {
      nativeErrorKind: native.errorKind,
      generatedErrorKind: generated.errorKind,
      nativeIndex: native.declarationIndex,
      generatedIndex: generated.declarationIndex,
    } : {}),
  });
  console.log('PSC0_GENERATED_CORE_CORPUS_CASE: PASS ' + fixture.id +
    ' expected=' + fixture.expected);
}
const reportFile = path.join(root,
  'dist/joint-kernel/generated-core-differential-corpus.json');
const finished = {
  schemaVersion: 1, kind: 'psc0-generated-core-differential-experiment',
  authority: 'non-authoritative-conformance',
  sourceCount: receipt.sourceCount,
  sourceTypeScriptSha256: tsDigest,
  canonicalAdmissionsSha256: admissionsDigest,
  generatedJavaScriptSha256: candidateDigest,
  checkedPreludeSha256: sha256(preludeText),
  toolchain: { package: 'typescript', version: '7.0.2',
    profile: 'strict-es2022-esm-ignoreconfig/1' },
  nativeKernel: expectedKernel, caseCount: results.length,
  elapsedSeconds: Number((Number(process.hrtime.bigint() - started) / 1e9).toFixed(3)),
  results, generatedCheckerAdmitsCompiler: false, jointCheckerFixedPoint: false,
};
await mkdir(path.dirname(reportFile), { recursive: true });
await writeFile(reportFile, JSON.stringify(finished, null, 2) + '\n');
console.log('PSC0_GENERATED_CORE_DIFFERENTIAL_CORPUS: PASS cases=' + results.length +
  ' toolchain=TypeScript-7.0.2 (NOT kernel soundness, NOT full joint self-host)');
