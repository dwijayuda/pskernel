import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

export function assertErasureBasicSource(source) {
  for (const marker of [
    'recursive : Bool\n',
    'runtimeExpressions : List (Nat × PsVerifiedIrExpr)\n',
    'currentDefinition : Option PsErasureCurrentDefinition\n',
    'match entry with\n        | Prod.mk key value =>',
    'if Nat.beq key target then Option.some value',
    'if psNameEq key target then Option.some value',
    'if Nat.beq value target then true else smaller target',
    'if psLevelNormalizesToZero left then psLevelNormalizesToZero right else false',
    'String.Internal.append "_" base',
    'List.cons (Prod.mk pushed.id runtimeName) scope.runtimeLocals',
  ]) assert.ok(source.replace(/\s+/g, ' ').includes(marker.replace(/\s+/g, ' ')), `ERASURE_BASIC_MISSING: ${marker}`);
  assert.ok(!/^  (?:recursive|runtimeStructures|runtimeStructureConstructors|runtimeExpressions|currentDefinition) :.*:=/m.test(source), 'ERASURE_BASIC_FORBIDDEN: structure defaults');
  assert.ok(/let nextScope : PsErasureScope := \{[^}]*runtimeExpressions := \[\]\s*currentDefinition := Option.none/.test(source), 'ERASURE_BASIC_MISSING: original runtime-type scope defaults');
  assert.ok(!/==|&&|\|\||entry\.[12]\b/.test(source), 'ERASURE_BASIC_FORBIDDEN: operators or numeric projections');
  const lookups = source.slice(source.indexOf('def psErasureLookupRuntimeExpression'), source.indexOf('def psErasureNatInList'));
  assert.equal((lookups.match(/\| Prod\.mk key value =>/g) ?? []).length, 2, 'ERASURE_BASIC_MISSING: local first-match lookups');
  for (const marker of [
    'psErasureIndexFind String entries.byCore name',
    'psErasureIndexFind PsRuntimeStructureInfo entries name',
    'psErasureIndexFind PsRuntimeConstructorInfo entries name',
    'psErasureIndexFind PsRuntimeInductiveInfo entries name',
    'psErasureIndexInsert Value (smaller tail) name value',
    'psErasureIndexFind Bool scope.declarationNames.byOutput (PsName.str PsName.anonymous candidate)',
    'psErasureIndexInsert Bool tail.byOutput (PsName.str PsName.anonymous value) true',
    '(Nat.succ tail.count)',
  ]) assert.ok(source.includes(marker), `ERASURE_BASIC_MISSING: indexed lookup ${marker}`);
  assert.ok(!source.includes('psListAny declarationUses scope.declarationNames'), 'ERASURE_BASIC_FORBIDDEN: repeated full declaration-name scans');
}

const source = await readFile(new URL('../packages/erasure/src/Ps/Erasure/Basic.lean', import.meta.url), 'utf8');
assertErasureBasicSource(source);
for (const [from, to] of [
  ['recursive : Bool\n', 'recursive : Bool := false\n'],
  ['currentDefinition : Option PsErasureCurrentDefinition\n', 'currentDefinition : Option PsErasureCurrentDefinition := none\n'],
  ['Nat.beq key target', 'key == target'],
  ['psNameEq key target', 'psNameEq entry.1 target'],
  ['if Nat.beq value target then true else smaller target', 'Nat.beq value target || smaller target'],
  ['runtimeExpressions := []\n                  currentDefinition := Option.none', 'runtimeExpressions := scope.runtimeExpressions\n                  currentDefinition := scope.currentDefinition'],
  ['psErasureIndexInsert Value (smaller tail) name value', 'smaller (psErasureIndexInsert Value tail name value)'],
  ['psErasureIndexFind Bool scope.declarationNames.byOutput', 'psErasureIndexFind Bool scope.declarationNames.byCore'],
]) {
  assert.ok(source.includes(from));
  assert.throws(() => assertErasureBasicSource(source.replace(from, to)), /ERASURE_BASIC/);
}
console.log('PSC2_ERASURE_BASIC_SOURCE_SYNTAX: PASS (explicit defaults, product matches, primitive equality and preserved first-match lookups)');
