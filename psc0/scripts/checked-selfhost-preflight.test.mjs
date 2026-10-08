import assert from 'node:assert/strict';
import test from 'node:test';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

test('checked bootstrap runs the real PSC1 project preflight before the checked seed session', async () => {
  const source = await readFile(path.join(root, 'scripts/checked-selfhost.mjs'), 'utf8');
  const bootstrap = source.match(
    /async function bootstrap\(kernel, fast = false\) \{[\s\S]*?(?=\nasync function next\b)/,
  )?.[0];
  assert.ok(bootstrap, 'bootstrap function missing');

  const lean = bootstrap.indexOf("runNpm(['run', 'bootstrap:lean']);");
  const preflight = bootstrap.indexOf("runNpm(['run', 'bootstrap:check']);");
  const providerBuild = bootstrap.indexOf("run('lake', ['build', 'psc_kernel_core_provider'], root);");
  const checkedSeed = bootstrap.indexOf('await buildChecked({');

  assert.ok(preflight >= 0, 'bootstrap:check missing');
  assert.ok(lean > preflight, 'bootstrap:lean must follow parser preflight');
  assert.ok(providerBuild > lean, 'native core build must follow full bootstrap suite');
  assert.ok(checkedSeed > providerBuild, 'native core build must precede checked seed');
});

test('checked bootstrap preflight is fail-closed, not advisory', async () => {
  const source = await readFile(path.join(root, 'scripts/checked-selfhost.mjs'), 'utf8');
  assert.match(
    source,
    /function run\([\s\S]*?if \(result\.status !== 0\) throw new Error\(`PSC2_CHECKED_STEP_FAILED:/,
  );
});
