import { projectSourceSignature } from './public-api-signature.mjs';
import { bindObservedBuildContext } from './observed-build-context.mjs';
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { SourceMap } from 'node:module';
import { mkdtemp, writeFile, rm, readFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { resolveTypeScriptCli, pinnedTypeScriptVersionText } from './typescript-cli.mjs';
import { uniformSpecializationArtifact, verifyUniformSpecialization, uniformJsRepresentationProfile } from './uniform-specialization.mjs';
import { createDirectJsDeclarations, directJsUniformDeclarationProfile } from './js-declarations.mjs';
import { publicApiArtifact } from './public-api-artifact.mjs';
import { spawnSync } from 'node:child_process';
import { canonicalBytes, canonicalArtifact, artifactKey, artifactId, passDefinition, recordPassExecution } from './artifact-evidence.mjs';
import { runtimeInterfaceArtifact, verifyRuntimeInterfaceProjection } from './runtime-interface-artifact.mjs';
import { decodeJsGeneratedPositions } from './js-generated-positions.mjs';
import { decodeErasureDeclarations } from './erasure-declarations.mjs';
import { decodeIrArtifact, checkedIrStageArtifacts } from './ir-artifact.mjs';
import { checkedTargetIrStageArtifacts } from './target-ir-artifact.mjs';
import { createCheckedBuildGraph } from './checked-build-evidence.mjs';
import { packObservedBuildArchive, verifyObservedBuildArchive } from './observed-build-archive.mjs';


function checkPortableSourceSignatures(staged) {
  const api = JSON.parse(staged.publicApi);
  const expected = api[2].map(declaration => {
    assert.equal(declaration[0], 'constant');
    return projectSourceSignature(declaration[4]);
  });
  assert.deepEqual(Buffer.from(staged.sourceSignatures), canonicalBytes(expected));
}

async function checkDeclarationConsumer(product, consumer) {
  const directory = await mkdtemp(path.join(tmpdir(), 'psc-direct-declarations-'));
  try {
    const cli = resolveTypeScriptCli();
    const version = spawnSync(process.execPath, [cli, '--version'], { encoding: 'utf8', timeout: 30000 });
    assert.equal(version.status, 0, version.stderr);
    assert.equal(version.stdout.trim(), pinnedTypeScriptVersionText);
    await writeFile(path.join(directory, 'module.d.ts'), product.declarations.bytes);
    await writeFile(path.join(directory, 'consumer.ts'), consumer);
    const result = spawnSync(process.execPath, [cli, '--target', 'ES2022', '--module', 'NodeNext',
      '--moduleResolution', 'NodeNext', '--strict', '--noEmit', '--pretty', 'false', 'consumer.ts'],
    { cwd: directory, encoding: 'utf8', timeout: 30000, maxBuffer: 4 * 1024 * 1024 });
    assert.equal(result.status, 0, result.error?.message ?? result.stdout + result.stderr);
    // This consumer check is separate evidence; generation itself never called tsc.
    assert.equal(JSON.parse(product.binding.bytes).declarationTargetAccepted, false);
    assert.equal(JSON.parse(product.binding.bytes).globalPreservationProved, false);
  } finally { await rm(directory, { recursive: true, force: true }); }
}

function emitted(flag) {
  const file = '.lake/build/bin/pscv_ir_encoding_tests' + (process.platform === 'win32' ? '.exe' : '');
  const result = spawnSync(file, [flag], { encoding: 'utf8', timeout: 30000, maxBuffer: 32 * 1024 * 1024 });
  assert.equal(result.status, 0, result.error?.message ?? result.stderr);
  return Buffer.from(result.stdout.trim());
}
test('portable IR encoding preserves exact constructor shape, Unicode and arbitrary integers', () => {
  const bytes = emitted('--raw'), value = decodeIrArtifact(bytes);
  assert.deepEqual(canonicalBytes(value), bytes);
  assert.deepEqual(value, ['psc-runtime-ir-json/1', [], [], [], [
    ['huge', [], [], ['primitive','nat'], ['literal',['natural','123456789012345678901234567890']]],
    ['negative', [], [], ['primitive','int'], ['literal',['integer','-123']]],
    ['unicode', [], [], ['primitive','string'], ['literal',['string','a\n"😀']]],
    ['unknown', [], [], ['unknown'], ['var','unresolved']],
  ]]);
  assert.throws(() => decodeIrArtifact(bytes, { maxBytes: 1 }), /export-bytes/);
  const bad = structuredClone(value);
  bad[4][0][4][1][1] = '01';
  assert.throws(() => decodeIrArtifact(canonicalBytes(bad)), /SCHEMA/);
  bad[4][0][4] = ['notAnExpression'];
  assert.throws(() => decodeIrArtifact(canonicalBytes(bad)), /SCHEMA/);
  assert.throws(() => decodeIrArtifact(Buffer.concat([bytes, Buffer.from('\n')])), /not-canonical/);
});

test('actual erasure/validation/emission snapshots form separately bound archived pass edges', async () => {
  const staged = JSON.parse(emitted('--stages'));
  decodeErasureDeclarations(Buffer.from(staged.erasureCorrespondence),
    { publicApi: Buffer.from(staged.publicApi), runtimeIr: Buffer.from(staged.runtimeIr) });
  assert.match(staged.typeScript, /export const answer/);
  const snapshots = checkedIrStageArtifacts(staged);
  assert.deepEqual(snapshots.runtimeIr.bytes, snapshots.verifiedIr.bytes);
  assert.notEqual(artifactKey(snapshots.runtimeIr.identity), artifactKey(snapshots.verifiedIr.identity));
  const inputs = { sourceKind: 'lean', sources: ['def answer : Nat := 42\n'],
    admissions: '{"admissions":[],"format":"proofscript-checked-admissions","version":2}',
    typeScript: staged.typeScript, irStages: staged,
    compilerBytes: Buffer.from('fixture provenance: actual stage output with synthetic admission/implementation metadata'),
    compilerKind: 'fixture', provider: { profile: 'fixture' }, providerSecurity: { profile: 'fixture' },
    kernelContract: { id: 'fixture' }, hostSources: [], runtime: { implementation: 'fixture' } };
  const built = createCheckedBuildGraph(inputs);
  assert.equal(built.graph.coverage, 'observed-erasure-validation-and-composite-backend-edges');
  assert.equal(built.graph.executions.length, 5);
  for (const artifact of Object.values(snapshots)) assert.deepEqual(built.artifacts.get(artifactKey(artifact.identity)), artifact.bytes);
  const definitions = built.graph.entries.filter(entry => entry.identity.domain === 'pass-definition').map(entry => entry.canonicalValue);
  assert.deepEqual(definitions.map(item => item.passId), [
    'psc-prepare-and-check/1', 'psc-erase-checked-core/1', 'psc-validate-runtime-ir/1', 'psc-project-runtime-interface/1', 'psc-verified-ir-to-typescript/1',
  ]);
  const archive = packObservedBuildArchive(built);
  const replay = await verifyObservedBuildArchive(archive.bytes, { expectedGraphId: built.identity,
    allowedAssumptions: [...new Set(definitions.flatMap(item => item.assumptionIds))] });
  assert.equal(replay.kind, 'accepted', replay.reason);
  assert.equal(replay.preservationVerified, false);
  assert.equal(replay.runtimeInterfaceProjections.length, 1);
  assert.deepEqual(replay.runtimeInterfaceProjections[0].interfaceId, built.runtimeInterface);
  const changed = JSON.parse(staged.verifiedIr);
  changed[4][0][0] = 'renamed';
  assert.throws(() => createCheckedBuildGraph({ ...inputs, irStages: { ...staged, verifiedIr: canonicalBytes(changed).toString() } }),
    /VALIDATION_CHANGED_IR/);
});

test('actual direct JavaScript specialization is revalidated, executed and archived as a separate pass', async () => {
  const staged = JSON.parse(emitted('--js-stages'));
  decodeJsGeneratedPositions(Buffer.from(staged.generatedPositions),
    { javaScript: staged.javaScript, jsIr: Buffer.from(staged.jsIr) });
  decodeErasureDeclarations(Buffer.from(staged.erasureCorrespondence),
    { publicApi: Buffer.from(staged.publicApi), runtimeIr: Buffer.from(staged.runtimeIr) });
  const snapshots = checkedIrStageArtifacts(staged);
  const targets = checkedTargetIrStageArtifacts(staged);
  assert.deepEqual(snapshots.runtimeIr.bytes, snapshots.verifiedIr.bytes);
  assert.notDeepEqual(snapshots.verifiedIr.bytes, snapshots.specializedIr.bytes);
  assert.equal(targets.jsIr.identity.contract, 'psc-js-ir-json/1');
  const specialized = decodeIrArtifact(snapshots.specializedIr.bytes);
  assert.ok(specialized[4].every(declaration => declaration[1].length === 0));
  const executable = await import('data:text/javascript;base64,' + Buffer.from(staged.javaScript).toString('base64'));
  assert.equal(executable.answer, 42n);
  const inputs = { sourceKind: 'lean', sources: ['actual source is in the native fixture; this graph uses synthetic audit metadata'],
    admissions: '{"admissions":[],"format":"proofscript-checked-admissions","version":2}',
    directJavaScript: staged.javaScript, irStages: staged, generatedPositions: staged.generatedPositions,
    compilerBytes: Buffer.from('actual stage/output bytes with synthetic admission and implementation provenance'),
    compilerKind: 'fixture', provider: { profile: 'fixture' }, providerSecurity: { profile: 'fixture' },
    kernelContract: { id: 'fixture' }, hostSources: [], runtime: { implementation: 'fixture' } };
  const built = createCheckedBuildGraph(inputs);
  const definitions = built.graph.entries.filter(entry => entry.identity.domain === 'pass-definition').map(entry => entry.canonicalValue);
  assert.deepEqual(definitions.map(item => item.passId), ['psc-prepare-and-check/1', 'psc-erase-checked-core/1',
    'psc-validate-runtime-ir/1', 'psc-project-runtime-interface/1', 'psc-verified-ir-to-js-abi-plan/1',
    'psc-pass-specialize/1', 'psc-specialized-ir-to-js-ir/1', 'psc-js-ir-to-javascript/1']);
  for (const snapshot of [...Object.values(snapshots), ...Object.values(targets)])
    assert.deepEqual(built.artifacts.get(artifactKey(snapshot.identity)), snapshot.bytes);
  const archive = packObservedBuildArchive(built);
  const replay = await verifyObservedBuildArchive(archive.bytes, { expectedGraphId: built.identity,
    allowedAssumptions: [...new Set(definitions.flatMap(item => item.assumptionIds))] });
  assert.equal(replay.kind, 'accepted', replay.reason);
  assert.equal(replay.preservationVerified, false);
  assert.equal(replay.semanticClaimsVerified, false);
  assert.equal(replay.specializationCorrespondences.length, 1);
  assert.equal(replay.targetIrArtifacts.length, 1);
  assert.equal(replay.targetIrArtifacts[0].kind, 'js-ir');
  assert.equal(replay.specializationCorrespondences[0].correspondenceChecked, true);
  assert.equal(built.generatedPositionMap.identity.contract, 'psc-js-generated-position-map/1');
  const canonicalAdmissionsId = artifactId(Buffer.from(inputs.admissions), 'canonical-admissions', 'proofscript-checked-admissions/2');
  const pscvCertificate = canonicalArtifact({ contract: 'pscv-cert/1', canonicalAdmissionsId, fixture: true }, 'pscv-cert', 'pscv-cert/1');
  const certifiedSourceArtifact = canonicalArtifact({ contract: 'psc-certified-source/1', canonicalAdmissionsId,
    certificateId: pscvCertificate.identity, fixture: true }, 'certified-source', 'psc-certified-source/1');
  const observed = createCheckedBuildGraph({ ...inputs, sources: [staged.source], publicApi: staged.publicApi,
    declarationOrigins: staged.declarationOrigins, erasureCorrespondence: staged.erasureCorrespondence,
    pscvCertificate, certifiedSourceArtifact });
  const lineage = JSON.parse(observed.declarationLineage.bytes);
  assert.equal(lineage.edges.length, specialized[4].length);
  assert.ok(lineage.edges.some(edge => edge[2] === 0));
  assert.equal(lineage.expressionCorrespondenceChecked, false);
  const sourceMapValue = JSON.parse(observed.directSourceMap.sourceMap.bytes), sourceMapConsumer = new SourceMap(sourceMapValue);
  const originTable = JSON.parse(staged.declarationOrigins), positionsTable = JSON.parse(staged.generatedPositions);
  for (const edge of lineage.edges) {
    const start = positionsTable[2][edge[0]][1], source = originTable[3][edge[3]];
    const found = sourceMapConsumer.findEntry(start[1], start[2]);
    assert.equal(found.originalLine, source[2][1] - 1);
    assert.equal(found.originalColumn, 0);
  }
  assert.equal(sourceMapValue.x_psc_expressionOrigins, false);
  assert.ok(observed.graph.entries.some(entry => entry.source.suffix === '.js.map'));
  const observedDefinitions = observed.graph.entries.filter(entry => entry.identity.domain === 'pass-definition').map(entry => entry.canonicalValue);
  const observedArchive = packObservedBuildArchive(observed);
  const observedReplay = await verifyObservedBuildArchive(observedArchive.bytes, { expectedGraphId: observed.identity,
    allowedAssumptions: [...new Set(observedDefinitions.flatMap(item => item.assumptionIds))] });
  assert.equal(observedReplay.kind, 'accepted', observedReplay.reason);
  assert.equal(observedReplay.preservationVerified, false);
  const map = JSON.parse(built.artifacts.get(artifactKey(built.specializationInstances.identity)));
  assert.ok(map.instances.some(item => item[0] === 'declaration' && item[1] === 'forward'));
  assert.deepEqual(map.outputId, snapshots.specializedIr.identity);
  const specializationPass = definitions.find(item => item.passId === 'psc-pass-specialize/1');
  assert.equal(specializationPass.validatorId, 'psc-specialization-correspondence/1');
  assert.throws(() => createCheckedBuildGraph({ ...inputs, irStages: { runtimeIr: staged.runtimeIr, verifiedIr: staged.verifiedIr } }),
    /JS_STAGES_REQUIRED/);
  assert.throws(() => createCheckedBuildGraph({ ...inputs, typeScript: 'competing backend' }), /MIXED_BACKEND_PATHS/);
});

test('actual direct Wasm retains specialization snapshots and replays correspondence with unchanged emitted bytes', async () => {
  const staged = JSON.parse(emitted('--wasm-stages')), binary = Uint8Array.from(staged.wasm);
  decodeErasureDeclarations(Buffer.from(staged.erasureCorrespondence),
    { publicApi: Buffer.from(staged.publicApi), runtimeIr: Buffer.from(staged.runtimeIr) });
  const snapshots = checkedIrStageArtifacts(staged);
  const targets = checkedTargetIrStageArtifacts(staged);
  assert.notDeepEqual(snapshots.verifiedIr.bytes, snapshots.specializedIr.bytes);
  assert.equal(targets.wasmIr.identity.contract, 'psc-wasm-ir-json/1');
  assert.equal(WebAssembly.validate(binary), true);
  const { instance } = await WebAssembly.instantiate(binary, {});
  assert.equal(instance.exports.answer(42), 42);
  const inputs = { sourceKind: 'lean', sources: ['actual generic UInt32 fixture with synthetic archive admission/implementation metadata'],
    admissions: '{"admissions":[],"format":"proofscript-checked-admissions","version":2}',
    directWasm: binary, irStages: staged,
    compilerBytes: Buffer.from('actual stage/output bytes; synthetic provenance'), compilerKind: 'fixture',
    provider: { profile: 'fixture' }, providerSecurity: { profile: 'fixture' }, kernelContract: { id: 'fixture' },
    hostSources: [], runtime: { implementation: 'fixture' } };
  const built = createCheckedBuildGraph(inputs), archive = packObservedBuildArchive(built);
  const definitions = built.graph.entries.filter(entry => entry.identity.domain === 'pass-definition').map(entry => entry.canonicalValue);
  assert.equal(definitions.length, 7);
  assert.equal(built.specializationInstances.identity.contract, 'psc-specialization-instance-map/1');
  assert.deepEqual(definitions.slice(-2).map(item => item.passId), [
    'psc-specialized-ir-to-wasm-ir/1',
    'psc-wasm-ir-to-wasm/1',
  ]);
  const replay = await verifyObservedBuildArchive(archive.bytes, { expectedGraphId: built.identity,
    allowedAssumptions: [...new Set(definitions.flatMap(item => item.assumptionIds))] });
  assert.equal(replay.kind, 'accepted', replay.reason);
  assert.equal(replay.specializationCorrespondences.length, 1);
  assert.equal(replay.targetIrArtifacts.length, 1);
  assert.equal(replay.targetIrArtifacts[0].kind, 'wasm-ir');
  assert.equal(replay.preservationVerified, false);
  assert.equal(replay.semanticClaimsVerified, false);
  assert.throws(() => createCheckedBuildGraph({ ...inputs, directJavaScript: 'competing output' }), /MIXED_BACKEND_PATHS/);
  assert.throws(() => createCheckedBuildGraph({ ...inputs, directWasm: staged.wasm }), /WASM_BYTES/);
  assert.throws(() => createCheckedBuildGraph({ ...inputs, irStages: undefined }), /WASM_STAGES_REQUIRED/);
});

test('portable and independent runtime-interface projections agree and distinguish signature drift from body edits', async () => {
  const staged = JSON.parse(emitted('--stages'));
  const verified = checkedIrStageArtifacts(staged).verifiedIr;
  const interfaceArtifact = runtimeInterfaceArtifact(verified);
  assert.deepEqual(interfaceArtifact.bytes, emitted('--interface'));
  const verification = verifyRuntimeInterfaceProjection(verified, interfaceArtifact);
  assert.equal(verification.behavioralReuse, false);
  const module = decodeIrArtifact(verified.bytes);
  function from(value) {
    const bytes = canonicalBytes(value);
    return { bytes, identity: artifactId(bytes, 'verified-ir', 'psc-runtime-ir-json/1') };
  }
  const bodyEdit = structuredClone(module);
  bodyEdit[4].find(declaration => declaration[0] === 'answer')[4] = ['literal', ['natural', '43']];
  assert.equal(artifactKey(runtimeInterfaceArtifact(from(bodyEdit)).identity), artifactKey(interfaceArtifact.identity));
  const signatureEdit = structuredClone(module);
  signatureEdit[4].find(declaration => declaration[0] === 'answer')[3] = ['primitive', 'int'];
  assert.notEqual(artifactKey(runtimeInterfaceArtifact(from(signatureEdit)).identity), artifactKey(interfaceArtifact.identity));
  assert.throws(() => verifyRuntimeInterfaceProjection(from(signatureEdit), interfaceArtifact), /INTERFACE_PROJECTION/);
  assert.throws(() => runtimeInterfaceArtifact(checkedIrStageArtifacts(staged).runtimeIr), /INPUT_CONTRACT/);
  assert.throws(() => runtimeInterfaceArtifact(verified, { maxBytes: 1 }), /export-bytes/);
  // Fully re-hash a false projection, including its pass and consumer-pinned
  // graph. Byte integrity succeeds; the independent relation check must fail.
  const implementation = canonicalArtifact({ fixture: 'false-projection-proposal' }, 'implementation', 'fixture/1');
  const wrong = runtimeInterfaceArtifact(from(signatureEdit));
  const definition = passDefinition({ passId: 'psc-project-runtime-interface/1', version: 1,
    inputContract: verified.identity.contract, outputContract: wrong.identity.contract,
    semanticRelationId: 'psc-runtime-interface-projection/1', resourceContractId: 'fixture/1',
    determinismClass: 'fixture', totalityClass: 'fixture', implementationId: implementation.identity,
    validatorId: null, theoremIds: [], assumptionIds: [] });
  const execution = recordPassExecution({ definition, inputs: [verified], outputs: [wrong],
    parameters: {}, semanticIdentity: { fixture: true }, resourcePolicy: { fixture: true } });
  const items = [implementation, verified, wrong, definition, execution.action, execution];
  const graphValue = { schemaVersion: 1, contract: 'psc-observed-build-graph/1', authority: 'audit-record-only',
    entries: items.map(item => ({ identity: item.identity, source: { kind: 'archive-required' },
      ...([definition, execution.action, execution].includes(item) ? { canonicalValue: JSON.parse(item.bytes) } : {}) })),
    executions: [execution.identity], coverage: 'observed-composite-edges', remaining: ['synthetic malicious fixture'] };
  const graph = canonicalArtifact(graphValue, 'build-graph', 'psc-observed-build-graph/1');
  const archive = packObservedBuildArchive({ ...graph, artifacts: new Map(items.map(item => [artifactKey(item.identity), item.bytes])) });
  const rejected = await verifyObservedBuildArchive(archive.bytes, { expectedGraphId: graph.identity, allowedAssumptions: [] });
  assert.equal(rejected.kind, 'rejectedInvalid');
  assert.match(rejected.reason, /RUNTIME_INTERFACE_PROJECTION/);
});

test('native generated coordinates count UTF-16, all ECMAScript line terminators and CRLF across chunks', () => {
  assert.deepEqual(JSON.parse(emitted('--generated-position-cursor')), [[5, 0, 3], [16, 3, 1]]);
});

test('actual source signatures produce direct declarations accepted by the pinned TypeScript consumer', async () => {
  const staged = JSON.parse(emitted('--js-declaration-stages'));
  checkPortableSourceSignatures(staged);
  const snapshots = checkedIrStageArtifacts(staged), targets = checkedTargetIrStageArtifacts(staged);
  const textRecord = (text, domain, contract) => {
    const bytes = Buffer.from(text); return { bytes, identity: artifactId(bytes, domain, contract) };
  };
  const product = createDirectJsDeclarations({ subjects: {
    publicApi: publicApiArtifact(staged.publicApi),
    erasureTable: textRecord(staged.erasureCorrespondence, 'erasure-table', 'psc-erasure-declarations/1'),
    runtimeIr: snapshots.runtimeIr, verifiedIr: snapshots.verifiedIr, specializedIr: snapshots.specializedIr,
    jsIr: targets.jsIr, javaScript: textRecord(staged.javaScript, 'javascript-output', 'psc-direct-javascript/es2022'),
  } });
  const executable = await import('data:text/javascript;base64,' + Buffer.from(staged.javaScript).toString('base64'));
  assert.equal(executable.answer, 42n);
  assert.equal(executable.applyNat(executable.echoNat, 17n), 17n);
  assert.deepEqual(executable.echoArray([3n]), [3n]);
  assert.deepEqual(Buffer.from(staged.portableDeclarations), product.declarations.bytes);
  await checkDeclarationConsumer(product, [
      'import { answer, echoNat, applyNat, echoArray, greeting } from "./module.js";',
      'const a: bigint = echoNat(answer);',
      'const b: bigint = applyNat(echoNat, 7n);',
      'const c: Array<bigint> = echoArray([1n, 2n]);',
      'const s: string = greeting;',
      '// @ts-expect-error source Nat uses bigint, not number',
      'echoNat(3);',
      '// @ts-expect-error source array element type remains Nat',
      'echoArray(["bad"]);',
      '// @ts-expect-error function parameter retains its result type',
      'applyNat((value: bigint): string => "bad", 3n);',
    ].join('\n'));
});

test('uniform JS representation retains generic exports and strips only checked static type arguments', async () => {
  const staged = JSON.parse(emitted('--js-uniform-stages'));
  checkPortableSourceSignatures(staged);
  const snapshots = checkedIrStageArtifacts(staged), targets = checkedTargetIrStageArtifacts(staged);
  const selected = uniformSpecializationArtifact(staged.uniformSpecializedIr);
  const relation = verifyUniformSpecialization(snapshots.verifiedIr, selected);
  const record = (text, domain, contract) => {
    const bytes = Buffer.from(text); return { bytes, identity: artifactId(bytes, domain, contract) };
  };
  const product = createDirectJsDeclarations({ profile: directJsUniformDeclarationProfile, subjects: {
    publicApi: publicApiArtifact(staged.publicApi),
    erasureTable: record(staged.erasureCorrespondence, 'erasure-table', 'psc-erasure-declarations/1'),
    runtimeIr: snapshots.runtimeIr, verifiedIr: snapshots.verifiedIr, uniformSpecializedIr: selected,
    jsIr: targets.jsIr, javaScript: record(staged.javaScript, 'javascript-output', 'psc-direct-javascript/es2022'),
  } });
  assert.deepEqual(Buffer.from(staged.portableDeclarations), product.declarations.bytes);
  await checkDeclarationConsumer(product, [
    'import { forward, unused, applyValue, echoArray, mapValues, answer, choice } from "./module.js";',
    'const a: bigint = forward(answer);',
    'const b: string = unused("retained");',
    'const c: boolean = applyValue((value: bigint): boolean => value === 7n, 7n);',
    'const d: Array<string> = mapValues((value: bigint): string => value.toString(), [1n, 2n]);',
    'const e: Array<boolean> = echoArray([choice]);',
    '// @ts-expect-error generic identity retains the actual argument type',
    'const bad: number = forward("text");',
    '// @ts-expect-error generic array mapping checks callback element type',
    'mapValues((value: string): string => value, [1n]);',
  ].join('\n'));

  const admissions = '{"admissions":[],"format":"proofscript-checked-admissions","version":2}';
  const canonicalAdmissionsId = artifactId(Buffer.from(admissions), 'canonical-admissions', 'proofscript-checked-admissions/2');
  const pscvCertificate = canonicalArtifact({ contract: 'pscv-cert/1', canonicalAdmissionsId, fixture: true }, 'pscv-cert', 'pscv-cert/1');
  const certifiedSourceArtifact = canonicalArtifact({ contract: 'psc-certified-source/1', canonicalAdmissionsId,
    certificateId: pscvCertificate.identity, fixture: true }, 'certified-source', 'psc-certified-source/1');
  const observed = createCheckedBuildGraph({
    sourceKind: 'lean', sources: [staged.source], admissions,
    declarationOrigins: staged.declarationOrigins,
    directJavaScript: staged.javaScript, irStages: staged, generatedPositions: staged.generatedPositions,
    publicApi: staged.publicApi, erasureCorrespondence: staged.erasureCorrespondence,
    declarationProfile: directJsUniformDeclarationProfile, javaScriptRepresentation: uniformJsRepresentationProfile,
    pscvCertificate, certifiedSourceArtifact,
    compilerBytes: Buffer.from('synthetic provenance; no live acceptance claim'), compilerKind: 'fixture',
    provider: { profile: 'fixture' }, providerSecurity: { profile: 'fixture' }, kernelContract: { id: 'fixture' },
    hostSources: [], runtime: { implementation: 'fixture' },
  });
  const backendRegistry = canonicalArtifact(JSON.parse(await readFile(new URL('../contracts/backends/BACKEND_REGISTRY_V1.json', import.meta.url))),
    'backend-registry', 'psc-backend-registry/1');
  const languageAuthority = canonicalArtifact({ languageEdition: 'fixture' }, 'language-authority', 'psc-language-authority-snapshot/1');
  const built = bindObservedBuildContext(observed, { backendRegistry, languageAuthority,
    backendId: 'javascript', javaScriptRepresentation: uniformJsRepresentationProfile });
  assert.deepEqual(built.directDeclarations.declarations.bytes, product.declarations.bytes);
  assert.equal(built.declarationLineage.identity.contract, 'psc-js-uniform-declaration-lineage/1');
  assert.equal(built.directSourceMap.recipe.identity.contract, 'psc-direct-javascript-source-map-recipe/2');
  const sourceMap = new SourceMap(JSON.parse(built.directSourceMap.sourceMap.bytes));
  const sourceOrigins = JSON.parse(staged.declarationOrigins)[3], generated = JSON.parse(staged.generatedPositions)[2];
  generated.forEach((entry, index) => {
    const mapped = sourceMap.findEntry(entry[1][1], entry[1][2]);
    assert.equal(mapped.originalLine, sourceOrigins[index][2][1] - 1);
    assert.equal(mapped.originalColumn, sourceOrigins[index][2][2] - 1);
  });
  assert.equal(built.specializationInstances, undefined);
  assert.ok(built.generatedPositionMap);
  const archive = packObservedBuildArchive(built);
  const definitions = built.graph.entries.filter(entry => entry.identity.domain === 'pass-definition').map(entry => entry.canonicalValue);
  const replay = await verifyObservedBuildArchive(archive.bytes, { expectedGraphId: built.identity,
    allowedAssumptions: [...new Set(definitions.flatMap(item => item.assumptionIds))] });
  assert.equal(replay.kind, 'accepted', replay.reason);
  assert.equal(replay.uniformSpecializationCorrespondences.length, 1);
  assert.equal(replay.buildContext.artifactBundle.profileSelection.bindingVerified, true);
  assert.equal(replay.buildContext.queryKeysVerified, true);
  assert.equal(replay.preservationVerified, false);

  assert.equal(relation.bytesPreserved, true);
  assert.equal(relation.targetRepresentationAdequacyProved, false);
  const runtime = JSON.parse(staged.runtimeIr), uniform = JSON.parse(staged.uniformSpecializedIr);
  assert.deepEqual(uniform[2], runtime);
  assert.ok(runtime[4].some(item => item[0] === 'unused' && item[1].length === 1));
  assert.deepEqual(JSON.parse(targets.jsIr.bytes)[2].map(item => item[0]), runtime[4].map(item => item[0]));
  decodeJsGeneratedPositions(Buffer.from(staged.generatedPositions),
    { javaScript: staged.javaScript, jsIr: Buffer.from(staged.jsIr) });
  const executable = await import('data:text/javascript;base64,' + Buffer.from(staged.javaScript).toString('base64'));
  const closed = await import('data:text/javascript;base64,' + Buffer.from(staged.closedJavaScript).toString('base64'));
  assert.equal(executable.answer, 42n); assert.equal(executable.choice, true);
  assert.equal(executable.answer, closed.answer); assert.equal(executable.choice, closed.choice);
  assert.equal(typeof executable.forward, 'function'); assert.equal(typeof executable.unused, 'function');
  assert.equal(closed.unused, undefined);
  const value = Object.freeze({ marker: 7 });
  assert.equal(executable.forward(value), value); assert.equal(executable.unused('retained'), 'retained');
  assert.equal(executable.applyValue(n => n.toString(), 17n), '17');
  assert.deepEqual(executable.echoArray([1n, 2n]), [1n, 2n]);
  assert.deepEqual(executable.mapValues(n => n.toString(), [1n, 2n]), ['1', '2']);
  const forgedValue = structuredClone(uniform); forgedValue[2][4].pop();
  const forgedBytes = canonicalBytes(forgedValue);
  const forged = { bytes: forgedBytes, identity: artifactId(forgedBytes, selected.identity.domain, selected.identity.contract) };
  assert.throws(() => verifyUniformSpecialization(snapshots.verifiedIr, forged), /PAYLOAD_CHANGED/);
  assert.throws(() => uniformSpecializationArtifact(canonicalBytes(['psc-uniform-specialized-ir/1', 'unknown', runtime])), /PROFILE/);
  assert.throws(() => verifyUniformSpecialization(snapshots.verifiedIr, selected, { maxBytes: 1 }), /RESOURCE_POLICY/);
});

test('portable source projection rejects ambiguous, dependent, higher-rank and exhausted products', () => {
  assert.equal(emitted('--source-signature-errors').toString(), 'PSCV_SOURCE_SIGNATURE_FAILURES: PASS');
});

test('portable declaration writer rejects invalid bindings and enforces exact resource bounds', () => {
  assert.match(emitted('--declaration-writer-errors').toString('utf8'), /PSCV_PORTABLE_DECLARATIONS: PASS/);
});

test('actual generic Rust source binds observed validation/emission edges in the common bundle', async () => {
  const staged = JSON.parse(emitted('--rust-stages'));
  decodeErasureDeclarations(Buffer.from(staged.erasureCorrespondence),
    { publicApi: Buffer.from(staged.publicApi), runtimeIr: Buffer.from(staged.runtimeIr) });
  const snapshots = checkedIrStageArtifacts(staged);
  assert.deepEqual(snapshots.runtimeIr.bytes, snapshots.verifiedIr.bytes);
  assert.ok(decodeIrArtifact(snapshots.verifiedIr.bytes)[4].some(decl => decl[0] === 'identity' && decl[1].length === 1));
  assert.match(staged.rustSource, /pub fn identity/);
  const inputs = { sourceKind: 'lean', sources: ['actual native fixture; synthetic source acceptance and implementation metadata'],
    admissions: '{"admissions":[],"format":"proofscript-checked-admissions","version":2}',
    rustSource: staged.rustSource, irStages: staged, compilerBytes: Buffer.from('fixture compiler provenance'),
    compilerKind: 'fixture', provider: { profile: 'fixture' }, providerSecurity: { profile: 'fixture' },
    kernelContract: { id: 'fixture' }, hostSources: [], runtime: { implementation: 'fixture' } };
  const observed = createCheckedBuildGraph(inputs);
  const backendRegistry = canonicalArtifact(JSON.parse(await readFile(new URL('../contracts/backends/BACKEND_REGISTRY_V1.json', import.meta.url))),
    'backend-registry', 'psc-backend-registry/1');
  const languageAuthority = canonicalArtifact({ languageEdition: 'fixture' }, 'language-authority', 'psc-language-authority-snapshot/1');
  const built = bindObservedBuildContext(observed, { backendRegistry, languageAuthority, backendId: 'rust' });
  const definitions = built.graph.entries.filter(entry => entry.identity.domain === 'pass-definition').map(entry => entry.canonicalValue);
  assert.deepEqual(definitions.map(item => item.passId), ['psc-prepare-and-check/1', 'psc-erase-checked-core/1',
    'psc-validate-runtime-ir/1', 'psc-project-runtime-interface/1', 'psc-verified-ir-to-rust/1']);
  assert.equal(built.executableArtifact.contract, 'psc-rust-source/2021');
  assert.equal(JSON.parse(built.backendDescriptor.bytes).externalToolchainId, null);
  const bundle = JSON.parse(built.artifactBundle.bytes);
  assert.deepEqual(bundle.executableArtifacts.map(item => item.role), ['target-source']);
  assert.equal(bundle.targetToolchainArtifacts.length, 0);
  assert.ok(!built.graph.entries.some(entry => ['specialized-ir', 'native-output', 'rust-ir'].includes(entry.identity.domain)));
  const archive = packObservedBuildArchive(built);
  const replay = await verifyObservedBuildArchive(archive.bytes, { expectedGraphId: built.identity,
    allowedAssumptions: [...new Set(definitions.flatMap(item => item.assumptionIds))] });
  assert.equal(replay.kind, 'accepted', replay.reason);
  assert.equal(replay.semanticClaimsVerified, false); assert.equal(replay.preservationVerified, false);
  assert.throws(() => createCheckedBuildGraph({ ...inputs, irStages: undefined }), /RUST_STAGES_REQUIRED/);
  assert.throws(() => createCheckedBuildGraph({ ...inputs, directWasm: new Uint8Array() }), /MIXED_BACKEND_PATHS/);
  assert.throws(() => createCheckedBuildGraph({ ...inputs, typeScript: '' }), /MIXED_BACKEND_PATHS/);
  assert.throws(() => createCheckedBuildGraph({ ...inputs, irStages: { ...staged, specializedIr: staged.verifiedIr } }),
    /RUST_UNSELECTED_STAGES/);
});
