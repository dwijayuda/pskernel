import assert from 'node:assert/strict';
import { test } from 'node:test';
import { hasOpaqueSourceCommand } from './source-profile-opaque.mjs';

test('portable constructor names do not masquerade as opaque commands', () => {
  assert.equal(hasOpaqueSourceCommand('inductive Body where\n  | opaque\n  | transparent (n : Nat)\n'), false);
  assert.equal(hasOpaqueSourceCommand('match b with\n| Body.opaque => false\n| Body.transparent n => true\n'), false);
  for (const declaration of ['opaque hidden : Nat := 0', 'private opaque hidden : Nat := 0', '@[irreducible] opaque hidden : Nat := 0', 'private\nopaque hidden : Nat := 0']) {
    assert.equal(hasOpaqueSourceCommand(declaration), true, declaration);
    assert.equal(hasOpaqueSourceCommand('def x := Body.opaque\n'+declaration), true, declaration);
  }
});
