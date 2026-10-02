import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { mkdtemp, writeFile, rm } from 'node:fs/promises';
import { createRequire } from 'node:module';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const require = createRequire(import.meta.url);
const tsc = require.resolve('typescript/bin/tsc');
const compiler = path.join(root, '.lake/build/bin', process.platform === 'win32' ? 'psc1.exe' : 'psc1');
const staging = await mkdtemp(path.join(tmpdir(), 'psc2-replay-runtime-'));
try {
  for (const fixture of ['selfhost-nat-recursion', 'selfhost-int-repr']) {
    const source = execFileSync(compiler, ['typescript', `test/fixtures/${fixture}.lean`], {
      cwd: root, encoding: 'utf8', timeout: 120000, maxBuffer: 8 * 1024 * 1024,
    });
    const input = path.join(staging, `${fixture}.ts`);
    await writeFile(input, source);
    execFileSync(process.execPath, [tsc, input, '--strict', '--target', 'ES2022', '--module', 'commonjs'], {
      encoding: 'utf8', timeout: 120000,
    });
    const compiled = require(path.join(staging, `${fixture}.js`));
    if (fixture === 'selfhost-nat-recursion') {
      for (const n of [0n, 1n, 2n, 8n, 100n]) {
        assert.equal(compiled.replayNatCase(n), n === 0n ? 7n : n - 1n);
        assert.equal(compiled.replayNatSum(n), n * (n + 1n) / 2n);
        assert.equal(compiled.replayNatSuccessor(n), n + 1n);
      }
    } else {
      for (const n of [0n, 1n, -1n, 9007199254740993n, -9007199254740993n,
        123456789012345678901234567890n, -123456789012345678901234567890n]) {
        assert.equal(compiled.renderInt(n), n.toString());
      }
    }
  }
  console.log('PSC2_SELFHOST_REPLAY_RUNTIME: PASS (strict TypeScript compilation and executed Nat recursion / arbitrary precision Int printing)');
} finally {
  await rm(staging, { recursive: true, force: true });
}
