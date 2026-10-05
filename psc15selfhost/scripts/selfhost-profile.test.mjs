import assert from 'node:assert/strict';
import { test } from 'node:test';
import {
  assertLegacyRepairGuards,
  findForbiddenForms,
  maskLeanNonCode,
  readSelfhostProfile,
} from './selfhost-profile.mjs';

const profile = await readSelfhostProfile();

test('comments and strings cannot create false profile violations', () => {
  const source = [
    '-- unsafe def fake : Nat := 0',
    '/- mutual',
    '   termination_by x',
    '-/',
    'def text : String := "opaque abbrev deriving by for while";',
    'def safe : Nat := 1',
  ].join('\n');
  assert.deepEqual(findForbiddenForms(source, profile), []);
  const masked = maskLeanNonCode(source);
  assert(masked.includes('def safe : Nat := 1'));
  assert(!masked.includes('unsafe def fake'));
});

test('unsupported Lean convenience forms are rejected generically', () => {
  const cases = [
    ['unsafe def bad : Nat := 0', 'unsafe-definition'],
    ['noncomputable def bad : Nat := 0', 'noncomputable'],
    ['mutual\n  def a : Nat := 0\nend', 'mutual'],
    ['termination_by n', 'termination-by'],
    ['opaque hidden : Nat', 'opaque'],
    ['abbrev Alias := Nat', 'abbrev'],
    ['syntax "x" : term', 'syntax-extension'],
    ['macro "x" : term => `(0)', 'macro'],
    ['theorem t : True := by trivial', 'tactic-proof'],
    ['def f := let mut x := 0; x', 'mutable-local'],
    ['def f := for x in xs do x', 'for-loop'],
    ['def f := while c do b', 'while-loop'],
  ];
  for (const [source, id] of cases) {
    const hits = findForbiddenForms(source, profile);
    assert(hits.some(hit => hit.id === id), `missing generic rejection for ${id}`);
  }
});

test('new one-off repair guards are rejected even if the count does not grow', () => {
  const current = profile.legacyRepairGuards.slice(1);
  current.push('check-new-feature-selfhost-source-syntax.mjs');
  current.sort();
  assert.throws(
    () => assertLegacyRepairGuards(current, profile),
    /ADHOC_GUARD_FORBIDDEN/u,
  );
  assert.doesNotThrow(() =>
    assertLegacyRepairGuards(profile.legacyRepairGuards.slice(1), profile));
});

test('stable explicit-recursion pattern remains allowed', () => {
  const source = `
def lengthWithFuel (fuel : Nat) : List Nat -> Nat :=
  match fuel with
  | 0 => fun (_values : List Nat) => 0
  | remaining + 1 =>
      let smaller : List Nat -> Nat := lengthWithFuel remaining;
      fun (values : List Nat) =>
        match values with
        | [] => 0
        | _ :: rest => Nat.succ (smaller rest)
`;
  assert.deepEqual(findForbiddenForms(source, profile), []);
});
