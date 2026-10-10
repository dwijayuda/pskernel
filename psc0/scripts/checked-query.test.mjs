import assert from 'node:assert/strict';
import { test } from 'node:test';
import { syntaxErrorRange, queryCheckedSource } from './checked-query.mjs';

test('syntax byte spans map to zero-based UTF-16 LSP positions', () => {
  const source = 'a😀\r\nb';
  assert.deepEqual(syntaxErrorRange(source, {
    span: { start: { byteOffset: 7n }, stop: { byteOffset: 8n } },
  }), { start: { line: 1, character: 0 }, end: { line: 1, character: 1 } });
  assert.deepEqual(syntaxErrorRange(source, {
    span: { start: { byteOffset: 1n }, stop: { byteOffset: 5n } },
  }), { start: { line: 0, character: 1 }, end: { line: 0, character: 3 } });
  assert.equal(syntaxErrorRange(source, {
    span: { start: { byteOffset: 2 }, stop: { byteOffset: 5 } },
  }), null, 'byte position inside a UTF-8 scalar is not a valid source span');
  assert.equal(syntaxErrorRange(source, {
    span: { start: { byteOffset: 12 }, stop: { byteOffset: 13 } },
  }), null);
  assert.equal(syntaxErrorRange(source, {
    span: { start: { byteOffset: 5 }, stop: { byteOffset: 1 } },
  }), null);
});

test('editor query refuses non-PS source and malformed scalar data', async () => {
  for (const [entryPath, sourceText] of [
    ['src/Main.lean', 'def answer : Nat := 42'],
    ['src/Main.ps', 'a\uD800b'],
    ['src/Main.ps', 'x'.repeat(1024 * 1024 + 1)],
  ]) {
    await assert.rejects(queryCheckedSource({ entryPath, sourceText }), /PSC_QUERY_INPUT_PROFILE/u);
  }
});
