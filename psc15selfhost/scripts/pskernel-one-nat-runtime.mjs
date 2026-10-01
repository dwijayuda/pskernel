import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath, pathToFileURL} from 'node:url';
import {spawnSync} from 'node:child_process';
import {createHash} from 'node:crypto';
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
const fromLean = command(psc, ['typescript', source]);
const canonical = path.join(out, 'fixture.ps');
command(psc, ['translate', source, '--to', 'ps', '--out', canonical]);
command(psc, ['check', canonical]);
const fromPS = command(psc, ['typescript', canonical]);
assert.equal(fromPS, fromLean, 'Canonical PS and Lean must emit identical TypeScript');
fs.writeFileSync(ts, fromPS);
function compile(ts) {
  command(process.env.TSC ?? 'npx', process.env.TSC
    ? [ts, '--target', 'ES2022', '--module', 'ES2022', '--strict', '--noEmitOnError']
    : ['--no-install', 'tsc', ts, '--target', 'ES2022', '--module', 'ES2022', '--strict', '--noEmitOnError']);
}
compile(ts);
const m = await import(pathToFileURL(path.join(out, 'fixture.js')));
for (let n = 0n; n <= 32n; n++) {
  assert.equal(m.oneNatIdentity(n), n);
  assert.equal(m.oneNatSum(n), n * (n - 1n) / 2n);
  assert.equal(m.oneNatCaptured(7n, n), 7n * (n + 1n));
  assert.equal(m.oneNatLarge(9007199254740993n, n), 9007199254740993n + n);
}
assert.equal(m.oneNatIdentity(10000n), 10000n);
compile(path.join(out, 'direct.ts'));
const direct = await import(pathToFileURL(path.join(out, 'direct.js')));
assert.equal(direct.nestedNatRec, 110n);
const sha = file => createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const files = [source, canonical, ts, path.join(out, 'fixture.js'), path.join(out, 'direct.ts'), path.join(out, 'direct.js')];
fs.writeFileSync(path.join(out, 'results.json'), JSON.stringify({schema: 'pskernel-one-nat-runtime/1',
  results: 134, compilerSha256: sha(psc), node: process.version,
  typescript: command(process.env.TSC ?? 'npx', process.env.TSC ? ['--version'] : ['--no-install', 'tsc', '--version']).trim(),
  artifacts: files.map(file => ({path: path.relative(root, file), sha256: sha(file), bytes: fs.statSync(file).size}))}, null, 2) + '\n');
console.log('PSKERNEL_ONE_NAT_RUNTIME: PASS (134 generated results, bigint, captured arguments, nested recursor)');
