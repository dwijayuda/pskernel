import assert from 'node:assert/strict';
import { test } from 'node:test';
import { spawnSync } from 'node:child_process';
import { canonicalBytes, canonicalArtifact, artifactKey, artifactId, passDefinition, recordPassExecution } from './artifact-evidence.mjs';
import { runtimeInterfaceArtifact, verifyRuntimeInterfaceProjection } from './runtime-interface-artifact.mjs';
import { decodeIrArtifact, checkedIrStageArtifacts } from './ir-artifact.mjs';
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
  const definitions = built.graph.entries.filter(entry => entry.identity.contract === 'psc-pass-definition/1').map(entry => entry.canonicalValue);
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
  const snapshots = checkedIrStageArtifacts(staged);
  assert.deepEqual(snapshots.runtimeIr.bytes, snapshots.verifiedIr.bytes);
  assert.notDeepEqual(snapshots.verifiedIr.bytes, snapshots.specializedIr.bytes);
  const specialized = decodeIrArtifact(snapshots.specializedIr.bytes);
  assert.ok(specialized[4].every(declaration => declaration[1].length === 0));
  const executable = await import('data:text/javascript;base64,' + Buffer.from(staged.javaScript).toString('base64'));
  assert.equal(executable.answer, 42n);
  const inputs = { sourceKind: 'lean', sources: ['actual source is in the native fixture; this graph uses synthetic audit metadata'],
    admissions: '{"admissions":[],"format":"proofscript-checked-admissions","version":2}',
    directJavaScript: staged.javaScript, irStages: staged,
    compilerBytes: Buffer.from('actual stage/output bytes with synthetic admission and implementation provenance'),
    compilerKind: 'fixture', provider: { profile: 'fixture' }, providerSecurity: { profile: 'fixture' },
    kernelContract: { id: 'fixture' }, hostSources: [], runtime: { implementation: 'fixture' } };
  const built = createCheckedBuildGraph(inputs);
  const definitions = built.graph.entries.filter(entry => entry.identity.contract === 'psc-pass-definition/1').map(entry => entry.canonicalValue);
  assert.deepEqual(definitions.map(item => item.passId), ['psc-prepare-and-check/1', 'psc-erase-checked-core/1',
    'psc-validate-runtime-ir/1', 'psc-project-runtime-interface/1', 'psc-pass-specialize/1', 'psc-specialized-ir-to-javascript/1']);
  for (const snapshot of Object.values(snapshots)) assert.deepEqual(built.artifacts.get(artifactKey(snapshot.identity)), snapshot.bytes);
  const archive = packObservedBuildArchive(built);
  const replay = await verifyObservedBuildArchive(archive.bytes, { expectedGraphId: built.identity,
    allowedAssumptions: [...new Set(definitions.flatMap(item => item.assumptionIds))] });
  assert.equal(replay.kind, 'accepted', replay.reason);
  assert.equal(replay.preservationVerified, false);
  assert.equal(replay.semanticClaimsVerified, false);
  assert.equal(replay.specializationCorrespondences.length, 1);
  assert.equal(replay.specializationCorrespondences[0].correspondenceChecked, true);
  const specializationPass = definitions.find(item => item.passId === 'psc-pass-specialize/1');
  assert.equal(specializationPass.validatorId, 'psc-specialization-correspondence/1');
  assert.throws(() => createCheckedBuildGraph({ ...inputs, irStages: { runtimeIr: staged.runtimeIr, verifiedIr: staged.verifiedIr } }),
    /JS_STAGES_REQUIRED/);
  assert.throws(() => createCheckedBuildGraph({ ...inputs, typeScript: 'competing backend' }), /MIXED_BACKEND_PATHS/);
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
