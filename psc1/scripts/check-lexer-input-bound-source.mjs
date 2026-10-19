import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
const source = await readFile(new URL('../packages/syntax/src/Ps/Syntax/Lexer.lean', import.meta.url), 'utf8');
const markers = [
  'psLexAllWorker inputBound remainingFuel;',
  'match psLexSkipTriviaWithFuel inputBound cursor.remaining cursor.position with',
  'psLexAllWorker (Nat.succ (psLexListLength cursor.remaining)) fuel cursor',
  'let bound := Nat.succ (String.utf8ByteSize source);',
  'psLexAllWorker bound bound cursor',
];
const validate = text => {
  for (const marker of markers) assert(text.includes(marker), `missing lexer input bound: ${marker}`);
  const worker = text.slice(text.indexOf('def psLexAllWorker'), text.indexOf('def psLexAllWithFuel'));
  assert(!worker.includes('psLexListLength'), 'token loop must not repeatedly count the remaining characters');
};
validate(source);
for (const marker of markers) assert.throws(() => validate(source.replace(marker, 'removed')));
console.log('PSC2_LEXER_INPUT_BOUND_SOURCE: PASS (one input bound, no repeated suffix scans and preserved explicit-fuel entry)');
