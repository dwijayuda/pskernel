import assert from 'node:assert/strict';
import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { checkAdmissionsWithDual } from './checked-kernel-dual.mjs';
import { checkAdmissionsWithKernel } from './checked-kernel-provider.mjs';
import { providerCorpus, preludeExtensionFixture, envelope } from './pskernel-core-provider-corpus.mjs';

const args = process.argv.slice(2);
const references = args.includes('--native-only') ? ['lean434'] : ['lean434', 'lean434-wasm'];
const outputIndex = args.indexOf('--output');
const output = outputIndex < 0 ? undefined : args[outputIndex + 1];
const start = performance.now();
const records = [];
for (const fixture of providerCorpus) {
  for (const reference of references) {
    if (performance.now() - start > 180000) throw new Error('M4 total parity budget exceeded: 180s');
    const before = performance.now();
    try {
      const checked = await checkAdmissionsWithDual(envelope(fixture.admissions), reference, 'pskernel-core', { timeoutMs: 10000 });
      assert.equal(checked.parity.decision, fixture.expected);
      records.push({ id: fixture.id, reference, elapsedMs: performance.now() - before, ...checked.parity });
      console.log(`M4_PARITY: PASS ${fixture.id} ${reference} ${checked.parity.decision}`);
    } catch (cause) {
      throw new Error(`M4 parity failed: ${fixture.id} / ${reference}: ${cause.message}`, { cause });
    }
  }
}
const extensionSource = envelope(preludeExtensionFixture.admissions);
const extension = await checkAdmissionsWithDual(extensionSource, 'lean434', 'pskernel-core', { timeoutMs: 10000 });
assert.equal(extension.parity.decision, 'accepted');
records.push({ id: preludeExtensionFixture.id, reference: 'lean434', ...extension.parity });
const knownLimitations = [];
if (references.includes('lean434-wasm')) {
  const wasm = await checkAdmissionsWithKernel(extensionSource, 'lean434-wasm', { timeoutMs: 10000 });
  assert.equal(wasm.result.accepted, false, 'WASM extension support changed: review and remove this documented limitation');
  assert.equal(wasm.result.errorKind, 'kernel-rejection');
  assert.equal(wasm.result.declarationIndex, 0);
  assert.match(wasm.result.message, /unknown-constant:UInt8\.ofNat/u);
  await assert.rejects(checkAdmissionsWithDual(extensionSource, 'lean434-wasm', 'pskernel-core', { timeoutMs: 10000 }), /DUAL_CHECK_DISAGREEMENT/);
  knownLimitations.push({ id: preludeExtensionFixture.id,
    reason: 'Bundled WASM predates the declared UInt8.ofNat prelude extension',
    nativeParity: extension.parity, wasmResult: wasm.result, dualMode: 'blocked-disagreement' });
  console.log('M4_KNOWN_LIMITATION: UInt8.ofNat agrees with native Lean; bundled WASM rejects; dual emission blocked');
}
const report = { schemaVersion: 1, phase: 'M4', commit: process.env.GITHUB_SHA ?? null,
  scope: 'common-canonical-admissions-and-current-native-prelude',
  fullCurrentPreludeWasmParity: references.includes('lean434-wasm') ? false : null,
  defaultAuthorityChanged: false, perProviderTimeoutMs: 10000, totalBudgetMs: 180000,
  elapsedMs: performance.now() - start, commonCaseCount: providerCorpus.length,
  currentPreludeExtensionCaseCount: 1, comparisonCount: records.length, records, knownLimitations };
assert(report.elapsedMs <= report.totalBudgetMs);
if (output) {
  await mkdir(path.dirname(path.resolve(output)), { recursive: true });
  await writeFile(output, JSON.stringify(report, null, 2) + '\n');
}
console.log(`M4_PROVIDER_PARITY: PASS ${records.length} comparisons in ${Math.round(report.elapsedMs)}ms`);
