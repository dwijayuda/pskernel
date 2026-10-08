import assert from 'node:assert/strict';
import './native-workspace-isolation.test.mjs';
import './native-typescript-cli.test.mjs';
import { execFileSync } from 'node:child_process';
import { mkdtemp, writeFile, rm } from 'node:fs/promises';
import { createRequire } from 'node:module';
import { assertPinnedTypeScriptCli } from './typescript-cli.mjs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const require = createRequire(import.meta.url);
const tsc = assertPinnedTypeScriptCli();
const compiler = path.join(root, '.lake/build/bin', process.platform === 'win32' ? 'psc1.exe' : 'psc1');
const staging = await mkdtemp(path.join(tmpdir(), 'psc2-replay-runtime-'));
try {
  for (const fixture of ['selfhost-nat-recursion', 'selfhost-int-repr', 'selfhost-function-results', 'selfhost-text-position', 'selfhost-count-fold', 'selfhost-tail-loop']) {
    const source = execFileSync(compiler, ['typescript', `test/fixtures/${fixture}.lean`], {
      cwd: root, encoding: 'utf8', timeout: 120000, maxBuffer: 8 * 1024 * 1024,
    });
    const input = path.join(staging, `${fixture}.ts`);
    await writeFile(input, source);
    execFileSync(process.execPath, [tsc, input, '--ignoreConfig', '--strict', '--target', 'ES2022', '--module', 'commonjs'], {
      encoding: 'utf8', timeout: 120000,
    });
    const compiled = require(path.join(staging, `${fixture}.js`));
    if (fixture === 'selfhost-tail-loop') {
      for (const name of ['replayTailSwap', 'replayTailReverse', 'replayTailFuel'])
        assert(!source.includes(`__ps$impl$${name}`), `${name} must use a bounded tail loop`);
      assert(source.includes('__ps$impl$replayNonTail'), 'non-tail recursion must keep the general path');
      for (const n of [0n, 1n, 2n, 31n, 20000n]) {
        assert.equal(compiled.replayTailSwap(n, 11n, 23n), n % 2n === 0n ? 11n : 23n);
        assert.equal(compiled.replayTailFuel(n, 7n), n + 7n);
        assert.equal(compiled.replayEscapedTail(n, 7n), n + 7n);
        assert.equal(compiled.replayNonTail(n), 2n * n + 7n);
      }
      let list = compiled.List.nil();
      for (let n = 0n; n < 20000n; n++) list = compiled.List.cons(n, list);
      let reversed = compiled.replayTailReverse(list, compiled.List.nil());
      for (let n = 0n; n < 20000n; n++) { assert.equal(reversed.head, n); reversed = reversed.tail; }
      assert.equal(Object.keys(reversed).length, 0);
      assert.throws(() => compiled.replayTailReverse({}, compiled.List.nil()), /invalid ProofScript constructor tag/);
    } else if (fixture === 'selfhost-count-fold') {
      for (const name of ['countRenamed', 'countSuccessor']) {
        assert(source.includes(`export function ${name}`));
        assert(!source.includes(`__ps$impl$${name}`), `${name} must use the structural count loop`);
      }
      for (const name of ['offsetCount', 'doubleCount', 'headSum'])
        assert(source.includes(`__ps$impl$${name}`), `${name} must retain its distinct semantics`);
      for (const count of [0, 1, 31, 20000]) {
        let values = compiled.List.nil();
        for (let index = 0; index < count; index++) values = compiled.List.cons(7n, values);
        assert.equal(compiled.countRenamed(values), BigInt(count));
        assert.equal(compiled.countSuccessor(values), BigInt(count));
        assert.equal(compiled.offsetCount(values), BigInt(count + 1));
        assert.equal(compiled.doubleCount(values), BigInt(count * 2));
        assert.equal(compiled.headSum(values), BigInt(count * 7));
      }
    } else if (fixture === 'selfhost-nat-recursion') {
      for (const n of [0n, 1n, 2n, 8n, 100n]) {
        assert.equal(compiled.replayNatCase(n), n === 0n ? 7n : n - 1n);
        assert.equal(compiled.replayNatSum(n), n * (n + 1n) / 2n);
        assert.equal(compiled.replayNatSuccessor(n), n + 1n);
      }
      assert.equal(compiled.replayNatSum(20000n), 200010000n);
    } else if (fixture === 'selfhost-int-repr') {
      for (const n of [0n, 1n, -1n, 9007199254740993n, -9007199254740993n,
        123456789012345678901234567890n, -123456789012345678901234567890n]) {
        assert.equal(compiled.renderInt(n), n.toString());
      }
    } else if (fixture === 'selfhost-text-position') {
      for (const text of ['', 'abc', 'Aé中😀Z', '\u0000é\n', 'a'.repeat(30000) + '😀']) {
        const positions = new Map();
        let size = 0n;
        for (const char of text) {
          const width = BigInt(Buffer.byteLength(char));
          positions.set(size, { char, next: size + width });
          size += width;
        }
        assert.equal(compiled.replayTextBytes(text), size);
        for (let position = 0n; position <= size + 1n; position++) {
          assert.equal(compiled.replayTextGet(text, position), positions.get(position)?.char ?? 'A');
          assert.equal(compiled.replayTextNext(text, position), positions.get(position)?.next ?? position + 1n);
          assert.equal(compiled.replayTextAtEnd(text, position), position >= size);
        }
        assert.equal(compiled.replayTextGet(text, 2n ** 70n), 'A');
        assert.equal(compiled.replayTextNext(text, 2n ** 70n), 2n ** 70n + 1n);
      }
      // Alternate cached text, including equal content from separate allocations.
      for (const text of ['é', 'xyz', ['é'].join(''), 'xyz']) {
        assert.equal(compiled.replayTextGet(text, 0n), [...text][0]);
      }
    } else {
      for (const n of [0n, 1n, 2n, 8n, 100n]) {
        assert.equal(compiled.replayReturnedFunction(n, 11n), n === 0n ? 18n : n + 10n);
        assert.equal(compiled.replayNestedFunction(31n, n, 11n), n === 0n ? 42n : n + 41n);
        assert.equal(compiled.replayPartialFunction(n), n + 2n);
        assert.equal(compiled.replayFuelFunction(n, 11n), n + 11n);
        assert.equal(compiled.replayPairProjection(n, 11n), n + 11n);
        assert.equal(compiled.replayRecordFunction(n, 11n).value, n + 11n);
        assert.equal(compiled.replayPartialOuter(n, 11n), n === 0n ? 18n : n + 10n);
        assert.equal(compiled.replayIgnoredParameters(4n, 5n, n), n);
        assert.equal(compiled.replayStrictBindings(n, 11n), n + 11n);
        assert.equal(compiled.replayShadowedBinding(n), n + 3n);
        assert.equal(compiled.replayStructureShadow(compiled.replayRecordFunction(n, 0n)), n + 1n);
      }
      assert.equal(compiled.replayReversed.head, 9n);
      assert.equal(compiled.replayReversed.tail.head, 7n);
      assert.equal(Object.keys(compiled.replayReversed.tail.tail).length, 0);
      let deep = compiled.List.nil();
      for (let n = 0n; n < 20000n; n++) deep = compiled.List.cons(n, deep);
      let reversed = compiled.replayReverse(deep);
      for (let n = 0n; n < 20000n; n++) {
        assert.equal(reversed.head, n);
        reversed = reversed.tail;
      }
      assert.equal(Object.keys(reversed).length, 0);
      assert.equal(compiled.replayFuelFunction(20000n, 11n), 20011n);
      assert.throws(() => compiled.replayReverse({}), /invalid ProofScript constructor tag/);
    }
  }
  console.log('PSC2_SELFHOST_REPLAY_RUNTIME: PASS (strict TypeScript; 20000-step recursion, function results, name collisions, generic lists and exact UTF-8 positions)');
} finally {
  await rm(staging, { recursive: true, force: true });
}
