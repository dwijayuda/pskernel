import assert from 'node:assert/strict';
import { test } from 'node:test';
import path from 'node:path';
import { captureProjectUnits, validateProjectExports, validateLibraryEmission, libraryArtifacts } from './checked-project.mjs';

const root = path.resolve('project');
const units = [
  { sourceId: 'src/Quantity.ps', source: 'type source', exports: ['Quantity', 'makeQuantity'] },
  { sourceId: 'src/Private.ps', source: 'private source', exports: [] },
  { sourceId: 'src/Main.ps', source: 'main source', exports: ['readQuantity'] },
];
const value = () => ({ profile: 'psc-ts-library/1', bundle: 'checked bundle',
  modules: [
    { sourceId: 'src/Quantity.ps', exports: [
      { name: 'Quantity', kind: 'type', binding: '__ps$type' },
      { name: 'makeQuantity', kind: 'value', binding: '__ps$make' },
    ] },
    { sourceId: 'src/Main.ps', exports: [
      { name: 'readQuantity', kind: 'value', binding: '__ps$read' },
    ] },
  ] });

test('explicit export selections capture all source units without exposing unselected modules', () => {
  const exports = { 'src/Quantity.ps': ['Quantity', 'makeQuantity'], 'src/Main.ps': ['readQuantity'] };
  const snapshot = { kind: 'ps', ordered: units.map(unit => ({
    path: path.join(root, unit.sourceId), source: unit.source,
  })) };
  const captured = captureProjectUnits(snapshot, root, exports);
  exports['src/Main.ps'][0] = 'changed';
  assert.deepEqual(captured, units);
  assert(Object.isFrozen(captured[0].exports));
  assert.throws(() => captureProjectUnits(snapshot, root, { 'src/Missing.ps': ['missing'] }), /outside the entry closure/);
});

test('project selections reject traversal, aliases, duplicate names and nonidentifiers', () => {
  for (const exports of [
    {}, { '../Main.ps': ['x'] }, { '/Main.ps': ['x'] }, { 'src/../Main.ps': ['x'] },
    { 'src/Main.ps': [] }, { 'src/Main.ps': ['x', 'x'] }, { 'src/Main.ps': ['x;evil'] },
    { 'src/Main.ps': ['x'], 'src/main.ps': ['y'] }, { 'src/Main.lean': ['x'] },
  ]) assert.throws(() => validateProjectExports(exports), /PSC0_LIBRARY_INTERFACE/);
});

test('project descriptors bind exact selected source and public name coverage', () => {
  const encoded = JSON.stringify(value());
  const accepted = validateLibraryEmission(encoded, units);
  assert.equal(accepted.typeScript, 'checked bundle');
  assert.match(accepted.publicInterfaceSha256, /^[0-9a-f]{64}$/u);
  assert(Object.isFrozen(accepted.modules[0].exports[0]));
  const malformed = [
    item => { item.modules.pop(); },
    item => { item.modules[0].sourceId = 'src/Private.ps'; },
    item => { item.modules[1].sourceId = item.modules[0].sourceId; },
    item => { item.modules[0].exports[0].name = 'unselected'; },
    item => { item.modules[0].exports[0].binding = 'x; process.exit()'; },
    item => { item.modules[0].exports[0].kind = 'proof'; },
    item => { item.extra = true; },
  ];
  for (const change of malformed) {
    const item = value(); change(item);
    assert.throws(() => validateLibraryEmission(JSON.stringify(item), units), /PSC0_LIBRARY_INTERFACE/);
  }
});

test('facades re-export checked bindings from one bundle with no copied runtime', () => {
  const emission = validateLibraryEmission(JSON.stringify(value()), units);
  const outputPath = path.join(root, 'src/generated/library.ts');
  const layout = libraryArtifacts({ projectRoot: root, outputPath, emission });
  assert.deepEqual([...layout.artifacts.keys()],
    ['src/generated/library.ts', 'src/Quantity.ts', 'src/Main.ts']);
  assert.equal(layout.artifacts.get('src/generated/library.ts'), 'checked bundle');
  assert.match(layout.artifacts.get('src/Quantity.ts'), /export type \{ __ps\$type as Quantity \} from "\.\/generated\/library\.js";/u);
  assert.match(layout.artifacts.get('src/Main.ts'), /export \{ __ps\$read as readQuantity \} from "\.\/generated\/library\.js";/u);
  assert.throws(() => libraryArtifacts({ projectRoot: root, outputPath: path.join(root, 'src/Main.ts'), emission }), /collision/);
});
