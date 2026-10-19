import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
const basic = await readFile(new URL('../packages/erasure/src/Ps/Erasure/Basic.lean', import.meta.url), 'utf8');
const expr = await readFile(new URL('../packages/erasure/src/Ps/Erasure/Expr.lean', import.meta.url), 'utf8');
function validate(source) {
  for (const marker of [
    'psEraseNatRecursorAlternatives',
    'psStringEq zeroName "zero"', 'psStringEq succName "succ"',
    'psListIsEmpty zeroBindings', 'psListIsEmpty bindingsTail', 'psListIsEmpty tail',
    'PsVerifiedIrIntrinsic.natEq', 'PsVerifiedIrIntrinsic.natSub',
    'if psNameEq inductiveInfo.coreName psNatName then',
  ]) assert(source.includes(marker), `missing Nat recursion lowering guard: ${marker}`);
}
assert(basic.includes('runtimeRecursors := psErasureIndexInsert PsRuntimeInductiveInfo PsErasureNameIndex.empty psNatRecName psErasureNatRecursor'));
assert(basic.includes('PsRuntimeConstructorField.mk 0 "predecessor" (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat) true'));
validate(expr);
for (const marker of ['psStringEq zeroName "zero"', 'psListIsEmpty zeroBindings', 'psListIsEmpty bindingsTail']) {
  assert.throws(() => validate(expr.replaceAll(marker, 'true')));
}
console.log('PSC2_NAT_RECURSOR_ERASURE_SOURCE: PASS (primitive Nat representation, structural hypotheses and exact branch shape)');
