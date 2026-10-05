import assert from 'node:assert/strict';
import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { checkAdmissionsWithDual } from './checked-kernel-dual.mjs';
import { providerCorpus, envelope } from './pskernel-core-provider-corpus.mjs';

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
const report = { schemaVersion: 1, phase: 'M4', commit: process.env.GITHUB_SHA ?? null,
  defaultAuthorityChanged: false, perProviderTimeoutMs: 10000, totalBudgetMs: 180000,
  elapsedMs: performance.now() - start, caseCount: providerCorpus.length, comparisonCount: records.length, records };
assert(report.elapsedMs <= report.totalBudgetMs);
if (output) {
  await mkdir(path.dirname(path.resolve(output)), { recursive: true });
  await writeFile(output, JSON.stringify(report, null, 2) + '\n');
}
console.log(`M4_PROVIDER_PARITY: PASS ${records.length} comparisons in ${Math.round(report.elapsedMs)}ms`);
