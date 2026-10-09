import assert from 'node:assert/strict';
import { test } from 'node:test';
import { existsSync } from 'node:fs';
import { mkdtemp, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { assertProofScriptGrammar, readProofScriptImports, readProofScriptImportsWithSeed, readProofScriptSource } from './proofscript-source.mjs';
import { sh1GrammarProfile } from './sh1-grammar-conformance.mjs';

const grammarIdentity = Object.freeze({
  psProofScriptGrammarEdition: sh1GrammarProfile.edition,
  psProofScriptGrammarMode: sh1GrammarProfile.mode,
  psProofScriptGrammarReferenceSha256: sh1GrammarProfile.referenceSha256,
});
const tag = Symbol('test-constructor');
const ok = value => ({ [tag]: 'ok', value });
const list = values => values.reduceRight((tail, head) => ({ [tag]: 'cons', head, tail }), { [tag]: 'nil' });
test('generated source adapter delegates complete raw source and AST import names', () => {
  const source = '\uFEFFimport /- comment ; \t -/ Real.Module\nconst answer : Nat := 42\n';
  let parses = 0, names = 0;
  const compiler = {
    ...grammarIdentity,
    psParseProofScriptSource(raw) {
      parses++; assert.equal(raw, source);
      return ok({ imports: list([{ moduleName: { id: 1 } }, { moduleName: { id: 2 } }]) });
    },
    psPrintSyntaxName(name) { names++; return ok(name.id === 1 ? 'Real.Module' : 'Other.Module'); },
  };
  assert.deepEqual(readProofScriptImports(compiler, source), ['Real.Module', 'Other.Module']);
  assert.equal(parses, 1); assert.equal(names, 2);
});
test('generated parser errors and missing parser API cannot become empty imports', () => {
  assert.throws(() => readProofScriptImports({ ...grammarIdentity }, 'import Missing;\n'), /SOURCE_PARSER_API_MISSING/);
  const compiler = {
    ...grammarIdentity,
    psParseProofScriptSource: () => ({ [tag]: 'error', error: { offset: 9n } }),
    psPrintSyntaxName: () => { throw new Error('must not print a rejected module'); },
  };
  assert.throws(() => readProofScriptImports(compiler, 'import Missing;\n', 'Bad.ps'),
    /SOURCE_PARSE_FAILED: Bad\.ps/);
});
test('generated import-list shape failure cannot silently hide a dependency', () => {
  const compiler = { ...grammarIdentity, psParseProofScriptSource: () => ok({}), psPrintSyntaxName: () => ok('Ignored') };
  assert.throws(() => readProofScriptImports(compiler, ''), /SOURCE_IMPORTS_RESULT_SHAPE/);
  compiler.psParseProofScriptSource = () => ok({ imports: { wrong: true } });
  assert.throws(() => readProofScriptImports(compiler, ''), /SOURCE_IMPORTS_RESULT_SHAPE/);
});

test('current PS host refuses historical and mismatched compiler grammar identities before parsing', () => {
  for (const identity of [
    {},
    { ...grammarIdentity, psProofScriptGrammarEdition: 'historical' },
    { ...grammarIdentity, psProofScriptGrammarMode: 'compatibility' },
    { ...grammarIdentity, psProofScriptGrammarReferenceSha256: '0'.repeat(64) },
  ]) {
    let parses = 0;
    const compiler = {
      ...identity,
      psParseProofScriptSource() { parses++; return ok({ imports: list([]) }); },
      psPrintSyntaxName: () => ok('Ignored'),
    };
    assert.throws(() => assertProofScriptGrammar(compiler), /SOURCE_GRAMMAR_COMPILER_MISMATCH/);
    assert.throws(() => readProofScriptImports(compiler, 'def answer : Nat := 42\n'),
      /SOURCE_GRAMMAR_COMPILER_MISMATCH/);
    assert.equal(parses, 0);
  }
});

const binary = process.env.PSC2_CHECKED_SEED_BIN ?? fileURLToPath(new URL(
  '../lean-checked/.lake/build/bin/psc2_lean_checked_seed' +
  (process.platform === 'win32' ? '.exe' : ''), import.meta.url));
const available = existsSync(binary);
test('actual native parser discovers commented imports and preserves legal literal/comment bytes',
  { skip: !available }, () => {
    const source = '\uFEFFimport /- ;\t -/ Demo.Core\n' +
      'def text : String := "literal;\\t"\n';
    assert.deepEqual(readProofScriptImportsWithSeed(binary, source), ['Demo.Core']);
  });
for (const [label, source] of [
  ['semicolon import', 'import Missing;\n'],
  ['tab in import', 'import\tMissing\n'],
  ['lone CR in import', 'import Missing\r'],
  ['old declaration separator', 'def answer : Nat := 42;\n'],
]) {
  test('actual native parser rejects ' + label, { skip: !available }, () => {
    assert.throws(() => readProofScriptImportsWithSeed(binary, source, 'Bad.ps'), /SOURCE_PARSE_FAILED/);
  });
}

test('PS file reads reject malformed UTF-8 and retain a leading BOM for the lexer', async () => {
  const dir = await mkdtemp(path.join(tmpdir(), 'psc2-source-utf8-'));
  try {
    const file = path.join(dir, 'Main.ps');
    const valid = '\uFEFFdef text : String := "λ😀"\n';
    await writeFile(file, valid);
    assert.equal(await readProofScriptSource(file), valid);
    await writeFile(file, new Uint8Array([0x69, 0x6d, 0x70, 0x6f, 0x72, 0x74, 0x20, 0xc3, 0x28]));
    await assert.rejects(readProofScriptSource(file), /SOURCE_UTF8_INVALID/);
  } finally { await rm(dir, { recursive: true, force: true }); }
});
