import { instantiateCanonicalExports } from './canonical-exports.mjs';
import { artifactId, canonicalArtifact, artifactKey } from './artifact-evidence.mjs';
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { mkdtemp, writeFile, readFile, rm } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { createHash } from 'node:crypto';
import { buildChecked, defaultCheckedSeed, selectCheckedBuildProducts } from './checked-build.mjs';
import { closedJsRepresentationProfile, uniformJsRepresentationProfile } from './uniform-specialization.mjs';
import { kernelContractV1 } from './kernel-contract.mjs';
import { decodePublicApi } from './public-api-artifact.mjs';
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
      'psc-source-preparation-origins/1',
      'psc-prepare-and-check/1',
      'psc-certify-checked-core/1',
      'psc-project-public-api/1',
      'psc-capture-declaration-origins/1',
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
      assert.equal(receipt.profileEnvironment.contract, 'psc-profile-environment/1');
      assert.equal(receipt.artifactBundle.contract, 'psc-artifact-bundle/1');
      const bundle = JSON.parse(await readFile(path.join(dir, 'out.artifact-bundle.json'), 'utf8'));
      assert.deepEqual(bundle.profileEnvironmentId, receipt.profileEnvironment);
      assert.deepEqual(bundle.backendDescriptorId, receipt.backendDescriptor);
      assert.deepEqual(bundle.claimSetId, receipt.claimSet);
      assert.deepEqual(bundle.executableArtifacts.map(item => item.role), ['target-source', 'javascript']);
      assert.deepEqual(bundle.publicApiArtifacts.map(item => item.role), ['source-api', 'declaration']);
      const apiBytes = await readFile(path.join(dir, 'out.public-api.json'));
      verifyArtifact(apiBytes, receipt.publicApi);
      assert.equal(decodePublicApi(apiBytes)[0], 'psc-public-api-ir/1');
      assert.deepEqual(bundle.debugArtifacts.map(item => item.role), ['source-origins', 'origin-graph', 'erasure-map', 'source-map']);
      const origins = await readFile(path.join(dir, 'out.source-origins.json'));
      verifyArtifact(origins, receipt.sourceOrigins);
      assert.equal(JSON.parse(origins).coordinateUnit, 'utf8-byte');
      const originGraph = await readFile(path.join(dir, 'out.origin-graph.json'));
      verifyArtifact(originGraph, receipt.originGraph);
      assert.equal(JSON.parse(originGraph).granularity, 'declaration-batch');
      const erasureMap = await readFile(path.join(dir, 'out.erasure-map.json'));
      verifyArtifact(erasureMap, receipt.erasureMap);
      assert.equal(JSON.parse(erasureMap).semanticPreservationProved, false);
      assert.ok(existsSync(path.join(dir, 'out.admissions.json')));
      assert.ok(existsSync(path.join(dir, 'out.pscv-cert.json')));
      assert.ok(existsSync(path.join(dir, 'out.certified-source.json')));
      assert.ok(existsSync(path.join(dir, 'out.evidence-envelope.json')));
      const graph = JSON.parse(await readFile(path.join(dir, 'out.build-graph.json'), 'utf8'));
      assert.equal(graph.coverage, 'observed-erasure-validation-and-composite-backend-edges');
      assertPasses(graph, [
        'psc-source-preparation-origins/1',
      'psc-prepare-and-check/1',
        'psc-certify-checked-core/1',
      'psc-project-public-api/1',
      'psc-capture-declaration-origins/1',
        'psc-erase-checked-core/1',
        'psc-capture-erasure-declarations/1',
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

test('build target and product combinations reject before source loading', async () => {
  assert.equal(selectCheckedBuildProducts().backend, 'typescript');
  assert.equal(selectCheckedBuildProducts({ backend: 'rust' }).products, 'source');
  assert.equal(selectCheckedBuildProducts().products, 'metadata');
  assert.equal(selectCheckedBuildProducts({ backend: 'javascript' }).products, 'executable');
  for (const options of [
    { backend: 'rust', products: 'executable' }, { backend: 'rust', products: 'all' },
    { backend: 'javascript', products: 'source' }, { backend: 'unknown' }, { backend: 'javascript', products: 'unknown' },
    { backend: 'typescript', products: 'all' }, { backend: 'wasm', products: 'declarations' },
    { backend: 'wasm', javaScriptRepresentation: uniformJsRepresentationProfile },
    { backend: 'javascript', javaScriptRepresentation: 'unknown' },
  ]) await assert.rejects(buildChecked({ entryPath: 'missing-source', outputPath: 'out.js', ...options }),
    /PSC2_CHECKED_(BACKEND|PRODUCTS|PRODUCT_TARGET|JAVASCRIPT_REPRESENTATION)/);
  await assert.rejects(buildChecked({ entryPath: 'missing-source', outputPath: 'out.ts', backend: 'javascript' }),
    /PSC2_CHECKED_OUTPUT_KIND/);
});

// These fixtures test host routing with real acceptance of empty admissions.
// Actual compiler source/backend correspondence is covered by IrEncodingTests;
// no preservation claim follows from this transport/publication test double.
function buildRoutingCompiler({ uniform, executableOnly, malformed = false }) {
  const ir = '["psc-runtime-ir-json/1",[],[],[],[]]';
  return [
    "const ok = value => ({ $ps$tag: 'ok', $ps$fields: { value } });",
    "const nil = () => ({ $ps$tag: 'nil', $ps$fields: {} });",
    "const cons = (head, tail) => ({ $ps$tag: 'cons', $ps$fields: { head, tail } });",
    "export const List = { nil, cons };",
    "export const PsCompilerSourceKind = { lean: 'lean', proofScript: 'ps' };",
    "let preparations = 0, emissions = 0, declarations = 0;",
    "export const counts = () => ({ preparations, emissions, declarations });",
    "export const psCompilerPrepareSource = (kind, source) => ok({kind, source});",
    "export const psCompilerPrepareSources = (kind, sources) => { preparations++; return ok({kind, sources}); };",
    "export const psCompilerPrepareSourcesWithOrigins = (kind, sources) => { preparations++; return ok({ prepared: {kind, sources}, origins: " +
      JSON.stringify(executableOnly ? null : '["psc-declaration-origins/1","declaration-batch",1,[]]') + " }); };",
    "export const psCompilerAdmissionsFromPrepared = () => ok(" +
      JSON.stringify('{"admissions":[],"format":"proofscript-checked-admissions","version":2}') + ");",
    "const ir = " + JSON.stringify(ir) + ";",
    "export const psCompilerPublicApiFromPrepared = () => " +
      (executableOnly ? "{ throw new Error('UNREQUESTED_API'); };" :
        "ok(" + JSON.stringify('["psc-public-api-ir/1","all-prepared-declarations",[]]') + ");"),
    "function js() { emissions++; const value = { javaScript: '', runtimeIr: ir, verifiedIr: ir, " +
      (uniform ? "uniformSpecializedIr: " + JSON.stringify(JSON.stringify(['psc-uniform-specialized-ir/1', uniformJsRepresentationProfile, JSON.parse(ir)])) :
        "specializedIr: ir") + ", jsIr: " + JSON.stringify(malformed ? 'malformed' : '["psc-js-ir-json/1",[],[]]') +
      ", erasureCorrespondence: " + JSON.stringify('["psc-erasure-declarations/1","declaration-inventory",[]]') + " }; " +
      (executableOnly ? "Object.defineProperty(value, 'generatedPositions', { get() { throw new Error('UNREQUESTED_POSITIONS'); } });" :
        "value.generatedPositions = " + JSON.stringify('["psc-js-generated-positions/1","declaration-emission-chunk",[]]') + ";") +
      "return ok(value); }",
    "export const " + (uniform ? "psCompilerUniformJavaScriptStagesFromPrepared" : "psCompilerJavaScriptStagesFromPrepared") + " = js;",
    "export const psCompilerJavaScriptDeclarationsFromPrepared = () => { declarations++; return ok(" +
      JSON.stringify('export {};\n') + "); };",
    "export const psCompilerRustStagesFromPrepared = () => { emissions++; return ok({ rustSource: 'pub fn answer() -> u32 { 42 }', runtimeIr: ir, verifiedIr: ir, erasureCorrespondence: " +
      JSON.stringify('["psc-erasure-declarations/1","declaration-inventory",[]]') + " }); };",
    "export const psCompilerWasm32Target = { wordSize: 'wasm32' };",
    "export const psCompilerWasmStagesFromPrepared = () => { emissions++; return ok({ runtimeIr: ir, verifiedIr: ir, specializedIr: ir, wasmIr: " +
      JSON.stringify('["psc-wasm-ir-json/1",[],[],[],[],[],[]]') +
      ", wasm: [0,97,115,109,1,0,0,0].reduceRight((tail, head) => cons(head, tail), nil()) }); };",
  ].join('\n');
}

for (const [backend, products, representation] of [
  ['javascript', 'all', closedJsRepresentationProfile],
  ['javascript', 'all', uniformJsRepresentationProfile],
  ['javascript', 'source-map', closedJsRepresentationProfile],
  ['javascript', 'linked', closedJsRepresentationProfile],
  ['javascript', 'linked', uniformJsRepresentationProfile],
  ['javascript', 'declaration-map', uniformJsRepresentationProfile],
  ['javascript', 'executable', closedJsRepresentationProfile],
  ['wasm', 'executable', closedJsRepresentationProfile],
]) test(`direct ${backend}/${products}/${representation} publishes selected graph products without TypeScript`,
  { skip: !native }, async () => {
    const dir = await mkdtemp(path.join(tmpdir(), 'psc-checked-direct-routing-'));
    const previousCli = process.env.PSC_TYPESCRIPT_CLI;
    try {
      process.env.PSC_TYPESCRIPT_CLI = path.join(dir, 'typescript-must-not-be-loaded');
      const entryPath = path.join(dir, 'Empty.lean'), compilerPath = path.join(dir, 'fixture.mjs');
      const outputPath = path.join(dir, backend === 'wasm' ? 'out.wasm' : 'out.js');
      await writeFile(entryPath, '-- no declarations\n');
      await writeFile(compilerPath, buildRoutingCompiler({ uniform: representation === uniformJsRepresentationProfile,
        executableOnly: products === 'executable' }));
      const receipt = await buildChecked({ entryPath, outputPath, compilerPath, backend, products,
        javaScriptRepresentation: representation, kernel: 'lean434' });
      assert.equal(receipt.backend, backend); assert.equal(receipt.requestedProducts, products);
      assert.equal(receipt.typeScriptToolInputs, undefined); assert.equal(receipt.typeScriptSha256, undefined);
      assert.equal(existsSync(path.join(dir, 'out.ts')), false);
      const counts = (await import(pathToFileURL(compilerPath).href)).counts();
      assert.deepEqual(counts, { preparations: 1, emissions: 1, declarations: ['all', 'declaration-map', 'linked'].includes(products) ? 1 : 0 });
      const certificate = JSON.parse(await readFile(path.join(dir, 'out.pscv-cert.json')));
      assert.deepEqual(certificate.context.targets, [backend]);
      const graph = JSON.parse(await readFile(path.join(dir, 'out.build-graph.json')));
      assert.equal(passIds(graph).includes('typescript-to-es2022/1'), false);
      assert.equal(graph.entries.some(entry => entry.identity.domain === 'typescript-compiler-entry'), false);
      const archived = await verifyObservedBuildArchive(await readFile(path.join(dir, 'out.build-archive.json')),
        { expectedGraphId: receipt.buildGraph, allowedAssumptions: allowedAssumptionsFromGraph(graph) });
      assert.equal(archived.kind, 'accepted', archived.reason); assert.equal(archived.semanticClaimsVerified, false);
      if (['all', 'declaration-map', 'linked'].includes(products)) {
        const publishedDeclarations = await readFile(path.join(dir, 'out.d.ts'), 'utf8');
        if (products === 'linked') {
          assert.match(publishedDeclarations, /sourceMappingURL=out\.d\.ts\.map/);
          assert.match(await readFile(outputPath, 'utf8'), /sourceMappingURL=out\.js\.map/);
          assert.equal(passIds(graph).includes('psc-link-direct-js-source-maps/1'), true);
          assert.ok(receipt.directMapLinks.linkedJavaScript);
          const publishedBytes = await readFile(outputPath);
          const declarationBytes = await readFile(path.join(dir, 'out.d.ts'));
          assert.equal(receipt.javaScriptSha256, createHash('sha256').update(publishedBytes).digest('hex'));
          assert.equal(receipt.linkedDeclarationsSha256, createHash('sha256').update(declarationBytes).digest('hex'));
          assert.notEqual(receipt.unlinkedJavaScriptSha256, receipt.javaScriptSha256);
          const bundle = JSON.parse(await readFile(path.join(dir, 'out.artifact-bundle.json')));
          assert.ok(bundle.executableArtifacts.some(item => item.role === 'linked-javascript'));
          assert.ok(bundle.publicApiArtifacts.some(item => item.role === 'linked-declarations'));
          assert.ok(bundle.debugArtifacts.some(item => item.role === 'source-map-link-recipe'));
        } else assert.equal(publishedDeclarations, 'export {};\n');
        assert.equal(JSON.parse(await readFile(path.join(dir, 'out.js.map'))).version, 3);
        assert.equal(receipt.declarationProduction.hostBytesCompared, true);
        assert.equal(JSON.parse(await readFile(path.join(dir, 'out.d.ts.map'))).version, 3);
        assert.ok(receipt.directDeclarationMap.declarationMap);
        assert.equal(passIds(graph).includes('psc-emit-direct-js-declaration-map/1'), true);
      } else if (products === 'source-map') {
        assert.equal(existsSync(path.join(dir, 'out.d.ts')), false);
        assert.equal(JSON.parse(await readFile(path.join(dir, 'out.js.map'))).version, 3);
      } else {
        assert.equal(receipt.publicApi, undefined); assert.equal(receipt.sourceOrigins, undefined);
        assert.equal(receipt.specializationInstances, undefined);
        assert.equal(existsSync(path.join(dir, 'out.d.ts')), false);
        assert.equal(existsSync(path.join(dir, 'out.js.map')), false);
      }
      if (backend === 'wasm') assert.equal(WebAssembly.validate(await readFile(outputPath)), true);
    } finally {
      if (previousCli === undefined) delete process.env.PSC_TYPESCRIPT_CLI;
      else process.env.PSC_TYPESCRIPT_CLI = previousCli;
      await rm(dir, { recursive: true, force: true });
    }
  });

test('a malformed direct stage does not publish executable or receipt files', { skip: !native }, async () => {
  const dir = await mkdtemp(path.join(tmpdir(), 'psc-checked-direct-reject-'));
  try {
    const entryPath = path.join(dir, 'Empty.lean'), compilerPath = path.join(dir, 'fixture.mjs');
    const outputPath = path.join(dir, 'never', 'out.js');
    await writeFile(entryPath, '-- no declarations\n');
    await writeFile(compilerPath, buildRoutingCompiler({ executableOnly: true, malformed: true }));
    await assert.rejects(buildChecked({ entryPath, outputPath, compilerPath, backend: 'javascript', kernel: 'lean434' }),
      /export-json/);
    assert.equal(existsSync(path.dirname(outputPath)), false);
  } finally { await rm(dir, { recursive: true, force: true }); }
});

// Independent producer/consumer budget for two separately captured native
// compiler/provider binaries. Per-artifact and count bounds remain defaults.
const nativeArchiveLimits = Object.freeze({ maxTotalBytes: 320 * 1024 * 1024, maxArchiveBytes: 448 * 1024 * 1024 });

for (const [backend, representation, source, linked = false] of [
  ['javascript', closedJsRepresentationProfile, 'def answer : Nat := 42\n'],
  ['javascript', uniformJsRepresentationProfile, 'def identity (A : Type) (value : A) : A := value\n'],
  ['javascript', closedJsRepresentationProfile, 'def answer : Nat := 42\n', true],
  ['javascript', uniformJsRepresentationProfile, 'def identity (A : Type) (value : A) : A := value\n', true],
  ['wasm', closedJsRepresentationProfile, 'def identity (value : Nat) : Nat := value\n'],
]) test(`actual native source -> checked ${backend}/${representation}${linked ? '/linked' : ''} -> shared published bundle`,
  { skip: !native }, async () => {
    const dir = await mkdtemp(path.join(tmpdir(), 'psc-native-direct-products-'));
    const previousCli = process.env.PSC_TYPESCRIPT_CLI;
    try {
      process.env.PSC_TYPESCRIPT_CLI = path.join(dir, 'typescript-must-not-be-loaded');
      await writeFile(path.join(dir, 'package.json'), '{"type":"module"}');
      const entryPath = path.join(dir, 'Main.lean'), outputPath = path.join(dir, backend === 'wasm' ? 'out.wasm' : 'out.js');
      await writeFile(entryPath, source);
      const receipt = await buildChecked({ entryPath, outputPath, seedPath: seed, kernel: 'lean434',
        backend, archiveResourceLimits: nativeArchiveLimits, javaScriptRepresentation: representation, products: backend === 'wasm' ? 'executable' : linked ? 'linked' : 'all' });
      assert.equal(receipt.compiler.engine, 'native-seed');
      assert.equal(receipt.archiveResourceLimits.maxTotalBytes, nativeArchiveLimits.maxTotalBytes);
      assert.equal(receipt.typeScriptToolInputs, undefined);
      assert.equal(receipt.seedResources.observed.frames, backend === 'wasm' ? 2 : 3);
      const graph = JSON.parse(await readFile(path.join(dir, 'out.build-graph.json')));
      const replay = await verifyObservedBuildArchive(await readFile(path.join(dir, 'out.build-archive.json')),
        { expectedGraphId: receipt.buildGraph, allowedAssumptions: allowedAssumptionsFromGraph(graph), resourceLimits: nativeArchiveLimits });
      assert.equal(replay.kind, 'accepted', replay.reason); assert.equal(replay.semanticClaimsVerified, false);
      if (backend === 'wasm') assert.equal(WebAssembly.validate(await readFile(outputPath)), true);
      else {
        const module = await import(pathToFileURL(outputPath).href);
        if (representation === uniformJsRepresentationProfile) assert.equal(module.identity(42n), 42n);
        else assert.equal(module.answer, 42n);
        assert.equal(receipt.declarationProduction.hostBytesCompared, true);
        assert.equal(JSON.parse(await readFile(path.join(dir, 'out.js.map'))).version, 3);
        if (linked) {
          assert.match(await readFile(outputPath, 'utf8'), /sourceMappingURL=out\.js\.map/);
          assert.match(await readFile(path.join(dir, 'out.d.ts'), 'utf8'), /sourceMappingURL=out\.d\.ts\.map/);
          assert.ok(receipt.directMapLinks.linkedJavaScript);
        }
        const declarationMap = JSON.parse(await readFile(path.join(dir, 'out.d.ts.map')));
        assert.equal(declarationMap.file, 'out.d.ts');
        assert.equal(declarationMap.sourcesContent[0], source);
        const bundle = JSON.parse(await readFile(path.join(dir, 'out.artifact-bundle.json')));
        assert.ok(bundle.debugArtifacts.some(item => item.role === 'declaration-map' &&
          artifactKey(item.artifact) === artifactKey(receipt.directDeclarationMap.declarationMap)));
        assert.match(await readFile(path.join(dir, 'out.d.ts'), 'utf8'),
          representation === uniformJsRepresentationProfile ? /<T0>/ : /bigint/);
      }
    } finally {
      if (previousCli === undefined) delete process.env.PSC_TYPESCRIPT_CLI;
      else process.env.PSC_TYPESCRIPT_CLI = previousCli;
      await rm(dir, { recursive: true, force: true });
    }
  });

test('invalid archive policy rejects before loading source or executing a compiler', async () => {
  for (const archiveResourceLimits of [null, [], { maxTotalBytes: -1 }, { maxTotalBytes: Infinity }, { unknown: 1 }])
    await assert.rejects(buildChecked({ entryPath: 'missing-source', outputPath: 'out.js',
      backend: 'javascript', archiveResourceLimits }), /PSC_BUILD_ARCHIVE_LIMIT_POLICY/);
});

test('Canonical Wasm selection requires the explicit Wasm target before source loading',async()=>{
  await assert.rejects(buildChecked({entryPath:'missing-source',outputPath:'out.js',backend:'javascript',
    wasmCanonicalSelectionPath:'missing-selection'}),/PSC2_CHECKED_WASM_EXPORT_TARGET/);
});

for(const wordBits of [32,64])test('actual native Canonical Wasm '+wordBits+' selection publishes and replays bound interface products',
  {skip:!native},async()=>{
    const dir=await mkdtemp(path.join(tmpdir(),'psc-native-canonical-'));
    const previousCli=process.env.PSC_TYPESCRIPT_CLI;
    try{
      process.env.PSC_TYPESCRIPT_CLI=path.join(dir,'typescript-must-not-be-loaded');
      const entryPath=path.join(dir,'Main.lean'),outputPath=path.join(dir,'out.wasm');
      const wasmCanonicalSelectionPath=path.join(dir,'exports.json');
      const policy=canonicalArtifact({schemaVersion:1,contract:'psc-wasm-canonical-selection/1',wordBits,
        packageNamespace:'psc',packageName:'native',worldName:'world',interfaceName:'api',
        exports:[{sourceName:'echoWord',foreignName:'echo-word'}]},'abi-policy','psc-wasm-canonical-selection/1');
      await writeFile(entryPath,'def echoWord (value : USize) : USize := value\ndef hidden (value : UInt32) : UInt32 := value\n');
      await writeFile(wasmCanonicalSelectionPath,policy.bytes);
      const receipt=await buildChecked({entryPath,outputPath,seedPath:seed,kernel:'lean434',backend:'wasm',
        products:wordBits===32?'metadata':'executable',wasmCanonicalSelectionPath,archiveResourceLimits:nativeArchiveLimits});
      assert.equal(receipt.seedProductProtocol,'psc-checked-seed-products/2');
      assert.equal(receipt.seedResources.observed.frames,2);
      assert.equal(receipt.typeScriptToolInputs,undefined);
      assert.equal(artifactKey(receipt.wasmCanonical.selection),artifactKey(policy.identity));
      const binaryBytes=await readFile(outputPath),interfaceBytes=await readFile(path.join(dir,'out.interface-ir.json'));
      const binary={bytes:binaryBytes,identity:artifactId(binaryBytes,'wasm-binary','webassembly-core/1')};
      const interfaceArtifact={bytes:interfaceBytes,identity:receipt.wasmCanonical.interface};
      const binding=JSON.parse(await readFile(path.join(dir,'out.wasm-abi-plan.json')));
      const api=instantiateCanonicalExports({binary,expectedBinaryId:binary.identity,
        interfaceArtifact,expectedInterfaceId:interfaceArtifact.identity,interfaceName:'api',
        bindings:binding.bindings.map(({functionName,coreExport})=>({functionName,coreExport}))});
      assert.deepEqual(Object.keys(api.exports),['echo-word']);
      const value=wordBits===32?4294967295:18446744073709551615n;
      assert.equal(api.exports['echo-word'](value),value);
      assert.equal(binding.wordBits,wordBits);
      const graph=JSON.parse(await readFile(path.join(dir,'out.build-graph.json')));
      const replay=await verifyObservedBuildArchive(await readFile(path.join(dir,'out.build-archive.json')),
        {expectedGraphId:receipt.buildGraph,allowedAssumptions:allowedAssumptionsFromGraph(graph),
          resourceLimits:nativeArchiveLimits});
      assert.equal(replay.kind,'accepted',replay.reason);
      assert.equal(replay.wasmCanonicalProjections.length,1);
      assert.equal(replay.wasmCanonicalSignatures[0].targetSignaturesChecked,true);
      assert.equal(replay.preservationVerified,false);
      const descriptor=JSON.parse(await readFile(path.join(dir,'out.backend-descriptor.json')));
      assert.equal(artifactKey(descriptor.interfaceAdapterId),artifactKey(policy.identity));
      const bundle=JSON.parse(await readFile(path.join(dir,'out.artifact-bundle.json')));
      assert.deepEqual(bundle.executableArtifacts.map(item=>item.role),['canonical-scalar-binary']);
      const envelope=JSON.parse(await readFile(path.join(dir,'out.evidence-envelope.json')));
      for(const id of Object.values(receipt.wasmCanonical))
        assert.ok(envelope.targetAdapters.some(actual=>artifactKey(actual)===artifactKey(id)));
      assert.deepEqual(await readFile(path.join(dir,'out.wasm-export-selection.json')),policy.bytes);
    }finally{
      if(previousCli===undefined)delete process.env.PSC_TYPESCRIPT_CLI;else process.env.PSC_TYPESCRIPT_CLI=previousCli;
      await rm(dir,{recursive:true,force:true});
    }
  });

for (const products of ['source', 'metadata']) test('checked Rust ' + products + ' publishes source and shared evidence without invoking a target compiler',
  { skip: !native }, async () => {
    const dir = await mkdtemp(path.join(tmpdir(), 'psc-rust-source-routing-'));
    const oldCli = process.env.PSC_TYPESCRIPT_CLI;
    try {
      process.env.PSC_TYPESCRIPT_CLI = path.join(dir, 'typescript-must-not-be-loaded');
      const entryPath = path.join(dir, 'Empty.lean'), compilerPath = path.join(dir, 'fixture.mjs'), outputPath = path.join(dir, 'out.rs');
      await writeFile(entryPath, '-- empty admissions; transport fixture only\n');
      await writeFile(compilerPath, buildRoutingCompiler({ executableOnly: products === 'source' }));
      const receipt = await buildChecked({ entryPath, compilerPath, outputPath, backend: 'rust', products, kernel: 'lean434' });
      assert.equal(await readFile(outputPath, 'utf8'), 'pub fn answer() -> u32 { 42 }');
      assert.equal(receipt.rustTarget.compilerInvoked, false); assert.equal(receipt.rustTarget.nativeBinaryProduced, false);
      assert.equal(receipt.typeScriptSha256, undefined);
      assert.deepEqual((await import(pathToFileURL(compilerPath).href)).counts(), { preparations: 1, emissions: 1, declarations: 0 });
      const graph = JSON.parse(await readFile(path.join(dir, 'out.build-graph.json')));
      assertPasses(graph, ['psc-verified-ir-to-rust/1', 'psc-validate-runtime-ir/1']);
      assert.equal(passIds(graph).includes('typescript-to-es2022/1'), false);
      assert.equal(graph.entries.some(entry => entry.identity.domain === 'native-output'), false);
      const bundle = JSON.parse(await readFile(path.join(dir, 'out.artifact-bundle.json')));
      assert.deepEqual(bundle.executableArtifacts.map(item => item.role), ['target-source']);
      assert.equal(bundle.executableArtifacts[0].artifact.domain, 'rust-source');
      assert.equal(Boolean(receipt.publicApi), products === 'metadata');
      assert.equal(Boolean(receipt.erasureMap), products === 'metadata');
      const archived = await verifyObservedBuildArchive(await readFile(path.join(dir, 'out.build-archive.json')),
        { expectedGraphId: receipt.buildGraph, allowedAssumptions: allowedAssumptionsFromGraph(graph) });
      assert.equal(archived.kind, 'accepted', archived.reason); assert.equal(archived.semanticClaimsVerified, false);
    } finally {
      if (oldCli === undefined) delete process.env.PSC_TYPESCRIPT_CLI; else process.env.PSC_TYPESCRIPT_CLI = oldCli;
      await rm(dir, { recursive: true, force: true });
    }
  });

test('Rust source route rejects incompatible policy before loading files', async () => {
  for (const [options, pattern] of [
    [{ jsAbiPolicyPath: 'missing-policy' }, /JS_ABI_TARGET/],
    [{ outputPath: 'out.js' }, /OUTPUT_KIND/],
  ]) await assert.rejects(buildChecked({ entryPath: 'missing-source', outputPath: 'out.rs', backend: 'rust', ...options }), pattern);
});

test('actual native generic Rust source publishes a shared source bundle with bounded version-3 transport',
  { skip: !native }, async () => {
    const dir = await mkdtemp(path.join(tmpdir(), 'psc-native-rust-source-'));
    try {
      const entryPath = path.join(dir, 'Main.lean'), outputPath = path.join(dir, 'out.rs');
      await writeFile(entryPath, 'def identity (A : Type) (value : A) : A := value\ndef answer : Nat := identity Nat 42\n');
      const receipt = await buildChecked({ entryPath, outputPath, seedPath: seed, kernel: 'lean434',
        backend: 'rust', products: 'metadata', archiveResourceLimits: nativeArchiveLimits });
      assert.equal(receipt.seedProductProtocol, 'psc-checked-seed-products/3');
      assert.equal(receipt.seedResources.observed.frames, 2);
      assert.equal(receipt.rustTarget.compilerInvoked, false);
      assert.match(await readFile(outputPath, 'utf8'), /pub fn identity/);
      assert.ok(receipt.publicApi && receipt.erasureMap);
      const graph = JSON.parse(await readFile(path.join(dir, 'out.build-graph.json')));
      assertPasses(graph, ['psc-verified-ir-to-rust/1']);
      const bundle = JSON.parse(await readFile(path.join(dir, 'out.artifact-bundle.json')));
      assert.deepEqual(bundle.executableArtifacts.map(item => item.role), ['target-source']);
      const replay = await verifyObservedBuildArchive(await readFile(path.join(dir, 'out.build-archive.json')),
        { expectedGraphId: receipt.buildGraph, allowedAssumptions: allowedAssumptionsFromGraph(graph), resourceLimits: nativeArchiveLimits });
      assert.equal(replay.kind, 'accepted', replay.reason); assert.equal(replay.preservationVerified, false);
    } finally { await rm(dir, { recursive: true, force: true }); }
  });
