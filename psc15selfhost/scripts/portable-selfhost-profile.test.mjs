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

test('structural recursion may change only the decreasing explicit argument', () => {
  const bad = [
    'def fold (step : Nat -> Nat -> Nat) (values : List Nat) (state : Nat) : Nat :=',
    '  match values with',
    '  | List.nil => state',
    '  | List.cons value rest =>',
    '      fold step rest (step state value)',
  ].join('\n');
  assert(ids(bad).includes('structural-recursion-call-shape'));

  const good = [
    'def foldWorker (step : Nat -> Nat -> Nat) (values : List Nat) : Nat -> Nat :=',
    '  match values with',
    '  | List.nil => fun (state : Nat) => state',
    '  | List.cons value rest =>',
    '      let smaller : Nat -> Nat := foldWorker step rest;',
    '      fun (state : Nat) => smaller (step state value)',
  ].join('\n');
  assert(!ids(good).includes('structural-recursion-call-shape'));
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
    ids('def text := toString value').includes('to-string-convenience'),
  );
  assert(
    ids('def count := values.length').includes('value-length-dot-notation'),
  );
  assert(
    !ids('def count := String.Internal.length text').includes('value-length-dot-notation'),
  );
  assert(
    ids('def value := .some x').includes('leading-dot-term-constructor'),
  );
  assert(ids('def mapper := fun x => x').includes('untyped-lambda-binder'));

  const multilinePattern = [
    'def f (value : T) :=',
    '  match value with',
    '  | .constructor',
    '      first',
    '      second => first',
    '  | _ => second',
  ].join('\n');
  assert(!ids(multilinePattern).includes('leading-dot-term-constructor'));
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
