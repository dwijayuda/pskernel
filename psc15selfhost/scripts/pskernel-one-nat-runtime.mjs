import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath, pathToFileURL} from 'node:url';
import {spawnSync} from 'node:child_process';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const out = path.join(root, 'dist/pskernel-one/nat');
fs.mkdirSync(out, {recursive: true});
const psc = process.env.PSC1 ?? path.join(root, '.lake/build/bin/psc1');
const source = path.join(root, 'packages/pskernel-one/test/NatRecFixture.lean');
function command(bin, args) {
  const r = spawnSync(bin, args, {cwd: root, encoding: 'utf8', timeout: 120000});
  if (r.status !== 0) throw new Error(`${bin}: ${r.stdout}\n${r.stderr}`);
  return r.stdout;
}
command(psc, ['check', source]);
const ts = path.join(out, 'fixture.ts');
fs.writeFileSync(ts, command(psc, ['typescript', source]));
command(process.env.TSC ?? 'npx', process.env.TSC
  ? [ts, '--target', 'ES2022', '--module', 'ES2022', '--strict', '--noEmitOnError']
  : ['--no-install', 'tsc', ts, '--target', 'ES2022', '--module', 'ES2022', '--strict', '--noEmitOnError']);
const m = await import(pathToFileURL(path.join(out, 'fixture.js')));
for (let n = 0n; n <= 32n; n++) {
  assert.equal(m.oneNatIdentity(n), n);
  assert.equal(m.oneNatSum(n), n * (n - 1n) / 2n);
  assert.equal(m.oneNatCaptured(7n, n), 7n * (n + 1n));
  assert.equal(m.oneNatLarge(9007199254740993n, n), 9007199254740993n + n);
}
assert.equal(m.oneNatIdentity(10000n), 10000n);
console.log('PSKERNEL_ONE_NAT_RUNTIME: PASS (133 generated results, bigint and captured arguments)');
