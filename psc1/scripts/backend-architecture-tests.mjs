// Focused direct planning/publication regression. Run in Linux cloud CI only.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { fileURLToPath, pathToFileURL } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const native = process.env.PSC1_NATIVE || path.join(root, '.lake/build/bin/psc1');
const work = fs.mkdtempSync(path.join(os.tmpdir(), 'psc1-backend-architecture-'));
const env = { ...process.env, PSC1_HOST_TOOLS: path.join(root, 'host-tools/artifacts.mjs') };
const records = [];
const digest = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const command = (cmd, args, options = {}) => {
  const result = spawnSync(cmd, args, { env, encoding: 'utf8', timeout: 120000, ...options });
  assert.equal(result.error, undefined, result.error?.message);
  assert.equal(result.status, 0, result.stdout + result.stderr);
  return result.stdout;
};
const reject = (args, pattern, options = {}) => {
  const result = spawnSync(native, args, { env, encoding: 'utf8', timeout: 120000, ...options });
  assert.notEqual(result.status, 0);
  assert.match(result.stdout + result.stderr, pattern);
};
const read = file => fs.readFileSync(file, 'utf8');
try {
  fs.writeFileSync(path.join(work, 'package.json'), '{"type":"module"}\n');
  const input = path.join(work, 'main.lean');
  const source = 'def negate (value : Bool) : Bool := if value then false else true\n';
  fs.writeFileSync(input, source);
  const out = path.join(work, 'out');
  const args = ['build', input, '--targets', 'ts,js', '--out-dir', out];
  command(native, args);
  const stem = path.join(out, 'main');
  const receipt = stem + '.ecma.bundle.json';
  const manifest = JSON.parse(read(receipt));
  assert.equal(manifest.target, 'ecma');
  assert.deepEqual(manifest.targets, ['ts', 'js']);
  assert.equal(manifest.sharedCheckedInput, true);
  assert.deepEqual(manifest.publicNames, ['negate']);
  assert.equal(manifest.logicalCheckerCommit, 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
  assert.equal(manifest.behaviorallyVerified, false);
  for (const extension of ['.js', '.ts', '.d.ts', '.js.map', '.ts.map']) {
    assert.ok(fs.statSync(stem + extension).size > 0, extension);
  }
  for (const extension of ['.js', '.ts']) {
    assert.doesNotMatch(read(stem + extension), /__ps\$(run|utf8|implementations)/);
    assert.match(read(stem + extension), /function negate/);
  }
  const js = await import(pathToFileURL(stem + '.js').href);
  assert.deepEqual(Object.keys(js), ['negate']);
  assert.equal(js.negate(true), false);
  assert.equal(js.negate(false), true);
  const checker = process.env.PSC1_TSC;
  assert.ok(checker, 'the separate TypeScript consumer checker must be installed for this test');
  const consumer = path.join(work, 'consumer');
  command(process.execPath, [checker, '--ignoreConfig', stem + '.ts', '--target', 'ES2020', '--module', 'ES2022',
    '--strict', '--skipLibCheck', '--outDir', consumer]);
  const ts = await import(pathToFileURL(path.join(consumer, 'main.js')).href);
  assert.equal(ts.negate(true), false);
  assert.equal(ts.negate(false), true);
  for (const extension of ['.js', '.ts']) {
    const map = JSON.parse(read(stem + extension + '.map'));
    assert.equal(map.version, 3);
    assert.equal(map.file, 'main' + extension);
    assert.ok(map.sources.some(file => file.endsWith('main.lean')));
    assert.ok(map.sourcesContent.includes(source));
  }
  records.push({ group: 'one-admission-independent-ts-js', passed: true,
    jsBytes: fs.statSync(stem + '.js').size, tsBytes: fs.statSync(stem + '.ts').size });

  const before = read(receipt);
  const files = ['.js', '.ts', '.d.ts', '.js.map', '.ts.map'].map(ext => [stem + ext, read(stem + ext)]);
  command(native, args);
  assert.equal(read(receipt), before, 'same inputs produce identical generation');
  fs.writeFileSync(input, 'def negate (value : Bool) : Bool := value\n');
  reject(args, /PSC1_INJECTED_PUBLICATION_FAILURE/, {
    env: { ...env, PSC1_TEST_PUBLICATION_FAIL_AT: 'before-commit' }
  });
  assert.equal(read(receipt), before);
  for (const [file, content] of files) assert.equal(read(file), content);
  fs.writeFileSync(input, 'def bad : Nat := true\n');
  reject(args, /PSC1_|PSC2_/);
  assert.equal(read(receipt), before);
  for (const [file, content] of files) assert.equal(read(file), content);
  records.push({ group: 'atomic-pair-failure-preservation-and-determinism', passed: true });

  reject(['build', input, '--targets', 'js,js', '--out-dir', path.join(work, 'duplicate')],
    /PSC1_TARGET_SET_UNSUPPORTED/);
  reject(['build', input, '--assurance', 'verified', '--targets', 'ts,js', '--out-dir', out],
    /PSC1_VERIFIED_EXECUTION_UNAVAILABLE/);
  assert.equal(read(receipt), before);
  records.push({ group: 'combined-request-negative-boundaries', passed: true });

  const evidence = path.join(root, 'dist/scoped-correctness/backend-architecture');
  fs.mkdirSync(evidence, { recursive: true });
  fs.cpSync(path.dirname(fs.realpathSync(receipt)), path.join(evidence, 'boolean-ts-js'),
    { recursive: true });
  fs.writeFileSync(path.join(evidence, 'results.json'), JSON.stringify({
    schema: 'psc1-backend-architecture-execution/1',
    commit: process.env.GITHUB_SHA || null, node: process.version, records,
    manifestSha256: digest(before)
  }, null, 2) + '\n');
  for (const record of records) console.log('PSC1_BACKEND_ARCHITECTURE_PASS: ' + record.group);
} finally {
  fs.rmSync(work, { recursive: true, force: true });
}
