import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

const required = {
  Basic: ['psEraseRuntimeTypeWithFuelWorker environment remaining;',
    'psEraseRuntimeTypeWithFuelWorker environment fuel scope type',
    'String.Internal.next raw (String.Pos.Raw.mk position)',
    'String.push mapped (psErasureSafeChar char)'],
  Expr: ['psEraseApplicationArgumentsWorker erase environment scope rest;',
    'psEraseFinishApplicationWithFuelWorker environment fn typeArguments remaining;',
    'psSubstituteVerifiedTypeWithFuel substitutions remaining;',
    'psOpenMatchMinorFields environment substitutions rest;',
    'psOpenMatchMinorHypotheses environment recursiveParameterIndex bindings rest;',
    'psEraseMatchAlternativesWorker environment eraseAt scope substitutions recursiveParameterIndex arguments minorStart rest;',
    'psEraseRuntimeExprWithFuelWorker environment remaining;',
    'psEraseRuntimeExprWithFuelWorker environment fuel scope expr'],
  Inductive: ['psPrepareInductiveParametersWithFuel environment remainingFuel;',
    'psPrepareConstructorFieldsWithFuel environment remainingFuel;',
    'psApplyConstructorParameters environment scope rest;',
    'psPrepareRuntimeConstructors environment declarations parameterScope parameterValues inductiveName rest;',
    'psPrepareRuntimeInductives environment declarations rest;',
    'PsRuntimeConstructorField.mk index fieldName fieldType false',
    'psErasureNatInList ctorInfo.recursiveFields field.sourceIndex'],
  Structure: ['psPrepareRuntimeStructures environment declarations rest;',
    'PsPreparedStructureResult.mk nextScope',
    'PsVerifiedIrStructure.mk outputName parameters.typeParameters (psListMap makeIrField fields)',
    'List.cons _ _ => Except.error PsErasureError.unsupportedRuntimeTerm'],
  StructureRecursor: ['psErasureApplyStructureMinorFields structureName major remaining;',
    'psLowerStructureRecursorsWithFuel environment remaining;',
    'psErasureNatNotEqual (psListLength view.args) expectedArity', 'psExprLiftBVars 1 0 minor'],
};

export function assertErasureReplayWorker(name, source) {
  const normalized = source.replace(/\s+/g, ' ');
  for (const marker of required[name])
    assert.ok(normalized.includes(marker), `ERASURE_REPLAY_WORKER_MISSING: ${name}: ${marker}`);
  const code = source.replace(/"(?:\\.|[^"\\])*"/g, '""').replaceAll('String.Internal.length', 'stringLengthPrimitive');
  assert.ok(!/\.(?:mapM|map|reverse|length|isEmpty)\b|\btoString\b|(?<![\w.])(?:some|none)\b/.test(code),
    `ERASURE_REPLAY_WORKER_FORBIDDEN: ${name}: unsupported convenience`);
  assert.ok(!/^\s*\|[^\n]*,.*=>/m.test(code),
    `ERASURE_REPLAY_WORKER_FORBIDDEN: ${name}: combined argument patterns`);
}
for (const [name, markers] of Object.entries(required)) {
  const source = await readFile(new URL(`../packages/erasure/src/Ps/Erasure/${name}.lean`, import.meta.url), 'utf8');
  assertErasureReplayWorker(name, source);
  const normalized = source.replace(/\s+/g, ' ');
  for (const marker of markers)
    assert.throws(() => assertErasureReplayWorker(name, normalized.replace(marker, 'missing')), /ERASURE_REPLAY_WORKER_MISSING/);
  assert.throws(() => assertErasureReplayWorker(name, `${source}\ndef bad := values.reverse`), /ERASURE_REPLAY_WORKER_FORBIDDEN/);
}
const list = await readFile(new URL('../packages/foundation/src/Ps/Foundation/List.lean', import.meta.url), 'utf8');
const mapExcept = list.slice(list.indexOf('def psListMapExcept'), list.indexOf('def psListTake'));
assert.match(mapExcept, /match convert value with[\s\S]*?Except\.error failure => Except\.error failure[\s\S]*?Except\.ok result =>\s*match psListMapExcept convert rest with/);
assert.doesNotMatch(mapExcept, /let smaller/, 'List erasure must propagate the first failure before visiting the tail');
console.log('PSC2_ERASURE_REPLAY_WORKERS: PASS (five modules; decreasing workers, explicit wrappers, first-error order and rejection mutations)');
