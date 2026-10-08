import assert from 'node:assert/strict';
import { test } from 'node:test';
import path from 'node:path';
import { mkdtemp, writeFile, rm, rmdir } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import {
  findSelfhostStructuralViolations,
  portableSelfhostStructuralRuleIds,
} from './selfhost-source-rules.mjs';

import {
  collectPortableSelfhostEntryRoots,
  collectImportClosure,
  collectPortableSelfhostPackages,
  readPortableSelfhostProfile,
} from './portable-selfhost-profile.mjs';

function ids(source) {
  return findSelfhostStructuralViolations(
    source,
    portableSelfhostStructuralRuleIds,
  ).map(hit => hit.id);
}

test('portable import closure resolves theory packages and rejects unknown or missing imports', async () => {
  const directory = await mkdtemp(path.join(tmpdir(), 'psc-import-closure-'));
  const file = path.join(directory, 'Root.lean');
  try {
    await writeFile(file, 'import Ps.TheoryBridge.Model\n');
    const closure = await collectImportClosure([file], true);
    assert([...closure.keys()].some(name => name.endsWith(path.join('TheoryBridge', 'Model.lean'))));
    for (const name of ['Ps.Unknown.Module', 'Ps.TheoryBridge.Missing']) {
      await writeFile(file, 'import ' + name + '\n');
      await assert.rejects(collectImportClosure([file], true), /IMPORT_UNRESOLVED/);
    }
  } finally { await rm(file, { force: true }); await rmdir(directory); }
});

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
    ids('def code := char.toNat').includes('value-conversion-dot-notation'),
  );
  assert(
    ids('def chars := text.toList').includes('value-conversion-dot-notation'),
  );
  assert(
    !ids('def code := Char.toNat char').includes('value-conversion-dot-notation'),
  );
  assert(
    ids('def value := .some x').includes('leading-dot-term-constructor'),
  );
  assert(ids('def mapper := fun x => x').includes('untyped-lambda-binder'));
  const untypedLambdaLet = [
    'def f : Nat -> Nat :=',
    '  let mapper :=',
    '    fun (x : Nat) => x;',
    '  mapper',
  ].join('\n');
  assert(ids(untypedLambdaLet).includes('untyped-lambda-let'));

  const typedLambdaLet = [
    'def f : Nat -> Nat :=',
    '  let mapper : Nat -> Nat :=',
    '    fun (x : Nat) => x;',
    '  mapper',
  ].join('\n');
  assert(!ids(typedLambdaLet).includes('untyped-lambda-let'));

  const untypedNumericChoice = [
    'def f (flag : Bool) : Int :=',
    '  let encoded :=',
    '    if flag then 1 else 0;',
    '  encoded',
  ].join('\n');
  assert(ids(untypedNumericChoice).includes('untyped-numeric-choice-let'));

  const typedNumericChoice = [
    'def f (flag : Bool) : Int :=',
    '  let encoded : Int :=',
    '    if flag then 1 else 0;',
    '  encoded',
  ].join('\n');
  assert(!ids(typedNumericChoice).includes('untyped-numeric-choice-let'));

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

test('general infix arithmetic is rejected but structural successor patterns remain allowed', () => {
  for (const source of [
    'def a (x : Nat) := x % 128',
    'def a (x : Nat) := x / 128',
    'def a (x : Nat) := x + 1',
    'def a (x : Nat) := x - 1',
    'def a (x : Nat) := x * 2',
    'def a (x : Nat) := x <= 2',
    'def a (x : Nat) := x >= 2',
    'def a (x : Nat) := x < 2',
    'def a (x : Nat) := x > 2',
  ]) {
    assert(ids(source).includes('term-arithmetic-operator'), source);
  }

  const structuralPattern = [
    'def f (fuel : Nat) : Nat :=',
    '  match fuel with',
    '  | 0 => 0',
    '  | remaining + 1 => Nat.succ remaining',
  ].join('\n');
  assert(!ids(structuralPattern).includes('term-arithmetic-operator'));

  const explicit = [
    'def f (x y : Nat) : Nat :=',
    '  Nat.add (Nat.mod x 128) (Nat.div y 64)',
  ].join('\n');
  assert(!ids(explicit).includes('term-arithmetic-operator'));

  const characterOperators = [
    "def slash (c : Char) : Bool := psLexCharEq c '/'",
    "def star (c : Char) : Bool := psLexCharEq c '*'",
    "def pair (a b : Char) : Bool := psLexPairEq a b '=' '>'",
    "def escaped : Char := '\\\\'",
  ].join('\n');
  assert(
    !ids(characterOperators).includes('term-arithmetic-operator'),
    characterOperators,
  );
});

test('portable scalar member capabilities are allowlisted explicitly', () => {
  for (const source of [
    'def a (x : Nat) := Nat.add x 1',
    'def a (x : Nat) := Int.ofNat x',
    'def a (c : Char) := Char.toNat c',
    'def a (x : Nat) : UInt8 := UInt8.ofNat x',
  ]) {
    assert(!ids(source).includes('scalar-member-capability'), source);
  }

  for (const source of [
    'def a (x : Nat) : UInt16 := UInt16.ofNat x',
    'def a (x : UInt8) := UInt8.toNat x',
    'def a (x : Nat) := Nat.toUInt8 x',
  ]) {
    assert(ids(source).includes('scalar-member-capability'), source);
  }
});

test('opaque primitive scalars cannot be pattern matched', () => {
  const bad = [
    'def f (value : Int) : Bool :=',
    '  match value with',
    '  | Int.ofNat _ => true',
    '  | Int.negSucc _ => false',
  ].join('\n');
  assert(ids(bad).includes('opaque-primitive-match'));

  const good = [
    'def f (value : Nat) : Bool :=',
    '  match value with',
    '  | Nat.zero => true',
    '  | Nat.succ _ => false',
  ].join('\n');
  assert(!ids(good).includes('opaque-primitive-match'));
});

test('portable source uses explicit Option constructors', () => {
  const bad = [
    'def f (value : Option Nat) : Option Nat :=',
    '  match value with',
    '  | none => some 0',
    '  | some current => some current',
  ].join('\n');
  assert(ids(bad).includes('explicit-option-constructors'));

  const good = [
    'def f (value : Option Nat) : Option Nat :=',
    '  match value with',
    '  | Option.none => Option.some 0',
    '  | Option.some current => Option.some current',
  ].join('\n');
  assert(!ids(good).includes('explicit-option-constructors'));
});

test('local match bindings require explicit result types', () => {
  const bad = [
    'def f (value : Option Nat) : Nat :=',
    '  let selected :=',
    '    match value with',
    '    | Option.none => 0',
    '    | Option.some current => current;',
    '  selected',
  ].join('\n');
  assert(ids(bad).includes('untyped-match-let'));

  const good = [
    'def f (value : Option Nat) : Nat :=',
    '  let selected : Nat :=',
    '    match value with',
    '    | Option.none => 0',
    '    | Option.some current => current;',
    '  selected',
  ].join('\n');
  assert(!ids(good).includes('untyped-match-let'));
});

test('portable entry roots minimally cover the backend-wasm package graph', async () => {
  const profile = await readPortableSelfhostProfile();
  const packages = await collectPortableSelfhostPackages(profile, 'backend-wasm');
  assert.equal(packages.length, 1);
  const entries = await collectPortableSelfhostEntryRoots(
    packages[0],
    profile.includeImportClosure === true,
  );
  assert.deepEqual(
    entries.map(sourcePath => path.basename(sourcePath)).sort(),
    ['CanonicalRequest.lean', 'Encode.lean', 'LiteralEvidence.lean', 'SelfHostAbi.lean'],
  );
  const closure = await collectImportClosure(entries, true);
  for (const sourcePath of packages[0].roots) {
    assert(closure.has(path.resolve(sourcePath)), 'uncovered backend source: ' + sourcePath);
  }
});

test('portable entry roots minimally cover the backend-js package graph', async () => {
  const profile = await readPortableSelfhostProfile();
  const packages = await collectPortableSelfhostPackages(profile, 'backend-js');
  assert.equal(packages.length, 1);
  const entries = await collectPortableSelfhostEntryRoots(
    packages[0],
    profile.includeImportClosure === true,
  );
  assert.deepEqual(
    entries.map(sourcePath => path.basename(sourcePath)).sort(),
    ['Encode.lean', 'Print.lean'],
  );
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

test('record updates require explicit portable constructors without rejecting record literals', () => {
  for (const source of [
    'def f := { state with operands := rest }',
    'def f := { (choose state) with value := next }',
    'def f := { state\n  with value := next }',
    'def f := { outer := { inner with value := next } }',
  ]) assert(ids(source).includes('record-update'), source);
  for (const source of [
    'def f := State.mk rest state.flag',
    'def f := { value := next, flag := false }',
    'def f := { value := match state with | Option.none => 0 | Option.some value => value }',
    'def f := { value := { inner := next } }',
    'def f := "{ state with value := next }"',
    '-- { state with value := next }\ndef f := 0',
    "/- { state with value := next } -/\ndef f := 0",
    "def brace : Char := '{'\ndef f := match x with | _ => 0",
  ]) assert(!ids(source).includes('record-update'), source);
  assert.equal(findSelfhostStructuralViolations('def f := { state with x := next }', []).length, 0);
});
