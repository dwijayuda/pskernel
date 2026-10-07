import assert from 'node:assert/strict';
import { test } from 'node:test';
import { mkdtemp, writeFile, readFile, rm } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { buildChecked, defaultCheckedSeed } from './checked-build.mjs';
import { kernelContractV1 } from './kernel-contract.mjs';
import { verifyArtifact } from './artifact-evidence.mjs';
import { verifyObservedBuildArchive } from './observed-build-archive.mjs';

const seed = process.env.PSC2_CHECKED_SEED_BIN ?? defaultCheckedSeed;
const native = existsSync(seed);

function passDefinitions(graph) {
  return graph.entries
    .filter(entry => entry.identity?.domain === 'pass-definition')
    .map(entry => entry.canonicalValue);
}

function allowedAssumptionsFromGraph(graph) {
  return [...new Set(passDefinitions(graph).flatMap(definition => definition.assumptionIds ?? []))];
}

function passIds(graph) {
  return passDefinitions(graph).map(definition => definition.passId);
}

function assertPasses(graph, required) {
  const actual = new Set(passIds(graph));
  for (const passId of required) assert.equal(actual.has(passId), true, 'missing pass ' + passId);
}

test('explicit owned kernel checks dependent source before emission and execution', { skip: !native }, async () => {
  const dir = await mkdtemp(path.join(tmpdir(), 'psc2-owned-checked-real-'));
  try {
    await writeFile(path.join(dir, 'package.json'), '{"type":"module"}');
    const entryPath = path.join(dir, 'Main.lean'), outputPath = path.join(dir, 'out.js');
    await writeFile(entryPath, 'def identity (A : Type) (a : A) : A := a\n');
    const receipt = await buildChecked({ entryPath, outputPath, seedPath: seed, kernel: 'pskernel-core.old3' });
    const module = await import(pathToFileURL(outputPath).href);
    assert.equal(module.identity(42n), 42n);
    assert.equal(receipt.kernel.selector, 'pskernel-core.old3');
    assert.equal(receipt.provider.provider, 'psc-generated-owned');
    assert.equal(receipt.schemaVersion, 4);
    assert.equal(receipt.kernelContract.id, kernelContractV1.id);
    assert.equal(receipt.kernelContract.sha256, kernelContractV1.sha256);
    const graph = JSON.parse(await readFile(path.join(dir, 'out.build-graph.json'), 'utf8'));
    const archiveBytes = await readFile(path.join(dir, 'out.build-archive.json'));
    verifyArtifact(archiveBytes, receipt.buildArchive);
    const archived = await verifyObservedBuildArchive(archiveBytes, { expectedGraphId: receipt.buildGraph,
      allowedAssumptions: allowedAssumptionsFromGraph(graph) });
    assert.equal(archived.kind, 'accepted', archived.reason);
    assert.equal(archived.executions.length, graph.executions.length);
    assertPasses(graph, [
      'psc-prepare-and-check/1',
      'psc-certify-checked-core/1',
      'psc-erase-checked-core/1',
      'psc-validate-runtime-ir/1',
      'psc-project-runtime-interface/1',
      'psc-verified-ir-to-js-abi-plan/1',
      'psc-verified-ir-to-typescript/1',
      'typescript-to-es2022/1',
    ]);
    assert.equal(archived.runtimeInterfaceProjections.length, 1);
    assert.equal(archived.semanticClaimsVerified, false);
  } finally { await rm(dir, { recursive: true, force: true }); }
});

test('previously unsupported Flag enum is now owned-checked and emitted', { skip: !native }, async () => {
  const dir = await mkdtemp(path.join(tmpdir(), 'psc2-owned-flag-real-'));
  try {
    await writeFile(path.join(dir, 'package.json'), '{"type":"module"}');
    const entryPath = path.join(dir, 'Main.lean'), outputPath = path.join(dir, 'out.js');
    await writeFile(entryPath, 'inductive Flag where\n  | off\n  | on\n');
    const receipt = await buildChecked({ entryPath, outputPath, seedPath: seed, kernel: 'pskernel-core.old3' });
    assert.equal(receipt.kernel.selector, 'pskernel-core.old3');
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
    const receipt = await buildChecked({ entryPath, outputPath, seedPath: seed, kernel: 'pskernel-core.old3' });
    assert.equal(receipt.kernel.selector, 'pskernel-core.old3');assert.equal(receipt.provider.profile, 'owned-uniform-algebraic/11');
    const module = await import(pathToFileURL(outputPath).href);assert.notEqual(module.PayloadFlag.on(7n), undefined);
  } finally { await rm(dir, { recursive: true, force: true }); }
});

test('explicit owned kernel blocks unsupported recursive payload sums before writing output', { skip: !native }, async () => {
  const dir = await mkdtemp(path.join(tmpdir(), 'psc2-owned-rejected-real-'));
  try {
    const entryPath = path.join(dir, 'Main.lean'), outputPath = path.join(dir, 'never/out.js');
    await writeFile(entryPath, 'inductive RecursiveFlag where\n  | off\n  | on (tail : RecursiveFlag) (value : Nat)\n');
    await assert.rejects(buildChecked({ entryPath, outputPath, seedPath: seed, kernel: 'pskernel-core.old3' }), /KERNEL_REJECTED:/);
    assert.equal(existsSync(path.dirname(outputPath)), false);
  } finally { await rm(dir, { recursive: true, force: true }); }
});

test('actual unit source passes owned admission, exact-module emission and execution', { skip: !native }, async () => {
  const dir = await mkdtemp(path.join(tmpdir(), 'psc2-owned-unit-real-'));
  try {
    await writeFile(path.join(dir, 'package.json'), '{"type":"module"}');
    const entryPath = path.join(dir, 'Main.lean'), outputPath = path.join(dir, 'out.js');
    await writeFile(entryPath, 'inductive SampleUnit where\n  | make\ndef sample : SampleUnit := SampleUnit.make\n');
    const receipt = await buildChecked({ entryPath, outputPath, seedPath: seed, kernel: 'pskernel-core.old3' });
    const module = await import(pathToFileURL(outputPath).href);
    assert.notEqual(module.sample, undefined);
    assert.deepEqual(module.sample, module.SampleUnit.make);
    assert.equal(receipt.kernel.selector, 'pskernel-core.old3');
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
    const receipt = await buildChecked({ entryPath, outputPath, seedPath: seed, kernel: 'pskernel-core.old3' });
    const module = await import(pathToFileURL(outputPath).href);
    assert.equal(module.first, 1n);
    assert.equal(receipt.kernel.selector, 'pskernel-core.old3');
    assert.equal(receipt.provider.profile, 'owned-uniform-algebraic/11');
  } finally { await rm(dir, { recursive: true, force: true }); }
});

for (const kind of ['lean','ps']) test(`actual ${kind} natural literal passes owned checking and executed output`, {skip:!native}, async()=>{
  const dir=await mkdtemp(path.join(tmpdir(),'psc2-owned-literal-real-'));
  try {
    await writeFile(path.join(dir,'package.json'),'{"type":"module"}');
    const entryPath=path.join(dir,'Main.'+kind),outputPath=path.join(dir,'out.js');
    await writeFile(entryPath,kind==='lean'?'def answer : Nat := 42\n':'const answer: Nat := { 42 }\n');
    const receipt=await buildChecked({entryPath,outputPath,seedPath:seed,kernel:'pskernel-core.old3'});
    assert.equal((await import(pathToFileURL(outputPath).href)).answer,42n);
    assert.equal(receipt.kernel.selector,'pskernel-core.old3');assert.equal(receipt.provider.profile,'owned-uniform-algebraic/11');
  } finally {await rm(dir,{recursive:true,force:true});}
});

for (const [kind, source] of [
  ['lean', 'def answer : Nat := 42\n'],
  ['ps', 'const answer: Nat := { 42 }\n'],
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
      assert.equal(receipt.pscvCert.contract, 'pscv-cert/1');
      assert.equal(receipt.certifiedSource.contract, 'psc-certified-source/1');
      assert.equal(receipt.evidenceEnvelope.contract, 'psc-evidence-envelope/1');
      assert.ok(existsSync(path.join(dir, 'out.admissions.json')));
      assert.ok(existsSync(path.join(dir, 'out.pscv-cert.json')));
      assert.ok(existsSync(path.join(dir, 'out.certified-source.json')));
      assert.ok(existsSync(path.join(dir, 'out.evidence-envelope.json')));
      const graph = JSON.parse(await readFile(path.join(dir, 'out.build-graph.json'), 'utf8'));
      assert.equal(graph.coverage, 'observed-erasure-validation-and-composite-backend-edges');
      assertPasses(graph, [
        'psc-prepare-and-check/1',
        'psc-certify-checked-core/1',
        'psc-erase-checked-core/1',
        'psc-validate-runtime-ir/1',
        'psc-project-runtime-interface/1',
        'psc-verified-ir-to-js-abi-plan/1',
        'psc-verified-ir-to-typescript/1',
        'typescript-to-es2022/1',
      ]);
      assert.equal(graph.executions.length, passDefinitions(graph).length);
      assert.equal(receipt.runtimeInterface.domain, 'runtime-interface');
      assert.deepEqual(graph.entries.find(entry => entry.identity.domain === 'runtime-interface').identity, receipt.runtimeInterface);
      assert.equal(receipt.sourceResources.contract, 'psc-source-read-budget/1');
      assert.equal(receipt.sourceResources.observed.sourceBytes, Buffer.byteLength(source));
      assert.equal(receipt.sourceResources.observed.moduleCount, 1);
      const preparation = graph.entries.find(entry => entry.identity.contract === 'psc-pass-execution/1' &&
        entry.canonicalValue.action.parameters.observedStages.includes('prepare')).canonicalValue;
      assert.deepEqual(preparation.action.resourcePolicy.sourceReading, receipt.sourceResources.limits);
      assert.deepEqual(preparation.resourceObservation.sourceReading, receipt.sourceResources.observed);
      assert.equal(preparation.action.resourcePolicy.completeBudgetCoverage, false);
      assert.deepEqual(preparation.action.resourcePolicy.nativeSession, receipt.seedResources.limits);
      assert.deepEqual(preparation.resourceObservation.nativeSession, receipt.seedResources.observed);
      assert.equal(receipt.seedResources.observed.frames, 2);
      assert.equal(graph.entries.filter(entry => entry.identity.domain === 'runtime-ir').length, 1);
      assert.equal(graph.entries.filter(entry => entry.identity.domain === 'verified-ir').length, 1);
      const tool = graph.entries.find(entry => entry.identity.contract === 'psc-typescript-tool-inputs/1');
      assert.deepEqual(tool.identity, receipt.typeScriptToolInputs);
      assert.equal(tool.canonicalValue.coverage, 'installed-package-and-selected-native-package');
      assert.equal(tool.canonicalValue.fullInputClosureEstablished, false);
      assert.ok(tool.canonicalValue.files.some(item => item.path === tool.canonicalValue.nativePath));
      assert.ok(tool.canonicalValue.files.some(item => item.path.endsWith('/lib.es2022.d.ts')));
      const provider = graph.entries.find(entry => entry.identity.contract === 'psc-checked-provider-inputs/1');
      assert.deepEqual(receipt.providerInputs, [provider.identity]);
      assert.equal(provider.canonicalValue.selector, 'lean434-wasm');
      assert.ok(provider.canonicalValue.files.some(item => item.path.endsWith('/pskernel-lean.wasm')));
      assert.equal(receipt.providerInputObservations[0].fullInputClosureEstablished, false);
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

test('source resource exhaustion precedes compiler loading and output publication', async () => {
  const dir = await mkdtemp(path.join(tmpdir(), 'psc2-source-budget-'));
  try {
    const entryPath = path.join(dir, 'Main.lean'), outputPath = path.join(dir, 'never', 'out.js');
    await writeFile(entryPath, 'def answer : Nat := 42\n');
    await assert.rejects(buildChecked({ entryPath, outputPath, seedPath: path.join(dir, 'missing-seed'),
      sourceResourceLimits: { sourceBytes: 1 } }), error => error.kind === 'resourceExhausted' && error.resource === 'sourceBytes');
    assert.equal(existsSync(path.dirname(outputPath)), false);
  } finally { await rm(dir, { recursive: true, force: true }); }
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
      : 'structure OwnedPair where {\n  left : Nat,\n  right : Nat\n}\nconst pair: OwnedPair := { OwnedPair.mk(7, 11) }\n';
    await writeFile(entryPath,source);
    const receipt=await buildChecked({entryPath,outputPath,seedPath:seed,kernel:'pskernel-core.old3'});
    const result=(await import(pathToFileURL(outputPath).href)).pair;
    assert.equal(result.left,7n);assert.equal(result.right,11n);
    assert.equal(receipt.kernel.selector,'pskernel-core.old3');assert.equal(receipt.provider.profile,'owned-uniform-algebraic/11');
  } finally {await rm(dir,{recursive:true,force:true});}
});
