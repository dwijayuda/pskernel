import assert from 'node:assert/strict';
import { test } from 'node:test';
import { spawnSync } from 'node:child_process';
import { canonicalBytes, artifactKey } from './artifact-evidence.mjs';
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
  assert.equal(built.graph.executions.length, 4);
  for (const artifact of Object.values(snapshots)) assert.deepEqual(built.artifacts.get(artifactKey(artifact.identity)), artifact.bytes);
  const definitions = built.graph.entries.filter(entry => entry.identity.contract === 'psc-pass-definition/1').map(entry => entry.canonicalValue);
  assert.deepEqual(definitions.map(item => item.passId), [
    'psc-prepare-and-check/1', 'psc-erase-checked-core/1', 'psc-validate-runtime-ir/1', 'psc-verified-ir-to-typescript/1',
  ]);
  const archive = packObservedBuildArchive(built);
  const replay = await verifyObservedBuildArchive(archive.bytes, { expectedGraphId: built.identity,
    allowedAssumptions: [...new Set(definitions.flatMap(item => item.assumptionIds))] });
  assert.equal(replay.kind, 'accepted', replay.reason);
  assert.equal(replay.preservationVerified, false);
  const changed = JSON.parse(staged.verifiedIr);
  changed[4][0][0] = 'renamed';
  assert.throws(() => createCheckedBuildGraph({ ...inputs, irStages: { ...staged, verifiedIr: canonicalBytes(changed).toString() } }),
    /VALIDATION_CHANGED_IR/);
});
