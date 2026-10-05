import assert from 'node:assert/strict';
import { test } from 'node:test';
import { validatePreludeExtensions } from './prelude-extension-contract.mjs';

const core = [
  { name: 'A', kind: 'axiom' },
  { name: 'UInt8', kind: 'axiom' },
  { name: 'B', kind: 'axiom' },
];

const extensionDeclaration = {
  name: 'UInt8.ofNat',
  kind: 'axiom',
  type: { from: 'Nat', to: 'UInt8' },
};

const contract = {
  schemaVersion: 1,
  extensions: [
    {
      name: 'UInt8.ofNat',
      insertBefore: 'UInt8',
      declaration: extensionDeclaration,
    },
  ],
};

test('exact declared extension is removed before frozen-core parity comparison', () => {
  const actual = [core[0], extensionDeclaration, core[1], core[2]];
  assert.deepEqual(validatePreludeExtensions(actual, contract), core);
});

test('unknown extra declarations are not hidden by the extension contract', () => {
  const unknown = { name: 'UInt8.other', kind: 'axiom' };
  const actual = [unknown, core[0], extensionDeclaration, core[1], core[2]];
  const reduced = validatePreludeExtensions(actual, contract);
  assert.deepEqual(reduced, [unknown, core[0], core[1], core[2]]);
});

test('missing declared extension rejects', () => {
  assert.throws(
    () => validatePreludeExtensions(core, contract),
    /required prelude extension missing/u,
  );
});

test('extension declaration drift rejects', () => {
  const changed = {
    ...extensionDeclaration,
    type: { from: 'Nat', to: 'UInt16' },
  };
  assert.throws(
    () => validatePreludeExtensions([core[0], changed, core[1], core[2]], contract),
    /prelude extension declaration changed/u,
  );
});

test('extension insertion point drift rejects', () => {
  const moved = [core[0], core[1], extensionDeclaration, core[2]];
  assert.throws(
    () => validatePreludeExtensions(moved, contract),
    /prelude extension insertion point changed/u,
  );
});

test('duplicate declarations reject', () => {
  const duplicate = [
    core[0],
    extensionDeclaration,
    core[1],
    core[1],
    core[2],
  ];
  assert.throws(
    () => validatePreludeExtensions(duplicate, contract),
    /prelude declaration names must remain unique/u,
  );
});
