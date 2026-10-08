import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import os from 'node:os';

const bytes = readFileSync(new URL('../packages/pskernel-core/M3_WORKLOAD_BUDGETS.json', import.meta.url));
export const budgets = JSON.parse(bytes);
export function benchmarkIdentity() {
  return { platform: process.platform, arch: process.arch, node: process.version,
    cpu: os.cpus()[0]?.model, kernel: os.release(),
    runnerImage: process.env.ImageOS ?? null, runnerImageVersion: process.env.ImageVersion ?? null };
}
export function assessBudgets(group, observations, identity = benchmarkIdentity()) {
  assert.equal(budgets.schemaVersion, 1);
  assert.equal(identity.platform, 'linux', 'M3 evidence requires Linux');
  assert.equal(identity.arch, 'x64', 'M3 evidence requires x64');
  assert.match(identity.node, /^v22\./, 'M3 evidence requires Node 22');
  assert.ok(group === 'native' || group === 'cross');
  const limits = budgets[group];
  assert.deepEqual(Object.keys(observations).sort(), Object.keys(limits).sort(), 'Incomplete M3 observations');
  const checks = Object.entries(limits).map(([name, bound]) => {
    assert.ok(['ms', 'MiB'].includes(bound.unit) && Number.isFinite(bound.limit) && bound.limit > 0);
    const values = observations[name];
    assert.ok(Array.isArray(values) && values.length === budgets.samples, `${name}: require three samples`);
    assert.ok(values.every(x => Number.isFinite(x) && x > 0), `${name}: missing/invalid measurement`);
    const sorted = [...values].sort((a, b) => a - b);
    return { name, ...bound, median: sorted[1], max: sorted.at(-1), min: sorted[0],
      passed: sorted.at(-1) <= bound.limit };
  });
  return { profile: budgets.profile, budgetSha256: createHash('sha256').update(bytes).digest('hex'),
    group, identity, sampleCount: budgets.samples, checks, passed: checks.every(x => x.passed) };
}
export function budgetMarkdown(result) {
  return [`M3 ${result.group} budgets: **${result.passed ? 'PASS' : 'FAIL'}** (${result.profile}).`, '',
    '| Measurement | Median | Maximum | Ceiling | Result |', '| --- | ---: | ---: | ---: | --- |',
    ...result.checks.map(x => `| ${x.name} (${x.unit}) | ${x.median.toFixed(3)} | ${x.max.toFixed(3)} | ${x.limit} | ${x.passed ? 'PASS' : 'FAIL'} |`), '',
    'Each of three samples must meet the ceiling. These limits cover the named small fixtures, not arbitrary input, browser execution or provider promotion.', ''].join('\n');
}
export function requireBudgetPass(result) {
  assert.ok(result.passed, `M3 budget exceeded: ${result.checks.filter(x => !x.passed).map(x => x.name).join(', ')}`);
}
