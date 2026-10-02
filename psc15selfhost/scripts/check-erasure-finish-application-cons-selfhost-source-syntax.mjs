import './check-erasure-finish-application-append-selfhost-source-syntax.mjs';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

export function assertFinishApplicationConstructors(source) {
  const block = source.match(/^def psEraseFinishApplicationWithFuelWorker\b[\s\S]*?(?=^def psEraseFinishApplication\b)/m)?.[0];
  if (!block) throw new Error('PSC2_ERASURE_FINISH_APPLICATION_CONSTRUCTORS_MISSING: declaration');
  for (const pattern of [
    /erasedLocals :=\s*List\.cons\s+pushed\.id\s+scope\.erasedLocals/,
    /runtimeLocals :=\s*List\.cons\s*\(Prod\.mk\s+pushed\.id\s+parameterName\)\s+scope\.runtimeLocals/,
    /\(List\.cons\s*\(PsVerifiedIrParameter\.mk\s+parameterName\s+parameterType\)\s+parametersRev\)/,
  ]) {
    if (!pattern.test(block)) throw new Error(`PSC2_ERASURE_FINISH_APPLICATION_CONSTRUCTORS_MISSING: ${pattern}`);
  }
  if (/::|\(pushed\.id,\s*parameterName\)|List\.cons\s*\{/.test(block)) {
    throw new Error('PSC2_ERASURE_FINISH_APPLICATION_CONSTRUCTORS_FORBIDDEN');
  }
  return block;
}
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const source = await readFile(path.join(root, 'packages/erasure/src/Ps/Erasure/Expr.lean'), 'utf8');
const block = assertFinishApplicationConstructors(source);
const mutations = [
  ['List.cons pushed.id scope.erasedLocals', 'pushed.id :: scope.erasedLocals'],
  ['(Prod.mk pushed.id parameterName)', '(pushed.id, parameterName)'],
  ['(PsVerifiedIrParameter.mk parameterName parameterType)', '{ name := parameterName type := parameterType }'],
];
for (const [good, bad] of mutations) {
  assert.ok(block.includes(good));
  assert.throws(() => assertFinishApplicationConstructors(source.replace(block, block.replace(good, bad))), /CONSTRUCTORS/);
}
assert.throws(() => assertFinishApplicationConstructors(''), /CONSTRUCTORS_MISSING/);
console.log('PSC2_ERASURE_FINISH_APPLICATION_CONS_SELFHOST_SOURCE_SYNTAX: PASS (List.cons, Prod.mk, parameter constructor; four rejection mutations)');
