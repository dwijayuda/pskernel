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

test('default owned kernel checks dependent source before emission and execution', { skip: !native }, async () => {
  const dir = await mkdtemp(path.join(tmpdir(), 'psc2-owned-checked-real-'));
  try {
    await writeFile(path.join(dir, 'package.json'), '{"type":"module"}');
    const entryPath = path.join(dir, 'Main.lean'), outputPath = path.join(dir, 'out.js');
    await writeFile(entryPath, 'def identity (A : Type) (a : A) : A := a\n');
    const receipt = await buildChecked({ entryPath, outputPath, seedPath: seed });
    const module = await import(pathToFileURL(outputPath).href);
    assert.equal(module.identity(42n), 42n);
    assert.equal(receipt.kernel.selector, 'pskernel-core');
    assert.equal(receipt.provider.provider, 'psc-generated-owned');
    assert.equal(receipt.schemaVersion, 3);
  } finally { await rm(dir, { recursive: true, force: true }); }
});

test('previously unsupported Flag enum is now owned-checked and emitted', { skip: !native }, async () => {
  const dir = await mkdtemp(path.join(tmpdir(), 'psc2-owned-flag-real-'));
  try {
    await writeFile(path.join(dir, 'package.json'), '{"type":"module"}');
    const entryPath = path.join(dir, 'Main.lean'), outputPath = path.join(dir, 'out.js');
    await writeFile(entryPath, 'inductive Flag where\n  | off\n  | on\n');
    const receipt = await buildChecked({ entryPath, outputPath, seedPath: seed });
    assert.equal(receipt.kernel.selector, 'pskernel-core');
    const module = await import(pathToFileURL(outputPath).href);
    assert.notDeepEqual(module.Flag.off, module.Flag.on);
  } finally { await rm(dir, { recursive: true, force: true }); }
});

test('previously unsupported PayloadFlag source now passes owned sum admission', { skip: !native }, async () => {
  const dir = await mkdtemp(path.join(tmpdir(), 'psc2-owned-payload-flag-'));
  try {
    await writeFile(path.join(dir, 'package.json'), '{"type":"module"}');
    const entryPath = path.join(dir, 'Main.lean'), outputPath = path.join(dir, 'out.js');
    await writeFile(entryPath, 'inductive PayloadFlag where\n  | off\n  | on (value : Nat)\n');
    const receipt = await buildChecked({ entryPath, outputPath, seedPath: seed });
    assert.equal(receipt.kernel.selector, 'pskernel-core');assert.equal(receipt.provider.profile, 'owned-uniform-algebraic/11');
    const module = await import(pathToFileURL(outputPath).href);assert.notEqual(module.PayloadFlag.on(7n), undefined);
  } finally { await rm(dir, { recursive: true, force: true }); }
});

test('default owned kernel blocks unsupported recursive payload sums before writing output', { skip: !native }, async () => {
  const dir = await mkdtemp(path.join(tmpdir(), 'psc2-owned-rejected-real-'));
  try {
    const entryPath = path.join(dir, 'Main.lean'), outputPath = path.join(dir, 'never/out.js');
    await writeFile(entryPath, 'inductive RecursiveFlag where\n  | off\n  | on (tail : RecursiveFlag) (value : Nat)\n');
    await assert.rejects(buildChecked({ entryPath, outputPath, seedPath: seed }), /KERNEL_REJECTED:/);
    assert.equal(existsSync(path.dirname(outputPath)), false);
  } finally { await rm(dir, { recursive: true, force: true }); }
});

test('actual unit source passes owned admission, exact-module emission and execution', { skip: !native }, async () => {
  const dir = await mkdtemp(path.join(tmpdir(), 'psc2-owned-unit-real-'));
  try {
    await writeFile(path.join(dir, 'package.json'), '{"type":"module"}');
    const entryPath = path.join(dir, 'Main.lean'), outputPath = path.join(dir, 'out.js');
    await writeFile(entryPath, 'inductive SampleUnit where\n  | make\ndef sample : SampleUnit := SampleUnit.make\n');
    const receipt = await buildChecked({ entryPath, outputPath, seedPath: seed });
    const module = await import(pathToFileURL(outputPath).href);
    assert.notEqual(module.sample, undefined);
    assert.deepEqual(module.sample, module.SampleUnit.make);
    assert.equal(receipt.kernel.selector, 'pskernel-core');
    assert.equal(receipt.provider.profile, 'owned-uniform-algebraic/11');
    assert.match(await readFile(path.join(dir, 'out.admissions.json'), 'utf8'), /SampleUnit/u);
  } finally { await rm(dir, { recursive: true, force: true }); }
});

test('actual Nat constructor source passes the owned bootstrap and executed output', { skip: !native }, async () => {
  const dir = await mkdtemp(path.join(tmpdir(), 'psc2-owned-nat-real-'));
  try {
    await writeFile(path.join(dir, 'package.json'), '{"type":"module"}');
    const entryPath = path.join(dir, 'Main.lean'), outputPath = path.join(dir, 'out.js');
    await writeFile(entryPath, 'def first : Nat := Nat.succ Nat.zero\n');
    const receipt = await buildChecked({ entryPath, outputPath, seedPath: seed });
    const module = await import(pathToFileURL(outputPath).href);
    assert.equal(module.first, 1n);
    assert.equal(receipt.kernel.selector, 'pskernel-core');
    assert.equal(receipt.provider.profile, 'owned-uniform-algebraic/11');
  } finally { await rm(dir, { recursive: true, force: true }); }
});

for (const kind of ['lean','ps']) test(`actual ${kind} natural literal passes owned checking and executed output`, {skip:!native}, async()=>{
  const dir=await mkdtemp(path.join(tmpdir(),'psc2-owned-literal-real-'));
  try {
    await writeFile(path.join(dir,'package.json'),'{"type":"module"}');
    const entryPath=path.join(dir,'Main.'+kind),outputPath=path.join(dir,'out.js');
    await writeFile(entryPath,kind==='lean'?'def answer : Nat := 42\n':'def answer: Nat := 42;\n');
    const receipt=await buildChecked({entryPath,outputPath,seedPath:seed});
    assert.equal((await import(pathToFileURL(outputPath).href)).answer,42n);
    assert.equal(receipt.kernel.selector,'pskernel-core');assert.equal(receipt.provider.profile,'owned-uniform-algebraic/11');
  } finally {await rm(dir,{recursive:true,force:true});}
});

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
      const receipt = await buildChecked({ entryPath, outputPath, seedPath: seed, kernel: 'lean434-wasm' });
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

for (const kind of ['lean','ps']) test(`actual ${kind} closed record passes owned checking and executed output`, {skip:!native}, async()=>{
  const dir=await mkdtemp(path.join(tmpdir(),'psc2-owned-record-real-'));
  try {
    await writeFile(path.join(dir,'package.json'),'{"type":"module"}');
    const entryPath=path.join(dir,'Main.'+kind),outputPath=path.join(dir,'out.js');
    const source=kind==='lean'
      ? 'structure OwnedPair where\n  left : Nat\n  right : Nat\ndef pair : OwnedPair := OwnedPair.mk 7 11\n'
      : 'structure OwnedPair where { left : Nat; right : Nat; };\ndef pair : OwnedPair := OwnedPair.mk(7, 11);\n';
    await writeFile(entryPath,source);
    const receipt=await buildChecked({entryPath,outputPath,seedPath:seed});
    const result=(await import(pathToFileURL(outputPath).href)).pair;
    assert.equal(result.left,7n);assert.equal(result.right,11n);
    assert.equal(receipt.kernel.selector,'pskernel-core');assert.equal(receipt.provider.profile,'owned-uniform-algebraic/11');
  } finally {await rm(dir,{recursive:true,force:true});}
});
