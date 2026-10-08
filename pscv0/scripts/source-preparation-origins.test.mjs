import assert from 'node:assert/strict';
import { test } from 'node:test';
import { artifactKey, canonicalArtifact } from './artifact-evidence.mjs';
import { prepareSourceWithOrigins, sourcePreparationRecord, createSourcePreparationArtifacts,
  mapPreparedRange, mapPreparedOffset, verifySourcePreparationOrigins } from './source-preparation-origins.mjs';

test('preparation records exact copied bytes across CRLF, imports, Unicode and trimming', () => {
  const source = '\ufeff  \r\nimport Lib\r\ndef λ : String := "😀"\r\nimport More;\r\ndef b : Nat := 2  \r\n';
  const result = prepareSourceWithOrigins(source);
  assert.equal(result.prepared, 'def λ : String := "😀"\ndef b : Nat := 2');
  const original = Buffer.from(source), prepared = Buffer.from(result.prepared);
  let end = 0;
  for (const [from, to, originalFrom, originalTo] of result.segments) {
    assert.equal(from, end); end = to;
    assert.deepEqual(prepared.subarray(from, to), original.subarray(originalFrom, originalTo));
    assert.equal(mapPreparedOffset(result.segments, from), originalFrom);
    assert.equal(mapPreparedOffset(result.segments, to - 1), originalTo - 1);
  }
  assert.equal(end, prepared.length);
  assert.throws(() => mapPreparedOffset(result.segments, prepared.length), /RANGE/);
  const fragments = mapPreparedRange(result.segments, 0, prepared.length);
  assert.ok(fragments.length > 1, 'removed imports must remain a source gap');
  assert.deepEqual(Buffer.concat(fragments.map(([from, to]) => original.subarray(from, to))), prepared);
  assert.deepEqual(mapPreparedRange(result.segments, prepared.length, prepared.length), []);
  assert.throws(() => mapPreparedRange(result.segments, 0, prepared.length + 1), /RANGE/);
});

test('empty/import-only files and a literal final carriage return preserve current preparation semantics', () => {
  for (const source of ['', '  \r\n', 'import Only\r\n', '  def value : Nat := 1\r', '-- 😀\n\ndef value : Nat := 1']) {
    const legacy = source.split(/\r?\n/u).filter(line => !/^\s*import\s+[A-Za-z0-9_.]+\s*;?\s*$/u.test(line)).join('\n').trim();
    const result = prepareSourceWithOrigins(source);
    assert.equal(result.prepared, legacy);
    if (!legacy) assert.deepEqual(result.segments, []);
  }
});

function fixture() {
  const records = [
    sourcePreparationRecord('Empty.lean', 'import Prelude\n', 0),
    sourcePreparationRecord('Lib.lean', '\n def lib : Nat := 1\r\n', 0),
    sourcePreparationRecord('Main.lean', 'import Lib\ndef main : Nat := lib\n', 1),
  ];
  const source = canonicalArtifact({ sourceKind: 'lean', sources: records.map(x => x.prepared).filter(Boolean) },
    'source-snapshot', 'psc-source-snapshot/1');
  const capture = createSourcePreparationArtifacts(records, source);
  const artifacts = new Map([source, ...capture.artifacts].map(item => [artifactKey(item.identity), item.bytes]));
  return { source, capture, resolveArtifact: id => artifacts.get(artifactKey(id)) };
}

test('archive projection binds complete ordered prepared inputs and rejects fresh-hash tampering', async () => {
  const { source, capture, resolveArtifact } = fixture();
  const policy = { expectedSourceId: source.identity, resolveArtifact };
  const checked = await verifySourcePreparationOrigins(capture.map, policy);
  assert.equal(checked.inputCount, 2); assert.equal(checked.fileCount, 3);
  assert.equal(checked.semanticPreservationProved, false);
  for (const change of [
    value => { value.files[1].segments[0][2]++; },
    value => { value.files[1].preparedIndex = 1; },
    value => { value.files.pop(); },
  ]) {
    const value = JSON.parse(capture.map.bytes); change(value);
    const modified = canonicalArtifact(value, 'source-origins', 'psc-source-preparation-origins/1');
    await assert.rejects(verifySourcePreparationOrigins(modified, policy), /PSC_SOURCE_ORIGIN_/);
  }
  const other = canonicalArtifact({ sourceKind: 'lean', sources: [] }, 'source-snapshot', 'psc-source-snapshot/1');
  await assert.rejects(verifySourcePreparationOrigins(capture.map, { ...policy, expectedSourceId: other.identity }), /SCHEMA/);
});
