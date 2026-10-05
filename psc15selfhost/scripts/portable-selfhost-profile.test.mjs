import assert from 'node:assert/strict';
import { test } from 'node:test';
import {
  findSelfhostStructuralViolations,
  portableSelfhostStructuralRuleIds,
} from './selfhost-source-rules.mjs';

function ids(source) {
  return findSelfhostStructuralViolations(
    source,
    portableSelfhostStructuralRuleIds,
  ).map(hit => hit.id);
}

test('recursive equation definitions are rejected but explicit structural recursion is accepted', () => {
  const bad = [
    'def length : List Nat -> Nat',
    '  | [] => 0',
    '  | _ :: rest => Nat.succ (length rest)',
  ].join('\n');
  assert(ids(bad).includes('recursive-equation-definition'));

  const good = [
    'def length (values : List Nat) : Nat :=',
    '  match values with',
    '  | List.nil => 0',
    '  | List.cons _ rest => Nat.succ (length rest)',
  ].join('\n');
  assert(!ids(good).includes('recursive-equation-definition'));
});

test('term list conveniences are rejected without rejecting supported list patterns', () => {
  assert(ids('def append := xs ++ ys').includes('term-list-append'));
  assert(ids('def prepend := x :: xs').includes('term-list-cons'));

  const pattern = [
    'def tail (xs : List Nat) :=',
    '  match xs with',
    '  | _ :: rest => rest',
    '  | [] => []',
  ].join('\n');
  assert(!ids(pattern).includes('term-list-cons'));
});

test('tuple, projection, grouped-dot and string-pattern hazards are rejected generically', () => {
  assert(ids('def pair := (left, right)').includes('tuple-construction'));
  assert(ids('def first := pair.1').includes('numeric-tuple-projection'));
  assert(
    ids('def zipped := (makeValues input).zip rest')
      .includes('grouped-dot-application'),
  );

  const literalPattern = [
    'def f (value : Option String) :=',
    '  match value with',
    '  | some "" => true',
    '  | _ => false',
  ].join('\n');
  assert(ids(literalPattern).includes('string-literal-pattern'));
});

test('known fragile term shorthand is rejected structurally', () => {
  assert(ids('def both := left && right').includes('boolean-convenience'));
  assert(
    ids('def value := .some x').includes('leading-dot-term-constructor'),
  );
  assert(ids('def mapper := fun x => x').includes('untyped-lambda-binder'));
});

test('layout-only lets are rejected while explicit sequencing remains valid', () => {
  const bad = [
    'def f : Nat :=',
    '  let value := 1',
    '  value',
  ].join('\n');
  assert(ids(bad).includes('layout-let-sequencing'));

  const good = [
    'def f : Nat :=',
    '  let value :=',
    '    Nat.add 0 1;',
    '  value',
  ].join('\n');
  assert(!ids(good).includes('layout-let-sequencing'));
});
