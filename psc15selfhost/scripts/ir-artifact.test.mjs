import assert from 'node:assert/strict';
import { test } from 'node:test';
import { spawnSync } from 'node:child_process';
import { canonicalBytes, canonicalArtifact, artifactKey, artifactId, passDefinition, recordPassExecution } from './artifact-evidence.mjs';
import { runtimeInterfaceArtifact, verifyRuntimeInterfaceProjection } from './runtime-interface-artifact.mjs';
import { decodeJsGeneratedPositions } from './js-generated-positions.mjs';
import { decodeErasureDeclarations } from './erasure-declarations.mjs';
import { decodeIrArtifact, checkedIrStageArtifacts } from './ir-artifact.mjs';
import { checkedTargetIrStageArtifacts } from './target-ir-artifact.mjs';
import { createCheckedBuildGraph } from './checked-build-evidence.mjs';
import { packObservedBuildArchive, verifyObservedBuildArchive } from './observed-build-archive.mjs';

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
