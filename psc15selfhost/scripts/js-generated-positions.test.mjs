import assert from 'node:assert/strict';
import { test } from 'node:test';
import { artifactKey, artifactId, canonicalArtifact, canonicalBytes } from './artifact-evidence.mjs';
import { createJsGeneratedPositionMap, decodeJsGeneratedPositions, verifyJsGeneratedPositionMap } from './js-generated-positions.mjs';

const javaScript = 'a😀\r\nx\u2028y\u2029z';
const ir = ['psc-js-ir-json/1', [], [['one', [], ['literal', ['unit']]], ['two', [], ['literal', ['unit']]]]];
const table = ['psc-js-generated-positions/1', 'declaration-emission-chunk', [
  ['one', [0, 0, 0], [5, 0, 3]], ['two', [7, 1, 0], [16, 3, 1]],
]];
const jsIr = { bytes: canonicalBytes(ir), identity: artifactId(canonicalBytes(ir), 'js-ir', 'psc-js-ir-json/1') };
const policy = { javaScript, jsIr: jsIr.bytes };

test('position validation distinguishes UTF-16 columns from bytes and parser scalar columns', () => {
  assert.deepEqual(decodeJsGeneratedPositions(canonicalBytes(table), policy), table);
  for (const mutate of [
    v => { v[2][0][2] = [5, 0, 2]; }, // scalar count, not UTF-16
    v => { v[2][0][2] = [3, 0, 2]; }, // middle of astral UTF-8 sequence
    v => { v[2][0][2] = [6, 1, 0]; }, // splits CRLF
    v => { v[2][1][2] = [16, 1, 7]; }, // ignores Unicode line separators
    v => { v[2][1][0] = 'wrong'; },
    v => { v[2].pop(); },
    v => { v[2][1][1] = [4, 0, 2]; }, // overlaps preceding declaration
  ]) {
    const changed = structuredClone(table); mutate(changed);
    assert.throws(() => decodeJsGeneratedPositions(canonicalBytes(changed), policy), /PSC_JS_POSITION_/);
  }
});

test('generated position maps bind exact target IR and code without assigning source or semantic authority', async () => {
  const product = createJsGeneratedPositionMap({ table: canonicalBytes(table), javaScript, jsIr });
  const records = new Map(product.artifacts.map(item => [artifactKey(item.identity), item.bytes]));
  const codeId = product.artifacts.find(item => item.identity.domain === 'javascript-output').identity;
  const pinned = { resolveArtifact: id => records.get(artifactKey(id)), expectedJsIrId: jsIr.identity, expectedJavaScriptId: codeId };
  const result = await verifyJsGeneratedPositionMap(product.map, pinned);
  assert.equal(result.generatedCoordinatesChecked, true);
  assert.equal(result.sourceAttributionChecked, false);
  await assert.rejects(verifyJsGeneratedPositionMap(product.map, { ...pinned, expectedJavaScriptId: jsIr.identity }), /SUBJECT/);
  const changed = JSON.parse(product.map.bytes); changed.sourceAttributionChecked = true;
  await assert.rejects(verifyJsGeneratedPositionMap(
    canonicalArtifact(changed, 'generated-position-map', 'psc-js-generated-position-map/1'), pinned), /BINDING/);
});
