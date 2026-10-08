import test from 'node:test';
import assert from 'node:assert/strict';
import { forbiddenSurfaceTokens, requireM0SourcePolicy } from '../policy.mjs';

test('accepts a simple bounded pure source', () => {
  const source = 'function add(x: Nat, y: Nat): Nat := { x + y }';
  assert.deepEqual(forbiddenSurfaceTokens(source), []);
  assert.doesNotThrow(() => requireM0SourcePolicy(source));
});

test('ignores forbidden words in strings and nested comments', () => {
  const source = [
    'const message: String := "unsafe partial \\"sorry\\""',
    '/- unsafe /- sorry -/ partial -/',
    '-- axiom',
    'function value(x: Nat): Nat := { x }',
  ].join('\n');
  assert.deepEqual(forbiddenSurfaceTokens(source), []);
});

test('flags unsound surface forms without treating them as evidence', () => {
  const source = 'partial def bad : Nat := sorry\naxiom fake : False';
  const violations = forbiddenSurfaceTokens(source);
  assert.deepEqual(violations.map(v => v.word), ['partial', 'sorry', 'axiom']);
  assert.throws(() => requireM0SourcePolicy(source), /PSCV_LEAN_SOURCE_REJECT/);
});

test('does not silently accept an unterminated block comment', () => {
  assert.throws(() => forbiddenSurfaceTokens('/- open'), /unterminated block comment/);
});

test('does not silently accept an unterminated string', () => {
  assert.throws(() => forbiddenSurfaceTokens('"unsafe'), /unterminated string/);
});

test('tracks forbidden token locations', () => {
  assert.deepEqual(forbiddenSurfaceTokens('def x := 1\nunsafe def y := 2'),
    [{ word: 'unsafe', line: 2, column: 1 }]);
});
