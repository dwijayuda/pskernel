import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
const read = file => readFile(new URL('../' + file, import.meta.url), 'utf8');
const basic = await read('packages/erasure/src/Ps/Erasure/Basic.lean');
const expr = await read('packages/erasure/src/Ps/Erasure/Expr.lean');
const definition = await read('packages/erasure/src/Ps/Erasure/Definition.lean');
const ts = await read('packages/backend-ts/src/Ps/BackendTs/Expr.lean');
function requireAll(source, markers) {
  for (const marker of markers) assert(source.includes(marker), `missing replay emission guard: ${marker}`);
}
const names = [
  'if psListAny localUses scope.runtimeLocals then true',
  'psErasureIndexFind Bool scope.declarationNames.byOutput (PsName.str PsName.anonymous candidate)',
  'Nat.succ (Nat.add (psListLength scope.runtimeLocals) scope.declarationNames.count)',
  '(scope : PsErasureScope) (base : String) (fuel : Nat) (index : Nat) : String :=',
  'if psErasureLocalNameUsed scope candidate then',
  'psErasureLocalNameWithFuel scope base remaining (Nat.succ index)',
  'if psStringEq sanitized "arguments" then "_arguments"',
  'else if psStringEq sanitized "eval" then "_eval"',
  'if psStringEq base "_" then psErasureLocalNameWithFuel scope fallback fuel id',
  'else if psErasureLocalNameUsed scope base then psErasureLocalNameWithFuel scope base fuel id',
];
const emission = [
  '| PsVerifiedIrExpr.lambda _ _ _ => psTsJoin "" ["(", printedFn, ")"]',
  '["(yield* __ps$invoke(", callable, generic, suffix, "))"]',
  '["({ [", brand, "]: true as const", suffix, " })"]',
];
requireAll(basic, names);
requireAll(ts, emission);
assert.equal((expr.match(/psErasureLocalName\s/g) ?? []).length, 3);
assert.equal((definition.match(/psErasureLocalName\s/g) ?? []).length, 1);
for (const marker of names) assert.throws(() => requireAll(basic.replace(marker, 'removed'), names));
for (const marker of emission) assert.throws(() => requireAll(ts.replace(marker, 'removed'), emission));
console.log('PSC2_REPLAY_EMISSION_SOURCE: PASS (fresh local names, strict bindings, lambda calls and record expressions)');
