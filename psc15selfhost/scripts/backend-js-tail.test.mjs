import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { mkdtemp, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const root = fileURLToPath(new URL('../', import.meta.url));
const compiler = path.join(root, '.lake/build/bin', process.platform === 'win32' ? 'psc1.exe' : 'psc1');
const staging = await mkdtemp(path.join(tmpdir(), 'psc-js-tail-'));
const options = { cwd: root, encoding: 'utf8', windowsHide: true, timeout: 120000, maxBuffer: 16 * 1024 * 1024 };
async function load(name, source) {
  const file = path.join(staging, `${name}.mjs`);
  await writeFile(file, source);
  return import(pathToFileURL(file).href);
}

try {
  const printed = execFileSync('lake', ['exe', 'psc1_backend_js_diff_fixture', 'tail'], options);
  const fixture = await load('printer', printed);
  for (const name of ['tailAlias', 'tailAliasBeforeBinder', 'tailShadow', 'tailSwap', 'tailClosures', 'matchAliasShadow']) {
    assert(!printed.includes(`function* __ps$impl$${name}(`), `${name} should use the closed loop path`);
  }
  for (const name of ['escapedAlias', 'nonTailShadow', 'stateCollision']) {
    assert(printed.includes(`function* __ps$impl$${name}(`), `${name} should retain the general path`);
  }
  for (const count of [0n, 1n, 2n, 31n, 100000n]) {
    for (const name of ['tailAlias', 'tailAliasBeforeBinder', 'tailShadow'])
      assert.equal(fixture[name](count, 11n), count + 11n);
    assert.equal(fixture.tailSwap(count, 11n, 23n), count % 2n === 0n ? 11n : 23n);
  }
  assert.equal(fixture.ordinaryShadow(41n), 42n);
  assert.equal(fixture.matchAliasShadow(5n, 11n), 18n);
  assert.deepEqual(fixture.tailClosures(5n, []).map(fn => fn()), [5n, 4n, 3n, 2n, 1n]);
  assert.equal(fixture.escapedAlias(20000n, 11n), 20011n);
  assert.equal(fixture.nonTailShadow(20000n, 11n), 40011n);
  assert.equal(fixture.stateCollision(20000n, 11n), 11n);

  // Exercise actual source preparation, erasure, strict validation and JS lowering.
  const source = execFileSync(compiler, ['javascript', 'test/fixtures/selfhost-tail-loop.lean'], options);
  const compiled = await load('source', source);
  for (const name of ['replayTailSwap', 'replayTailReverse', 'replayTailFuel'])
    assert(!source.includes(`function* __ps$impl$${name}(`), `${name} source worker must use a loop`);
  assert(source.includes('function* __ps$impl$replayNonTail('));
  for (const count of [0n, 1n, 31n, 100000n]) {
    assert.equal(compiled.replayTailSwap(count, 11n, 23n), count % 2n === 0n ? 11n : 23n);
    assert.equal(compiled.replayTailFuel(count, 7n), count + 7n);
    assert.equal(compiled.replayEscapedTail(count, 7n), count + 7n);
  }
  assert.equal(compiled.replayNonTail(20000n), 40007n);
  // JsIR constructor tags are a target representation, not TypeScript's namespace API.
  let list = { '$ps$tag': 'nil', '$ps$fields': {} };
  for (let n = 0n; n < 20000n; n++) list = { '$ps$tag': 'cons', '$ps$fields': { head: n, tail: list } };
  let reversed = compiled.replayTailReverse(list, { '$ps$tag': 'nil', '$ps$fields': {} });
  for (let n = 0n; n < 20000n; n++) {
    assert.equal(reversed['$ps$tag'], 'cons');
    assert.equal(reversed['$ps$fields'].head, n);
    reversed = reversed['$ps$fields'].tail;
  }
  assert.equal(reversed['$ps$tag'], 'nil');
  assert.throws(() => compiled.replayTailReverse({}, list), /invalid ProofScript constructor tag/);
  console.log('PSC_BACKEND_JS_TAIL: PASS (actual source workers, simultaneous arguments, frozen captures, let/match shadowing, closures and conservative fallback)');
} finally {
  await rm(staging, { recursive: true, force: true });
}
