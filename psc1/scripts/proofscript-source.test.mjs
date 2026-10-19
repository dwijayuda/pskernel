import assert from 'node:assert/strict';
import { test } from 'node:test';
import { createHash } from 'node:crypto';
import { existsSync } from 'node:fs';
import { mkdtemp, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { assertProofScriptGrammar, readProofScriptImports, readProofScriptImportsWithSeed, readProofScriptSource } from './proofscript-source.mjs';
import { sh1GrammarProfile } from './sh1-grammar-conformance.mjs';
import { createGeneratedPreparationSession } from './generated-preparation-session.mjs';

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


// These doubles check the host session boundary and receipt contract. They do
// not implement or claim to validate PS syntax; actual parser tests follow.
function preparationCompiler(identity = {}) {
  const calls = { start: 0, parse: 0, step: 0, finish: 0 };
  const compiler = Object.freeze({
    ...identity,
    PsCompilerSourceKind: Object.freeze({ lean: 'lean', proofScript: 'proofScript' }),
    psCompilerPreparationStart(kind) {
      calls.start++; return { kind, modules: [] };
    },
    psCompilerParseSource(kind, source) {
      calls.parse++; return ok({ kind, source });
    },
    psCompilerPreparationStepParsed(state, module) {
      calls.step++; return ok({ kind: state.kind, modules: [...state.modules, module] });
    },
    psCompilerPreparationFinish(state) {
      calls.finish++; return ok({ kind: state.kind, modules: state.modules });
    },
  });
  return { compiler, calls };
}
const sessionHash = value => createHash('sha256').update(value, 'utf8').digest('hex');
const sessionCompilerSha256 = '8'.repeat(64);
test('reusable PS preparation rejects old and mismatched grammars before compiler operations', () => {
  for (const identity of [
    {},
    { ...grammarIdentity, psProofScriptGrammarEdition: 'historical' },
    { ...grammarIdentity, psProofScriptGrammarMode: 'compatibility' },
    { ...grammarIdentity, psProofScriptGrammarReferenceSha256: '0'.repeat(64) },
  ]) {
    const { compiler, calls } = preparationCompiler(identity);
    const session = createGeneratedPreparationSession(compiler, { compilerSha256: sessionCompilerSha256 });
    for (const sources of [[], [{ path: 'answer.ps', source: 'def answer : Nat := 42\n' }]]) {
      assert.throws(() => session.prepare('proofScript', sources), /SOURCE_GRAMMAR_COMPILER_MISMATCH/);
    }
    assert.deepEqual(calls, { start: 0, parse: 0, step: 0, finish: 0 });
  }
});
test('reusable current PS preparation binds grammar in cold and warm receipts', () => {
  const { compiler, calls } = preparationCompiler(grammarIdentity);
  const session = createGeneratedPreparationSession(compiler, { compilerSha256: sessionCompilerSha256 });
  const sources = [{ path: 'answer.ps', source: 'def answer : Nat := 42\n' }];
  const cold = session.prepare('proofScript', sources);
  const warm = session.prepare('proofScript', sources);
  const expectedClosureSha256 = sessionHash(JSON.stringify({
    sourceKind: 'proofScript',
    sourceGrammar: sh1GrammarProfile,
    modules: sources.map(({ path, source }) => ({ path, sha256: sessionHash(source) })),
  }));
  for (const result of [cold, warm]) {
    assert.equal(result.receipt.compilerSha256, sessionCompilerSha256);
    assert.deepEqual(result.receipt.sourceGrammar, sh1GrammarProfile);
    assert(Object.isFrozen(result.receipt.sourceGrammar));
    assert.equal(result.receipt.closureSha256, expectedClosureSha256);
  }
  assert.equal(warm.prepared, cold.prepared);
  assert.equal(warm.receipt.cache.finishHit, true);
  assert.deepEqual(calls, { start: 1, parse: 1, step: 1, finish: 1 });
});
test('reusable historical Lean preparation retains its receipt and warm state after PS refusal', () => {
  const { compiler, calls } = preparationCompiler();
  const session = createGeneratedPreparationSession(compiler, { compilerSha256: sessionCompilerSha256 });
  const sources = [{ path: 'answer.lean', source: 'def answer : Nat := 42\n' }];
  const cold = session.prepare('lean', sources);
  assert.throws(() => session.prepare('proofScript', []), /SOURCE_GRAMMAR_COMPILER_MISMATCH/);
  const warm = session.prepare('lean', sources);
  const expectedClosureSha256 = sessionHash(JSON.stringify({
    sourceKind: 'lean',
    modules: sources.map(({ path, source }) => ({ path, sha256: sessionHash(source) })),
  }));
  for (const result of [cold, warm]) {
    assert.equal(Object.hasOwn(result.receipt, 'sourceGrammar'), false);
    assert.equal(result.receipt.closureSha256, expectedClosureSha256);
  }
  assert.equal(warm.prepared, cold.prepared);
  assert.equal(warm.receipt.cache.finishHit, true);
  assert.deepEqual(calls, { start: 1, parse: 1, step: 1, finish: 1 });
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
