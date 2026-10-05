import assert from 'node:assert/strict';
import { test } from 'node:test';
import { execFileSync, spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { readdirSync } from 'node:fs';
import path from 'node:path';

const root = fileURLToPath(new URL('../packages/pskernel-core.old3/', import.meta.url));
test('regenerated owned kernel has matching build/evidence identities and owns bootstrap routing', () => {
  execFileSync(process.execPath, [fileURLToPath(new URL('./check-owned-kernel-receipt.mjs', import.meta.url))]);
});
test('owned checker full discovered test corpus passes without regressions', {
  // The unchanged receipt includes POSIX executable-bit and symlink tests.
  skip: process.platform === 'win32' ? 'full receipt baseline requires POSIX filesystem semantics' : false,
}, () => {
  const tests = readdirSync(path.join(root, 'test')).filter(name => name.endsWith('.test.mjs')).sort();
  const { NODE_TEST_CONTEXT: _nestedRunner, ...env } = process.env;
  const run = spawnSync(process.execPath, ['--test', '--test-reporter=tap', ...tests.map(name => path.join('test', name))], {
    cwd: root, env, encoding: 'utf8', timeout: 600000, maxBuffer: 8 * 1024 * 1024,
  });
  assert.equal(run.status, 0, `${run.error ?? ''}\n${run.stdout}\n${run.stderr}`);
  const output = run.stdout;
  const testsMatch = output.match(/# tests (\d+)\b/u);
  const passMatch = output.match(/# pass (\d+)\b/u);
  assert.notEqual(testsMatch, null, output);
  assert.notEqual(passMatch, null, output);
  const total = Number(testsMatch[1]);
  const passed = Number(passMatch[1]);
  assert(Number.isInteger(total) && total > 0, output);
  assert.equal(passed, total, output);
  assert.match(output, /# fail 0\b/u);
  assert.match(output, /# skipped 0\b/u);
});
test('owned kernel release remains blocked until promotion gates pass', () => {
  const result = spawnSync(process.execPath, ['scripts/release-check.mjs'], {cwd: root, encoding: 'utf8', timeout: 10000});
  assert.equal(result.status, 1, result.stderr);
  const report = JSON.parse(result.stdout);
  assert.equal(report.releaseReady, false);
  assert(report.blockers.includes('INCOMPLETE_GATE:compiler-kernel-closure'));
  assert(report.blockers.includes('INCOMPLETE_GATE:generated-kernel-fixed-point'));
});
