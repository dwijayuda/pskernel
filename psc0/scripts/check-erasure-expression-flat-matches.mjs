import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

export function assertErasureExpressionFlatMatches(source) {
  const required = [
    'match view.head with',
    'match view.args with\n        | List.cons type afterType =>',
    'match afterType with\n            | List.cons left afterLeft =>',
    'match afterLeft with\n                | List.cons right remaining =>',
    'match remaining with\n                    | List.nil =>',
    'match psErasureExprListAt view.args 1 with',
    'match psErasureExprListAt view.args 3 with',
    'match psErasureExprListAt view.args 4 with',
    'match entry with\n        | Prod.mk key value =>',
    'match recursiveParameterIndex with',
    'match scrutinee with',
    'let typeLocalPresent : Bool :=',
    'fun (nextScope : PsErasureScope) (value : PsExpr) =>',
    'match psErasureFindProjectionField index structureInfo.fields with',
  ];
  for (const marker of required) assert.ok(source.includes(marker), `ERASURE_FLAT_MATCH_MISSING: ${marker}`);
  assert.doesNotMatch(source, /\(\s*(?:match|fun)\b/, 'ERASURE_FLAT_MATCH_FORBIDDEN: complex argument');
  // Primitive argument-selection lists may contain commas inside one scrutinee.
  const withoutLists = source.replace(/\[[^\[\]\n]*\]/g, '[]');
  assert.doesNotMatch(withoutLists, /\bmatch\b(?:(?!\bwith\b)[\s\S])*?,(?:(?!\bwith\b)[\s\S])*?\bwith\b/, 'ERASURE_FLAT_MATCH_FORBIDDEN: multiple scrutinees');
  assert.doesNotMatch(source, /\| Except\.ok \(some\b/, 'ERASURE_FLAT_MATCH_FORBIDDEN: nested option pattern');
}

const source = await readFile(new URL('../packages/erasure/src/Ps/Erasure/Expr.lean', import.meta.url), 'utf8');
assertErasureExpressionFlatMatches(source);
for (const [from, to] of [
  ['match view.head with', 'match view.head, view.args with'],
  ['List.cons type afterType =>', '[type, left, right] =>'],
  ['match psErasureExprListAt view.args 1 with', 'match psErasureExprListAt view.args 1, psErasureExprListAt view.args 3 with'],
  ['| Except.ok candidate =>', '| Except.ok (some candidate) =>'],
  ['match recursiveParameterIndex with', 'match recursiveParameterIndex, state.scope.currentDefinition with'],
  ['fun (nextScope : PsErasureScope) (value : PsExpr) =>', 'fun nextScope value =>'],
]) {
  assert.ok(source.includes(from));
  assert.throws(() => assertErasureExpressionFlatMatches(source.replace(from, to)), /ERASURE_FLAT_MATCH/);
}
console.log('PSC2_ERASURE_EXPRESSION_FLAT_MATCHES: PASS (unary matches, flat patterns and typed callbacks; six rejection mutations)');
