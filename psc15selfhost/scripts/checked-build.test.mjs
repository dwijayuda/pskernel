import assert from 'node:assert/strict';
import { test } from 'node:test';
import { mkdtemp, writeFile, readFile, rm } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { buildChecked, defaultCheckedSeed } from './checked-build.mjs';

const seed = process.env.PSC2_CHECKED_SEED_BIN ?? defaultCheckedSeed;
const native = existsSync(seed);

for (const [kind, source] of [
  ['lean', 'def answer : Nat := 42\n'],
  ['ps', 'def answer: Nat := 42;\n'],
]) {
  test(`real ${kind} frontend -> WASM Lean kernel -> tsc -> executed JavaScript`, { skip: !native }, async () => {
    const dir = await mkdtemp(path.join(tmpdir(), 'psc2-checked-real-'));
    try {
      await writeFile(path.join(dir, 'package.json'), '{"type":"module"}');
      const entryPath = path.join(dir, 'Main.' + kind);
      await writeFile(entryPath, source);
      const outputPath = path.join(dir, 'out.js');
      const receipt = await buildChecked({ entryPath, outputPath, seedPath: seed });
      const module = await import(pathToFileURL(outputPath).href);
      assert.equal(module.answer, 42n);
      assert.equal(receipt.provider.profile, 'lean4.34-core');
      assert.equal(receipt.kernel.selector, 'lean434-wasm');
      assert.equal(receipt.kernel.package, '@proofscript/pskernel-lean-wasm');
      const saved = JSON.parse(await readFile(path.join(dir, 'out.checked.json'), 'utf8'));
      assert.deepEqual(saved, receipt);
      assert.equal(saved.compiler.engine, 'native-seed');
      assert.ok(existsSync(path.join(dir, 'out.admissions.json')));
    } finally {
      await rm(dir, { recursive: true, force: true });
    }
  });
}

test('native Lean kernel remains selectable for the same seed session', { skip: !native }, async () => {
  const dir = await mkdtemp(path.join(tmpdir(), 'psc2-checked-native-alt-'));
  try {
    const entryPath = path.join(dir, 'Main.lean');
    await writeFile(entryPath, 'def answer : Nat := 42\n');
    const receipt = await buildChecked({ entryPath, seedPath: seed, kernel: 'lean434', checkOnly: true });
    assert.equal(receipt.kernel.selector, 'lean434');
    assert.equal(receipt.kernel.package, '@proofscript/pskernel-lean');
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
});

test('real frontend failure creates no requested output or checked receipt', { skip: !native }, async () => {
  const dir = await mkdtemp(path.join(tmpdir(), 'psc2-checked-negative-'));
  try {
    const entryPath = path.join(dir, 'Bad.lean');
    await writeFile(entryPath, 'def bad : Nat := Type\n');
    const outputPath = path.join(dir, 'never', 'out.js');
    await assert.rejects(
      buildChecked({ entryPath, outputPath, seedPath: seed }),
      /SEED_SESSION|PREPARE_FAILED/,
    );
    assert.equal(existsSync(path.dirname(outputPath)), false);
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
});

test('no unchecked or alternative-kernel fallback in checked profile', async () => {
  await assert.rejects(
    buildChecked({ entryPath: 'Main.ps', kernel: 'none', checkOnly: true }),
    /KERNEL_UNSUPPORTED/,
  );
});
