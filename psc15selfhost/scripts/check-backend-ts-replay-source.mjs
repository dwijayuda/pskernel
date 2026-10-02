import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

const files = Object.fromEntries(await Promise.all(['Type', 'Expr', 'Module'].map(async name =>
  [name, await readFile(new URL(`../packages/backend-ts/src/Ps/BackendTs/${name}.lean`, import.meta.url), 'utf8')])));
const required = {
  Type: ['psTsIndexTypesWorker rest;', 'psTsEmitTypeWithFuel remaining;',
    'psListMapExcept smaller parameters', 'psListMapExcept smaller arguments', 'Int.repr value'],
  Expr: ['psTsExprUsesNameWithFuel remaining;', 'psTsFreshMatchTempWorker expr remaining;',
    'psTsEmitExprWithFuel brands tags remaining;', 'match operation with',
    'Prod.mk fieldName fieldValue =>', 'Prod.mk constructorName detail =>', 'Prod.mk bindings body =>'],
  Module: ['psTsFreshInternalWorker used namePrefix remaining;',
    'psTsBuildSymbolMap namePrefix rest;', 'psTsNameSequence namePrefix remaining;',
    'psListMap formatParameter (psListZip parameterNames fieldTypes)',
    'psListMap formatField (psListZip constructorInfo.fields parameterNames)',
    'psListMap psTsEmitImport module.imports'],
};
export function assertBackendReplay(name, source) {
  const flat = source.replace(/\s+/g, ' ');
  for (const marker of required[name]) assert.ok(flat.includes(marker), `BACKEND_REPLAY_MISSING: ${name}: ${marker}`);
  const code = source.replace(/"(?:\\.|[^"\\])*"/g, '""');
  assert.ok(!/\+\+|&&|\|\||==|\|>|\.\d\b|\.(?:mapM?|any|contains|reverse|isEmpty|length|zip)\b|\btoString\b/.test(code),
    `BACKEND_REPLAY_FORBIDDEN: ${name}: unsupported syntax or library method`);
}
for (const [name, source] of Object.entries(files)) {
  assertBackendReplay(name, source);
  const flat = source.replace(/\s+/g, ' ');
  for (const marker of required[name])
    assert.throws(() => assertBackendReplay(name, flat.replaceAll(marker, 'missing')), /BACKEND_REPLAY_MISSING/);
  assert.throws(() => assertBackendReplay(name, `${source}\ndef bad := value.1`), /BACKEND_REPLAY_FORBIDDEN/);
}
const model = await readFile(new URL('../packages/compiler-ir/src/Ps/CompilerIr/Model.lean', import.meta.url), 'utf8');
const intrinsicModel = model.slice(model.indexOf('inductive PsVerifiedIrIntrinsic'), model.indexOf('structure PsVerifiedIrParameter'));
const cases = [...intrinsicModel.matchAll(/^  \| (\w+)/gm)].map(m => m[1]);
const dispatch = files.Expr.slice(files.Expr.indexOf('def psTsEmitIntrinsicFromPrinted'), files.Expr.indexOf('def psTsEmitExprWithFuel'));
assert.deepEqual([...dispatch.matchAll(/^  \| \.(\w+)/gm)].map(m => m[1]).sort(), cases.sort(), 'BACKEND_REPLAY: exactly one dispatch branch per intrinsic');
for (const arity of [1, 2, 3, 5]) {
  const helper = files.Expr.slice(files.Expr.indexOf(`def psTsPrinted${arity} `)).split('\n\ndef ')[0];
  assert.equal((helper.match(/List\.nil => Except\.error PsTsEmitError\.intrinsicArity/g) ?? []).length, arity);
  assert.ok(helper.includes(`match rest${arity - 1} with`));
  assert.ok(helper.includes('| List.cons _ _ => Except.error PsTsEmitError.intrinsicArity'));
}
const api = await readFile(new URL('../packages/compiler/src/Ps/Compiler/Api.lean', import.meta.url), 'utf8');
assert.ok(api.includes('let translated : Except PsTranslationError String :='));
assert.ok(api.includes('String.Internal.append canonicalAdmissions "\\n"'));
const erasure = await readFile(new URL('../packages/erasure/src/Ps/Erasure/Expr.lean', import.meta.url), 'utf8');
assert.match(erasure, /psStringEq text "Int\.repr" then\s*if Nat\.beq \(psListLength view\.args\) 1 then\s*match psEraseMappedIntrinsic erase PsVerifiedIrIntrinsic\.intRepr view\.args with/);
console.log('PSC2_BACKEND_TS_REPLAY_SOURCE: PASS (three modules; explicit recursion, products, intrinsic coverage and exact arity rejection)');
