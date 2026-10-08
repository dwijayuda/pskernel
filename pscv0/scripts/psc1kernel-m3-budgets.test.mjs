import assert from 'node:assert/strict';
import test from 'node:test';
import { assessBudgets, budgets, budgetMarkdown, requireBudgetPass } from './psc1kernel-m3-budgets.mjs';
import { parsePeakRss } from './psc1kernel-measure.mjs';

const identity = { platform: 'linux', arch: 'x64', node: 'v22.23.3' };
const observations = group => Object.fromEntries(Object.entries(budgets[group]).map(([name, bound]) =>
  [name, [bound.limit / 2, bound.limit / 2, bound.limit]]));

test('every declared workload and memory ceiling is enforced for all three samples', () => {
  for (const group of ['native', 'cross']) {
    const accepted = assessBudgets(group, observations(group), identity);
    requireBudgetPass(accepted);
    assert.match(accepted.budgetSha256, /^[a-f0-9]{64}$/);
    assert.match(budgetMarkdown(accepted), /\*\*PASS\*\*/);
    for (const [name, bound] of Object.entries(budgets[group])) {
      const values = observations(group);
      values[name][2] = bound.limit + 0.001;
      const result = assessBudgets(group, values, identity);
      assert.equal(result.passed, false, name);
      assert.throws(() => requireBudgetPass(result), /budget exceeded/);
      assert.match(budgetMarkdown(result), /\*\*FAIL\*\*/);
    }
  }
});

test('a low median cannot hide an over-budget sample', () => {
  const values = observations('cross');
  values['js.admit128'] = [1, 1, 251];
  const result = assessBudgets('cross', values, identity);
  assert.equal(result.checks.find(x => x.name === 'js.admit128').median, 1);
  assert.equal(result.passed, false);
});

test('missing, extra, nonnumeric, and incomplete evidence fails closed', () => {
  for (const mutate of [x => delete x['js.import'], x => x.unexpected = [1, 1, 1],
    x => x['js.import'] = [1, 1], x => x['js.import'] = [1, 1, 1, 1],
    ...[0, -1, NaN, Infinity, '1', null].map(v => x => x['js.import'][0] = v)]) {
    const values = observations('cross'); mutate(values);
    assert.throws(() => assessBudgets('cross', values, identity));
  }
});

test('different execution profiles cannot claim this M3 budget result', () => {
  for (const changed of [{ platform: 'win32' }, { arch: 'arm64' }, { node: 'v26.0.0' }]) {
    assert.throws(() => assessBudgets('native', observations('native'), { ...identity, ...changed }));
  }
});

test('native peak memory must be one positive exact GNU time observation', () => {
  assert.equal(parsePeakRss('PSKERNEL_PEAK_RSS_KIB=1024\n'), 1024);
  for (const value of ['0', '-1', 'NaN', '1.5', '9007199254740992']) {
    assert.throws(() => parsePeakRss(`PSKERNEL_PEAK_RSS_KIB=${value}\n`));
  }
  assert.throws(() => parsePeakRss(''));
  assert.throws(() => parsePeakRss('PSKERNEL_PEAK_RSS_KIB=1024\nextra'));
});
