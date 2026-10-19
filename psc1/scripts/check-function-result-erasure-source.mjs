import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
const source = await readFile(new URL('../packages/erasure/src/Ps/Erasure/Expr.lean', import.meta.url), 'utf8');
function validate(text) {
  for (const marker of [
    'psErasureIrUsesNameWithFuel',
    'if psListAny sameName used then smaller (Nat.succ index)',
    'psErasureIrUsesNameWithFuel 4096 body candidate',
    'smaller (List.cons parameter used) (Nat.succ index)',
    'if psListIsEmpty parameters then Except.ok (PsVerifiedIrExpr.lambda parameters resultType body)',
    'psListAppend parameters extraParameters',
    'PsVerifiedIrExpr.call body List.nil (psListMap asVariable extraParameters)',
    'psEraseFinishApplication environment baseScope',
    'psErasureRecursiveCallArguments current.runtimeParameters parameterIndex binding.name',
    'if psStringEq text "Prod.fst" then productProjection 0',
    'else if psStringEq text "Prod.snd" then productProjection 1',
    'match erase (PsExpr.proj psProdName index value) with',
  ]) assert(text.includes(marker), `missing function-result / projection guard: ${marker}`);
  const projection = text.slice(text.indexOf('let productProjection'), text.indexOf('if psStringEq text "Prod.fst"'));
  assert(projection.includes('Nat.beq (psListLength view.args) 3'), 'pair projection requires exactly two types and a value');
  assert(projection.includes('Except.error error => Except.error error'), 'projection must preserve erasure failure');
}
validate(source);
for (const marker of [
  'if psListAny sameName used then smaller (Nat.succ index)',
  'psErasureIrUsesNameWithFuel 4096 body candidate',
  'psEraseFinishApplication environment baseScope',
  'Nat.beq (psListLength view.args) 3',
]) assert.throws(() => validate(source.replaceAll(marker, 'removed')));
console.log('PSC2_FUNCTION_RESULT_ERASURE_SOURCE: PASS (flat call arity, recursive partial calls, fresh names, value bindings and exact pair projection arity)');
