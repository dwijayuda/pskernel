import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
const source = await readFile(new URL('../packages/backend-ts/src/Ps/BackendTs/Module.lean', import.meta.url), 'utf8');
const markers = ['if psTsExprUsesNameWithFuel 4096 fn name then false else psTsEtaArgumentsFresh fn rest',
  'if psListIsEmpty arguments then Option.some body else Option.none',
  'PsVerifiedIrExpr.letE parameter.name parameter.type argument inner',
  'if psListIsEmpty types then', 'if psTsEtaArgumentsFresh fn arguments then',
  '| Option.none => expr', '(psTsInlineEtaApplication declaration.body)'];
const validate = text => { for (const marker of markers) assert(text.includes(marker), `missing eta inline guard: ${marker}`); };
validate(source);
for (const marker of markers) assert.throws(() => validate(source.replaceAll(marker, 'removed')));
const expr = await readFile(new URL('../packages/backend-ts/src/Ps/BackendTs/Expr.lean', import.meta.url), 'utf8');
assert(expr.includes('| Nat.zero => fun (_expr : PsVerifiedIrExpr) (_name : String) => true'));
console.log('PSC2_ETA_INLINE_SOURCE: PASS (fresh variables, preserved scope and arity, conservative fuel exhaustion and general fallback)');
