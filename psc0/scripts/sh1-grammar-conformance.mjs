import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';

// This is a finite API gate for the supported source subset. It is not the
// reference's complete Standard/PSCV conformance suite or a kernel proof.
// The caller loads and identifies a compiler, then decides where to save the
// returned receipt. No compiler loading, filesystem access, or subprocesses occur here.
export const sh1GrammarProfile = Object.freeze({
  edition: 'ps-0.9-r3',
  mode: 'new-only',
  support: 'bounded-selfhost-subset',
  referenceSha256: '4c02626fd0b991e8526c64b65f4ffb66b9ce7b688298e82fb0309802a263db71',
  fullStandardConformance: false,
  fullPscvConformance: false,
});

const sha256 = (value) => createHash('sha256').update(value).digest('hex');

function tag(value) {
  if (value === null || typeof value !== 'object') return undefined;
  for (const symbol of Object.getOwnPropertySymbols(value)) {
    if (typeof value[symbol] === 'string') return value[symbol];
  }
  return undefined;
}

function array(value) {
  const result = [];
  while (tag(value) === 'cons') {
    assert(result.length < 10000, 'PSC0_SH1_GRAMMAR_LIST_BOUND');
    result.push(value.head);
    value = value.tail;
  }
  assert.equal(tag(value), 'nil', 'PSC0_SH1_GRAMMAR_LIST_SHAPE');
  return result;
}

function diagnostic(value) {
  if (typeof value === 'bigint') return value.toString();
  if (Array.isArray(value)) return value.map(diagnostic);
  if (value === null || typeof value !== 'object') return value;
  const result = {};
  if (tag(value) !== undefined) result.tag = tag(value);
  for (const key of Object.keys(value).sort()) result[key] = diagnostic(value[key]);
  return result;
}

function tags(value) {
  if (value === null || typeof value !== 'object') return [];
  const own = tag(value);
  return (own === undefined ? [] : [own]).concat(...Object.values(value).map(tags));
}

function ok(value, label) {
  assert.equal(tag(value), 'ok', 'PSC0_SH1_GRAMMAR_' + label + ': ' +
    JSON.stringify(diagnostic(value)));
  return value.value;
}

function refused(value, label, expectedTags) {
  assert.equal(tag(value), 'error', 'PSC0_SH1_GRAMMAR_ACCEPTED_' + label);
  const found = tags(value.error);
  for (const expected of expectedTags) {
    assert(found.includes(expected), 'PSC0_SH1_GRAMMAR_DIAGNOSTIC_' + label +
      ': expected ' + expected + ', received ' + JSON.stringify(diagnostic(value.error)));
  }
  assert(!found.includes('fuelExhausted'), 'PSC0_SH1_GRAMMAR_ACCIDENTAL_EXHAUSTION_' + label);
  return {
    name: label,
    diagnosticTags: found,
    diagnosticSha256: sha256(JSON.stringify(diagnostic(value.error))),
  };
}

function requireApi(compiler, compilerSha256) {
  assert.match(compilerSha256, /^[a-f0-9]{64}$/u, 'PSC0_SH1_GRAMMAR_COMPILER_IDENTITY');
  for (const name of [
    'psCompilerParseSource', 'psCompilerTranslateSource',
    'psCompilerPrepareSource', 'psLexProofScript',
  ]) assert.equal(typeof compiler[name], 'function', 'PSC0_SH1_GRAMMAR_EXPORT_' + name);
  assert(compiler.PsCompilerSourceKind !== undefined, 'PSC0_SH1_GRAMMAR_SOURCE_KIND');
  assert.equal(compiler.psProofScriptGrammarEdition, sh1GrammarProfile.edition,
    'PSC0_SH1_GRAMMAR_EXPORTED_EDITION');
  assert.equal(compiler.psProofScriptGrammarMode, sh1GrammarProfile.mode,
    'PSC0_SH1_GRAMMAR_EXPORTED_MODE');
  assert.equal(compiler.psProofScriptGrammarReferenceSha256, sh1GrammarProfile.referenceSha256,
    'PSC0_SH1_GRAMMAR_EXPORTED_REFERENCE');
}

function parse(compiler, source, label) {
  return ok(compiler.psCompilerParseSource(
    compiler.PsCompilerSourceKind.proofScript, source), label + '_PARSE');
}

function translate(compiler, from, to, source, label) {
  return ok(compiler.psCompilerTranslateSource(from, to, source), label + '_PRINT');
}

// Erase source locations, including the unnamed span inside match alternatives.
// Keep all constructor tags, field names, binder kinds, order, and application
// nesting. Values stay within the compiler instance that produced them.
function syntaxData(value) {
  if (typeof value === 'bigint') return value.toString();
  if (value === null || typeof value !== 'object') return value;
  if ('byteOffset' in value && 'line' in value && 'column' in value) return ['source-position'];
  if ('start' in value && 'stop' in value &&
      value.start !== null && typeof value.start === 'object' && 'byteOffset' in value.start) {
    return ['source-span'];
  }
  return [tag(value) ?? null, ...Object.keys(value).filter((key) => key !== 'span').sort()
    .map((key) => [key, syntaxData(value[key])])];
}

function roundTrip(compiler, source, label) {
  const parsed = parse(compiler, source, label);
  const ps = compiler.PsCompilerSourceKind.proofScript;
  const canonical = translate(compiler, ps, ps, source, label);
  const reparsed = parse(compiler, canonical, label + '_CANONICAL');
  assert.deepEqual(syntaxData(reparsed), syntaxData(parsed),
    'PSC0_SH1_GRAMMAR_AST_ROUND_TRIP_' + label);
  assert.equal(translate(compiler, ps, ps, canonical, label + '_IDEMPOTENT'), canonical,
    'PSC0_SH1_GRAMMAR_PRINTER_IDEMPOTENCE_' + label);
  return {
    parsed, canonical,
    receipt: {
      name: label,
      sourceSha256: sha256(source),
      canonicalSha256: sha256(canonical),
      astSha256: sha256(JSON.stringify(syntaxData(parsed))),
    },
  };
}

const ref = (name) => ['reference', name];
const app = (fn, ...args) => ['app', fn, args];
const unit = ['unit'];

function nameText(name) {
  return array(name.segments).join('.');
}

function applicationShape(term) {
  switch (tag(term)) {
    case 'reference': return ref(nameText(term.name));
    case 'unit': return unit;
    case 'app': return app(applicationShape(term.fn), ...array(term.args).map(applicationShape));
    default: throw new Error('PSC0_SH1_GRAMMAR_UNEXPECTED_APPLICATION_TERM: ' + tag(term));
  }
}

// Explicit expected trees distinguish native argument accumulation from an
// existing grouped/postfix callee. In particular an empty inner call cannot
// disappear when a later native argument is parsed.
const applicationCases = [
  ['explicit-empty-call', 'f()', app(ref('f')), 'f()'],
  ['explicit-unit-argument', 'f(())', app(ref('f'), unit), 'f(())'],
  ['native-unit-argument', 'f ()', app(ref('f'), unit), 'f(())'],
  ['comment-gap-unit-argument', 'f/- comment -/()', app(ref('f'), unit), 'f(())'],
  ['empty-call-then-native', 'f() x', app(app(ref('f')), ref('x')), '(f())(x)'],
  ['grouped-empty-call-then-native', '(f()) x', app(app(ref('f')), ref('x')), '(f())(x)'],
  ['repeated-empty-call', 'f()()', app(app(ref('f'))), '(f())()'],
  ['native-argument-chain', 'f a b', app(ref('f'), ref('a'), ref('b')), 'f(a, b)'],
  ['adjacent-argument-group', 'f(a, b)', app(ref('f'), ref('a'), ref('b')), 'f(a, b)'],
  ['trailing-call-comma', 'f(a, b,)', app(ref('f'), ref('a'), ref('b')), 'f(a, b)'],
  ['postfix-then-native', 'f(a) b', app(app(ref('f'), ref('a')), ref('b')), '(f(a))(b)'],
  ['grouped-native-callee', '(f a) b', app(app(ref('f'), ref('a')), ref('b')), '(f(a))(b)'],
  ['repeated-postfix-call', 'f(a)(b)', app(app(ref('f'), ref('a')), ref('b')), '(f(a))(b)'],
  ['grouped-reference-callee', '(f)(a)', app(ref('f'), ref('a')), 'f(a)'],
  ['grouped-postfix-callee', '(f(a))(b)', app(app(ref('f'), ref('a')), ref('b')), '(f(a))(b)'],
  ['grouped-native-argument', 'f (g a b)', app(ref('f'), app(ref('g'), ref('a'), ref('b'))),
    'f((g(a, b)))'],
  ['nested-postfix-argument', 'f((g(a)))', app(ref('f'), app(ref('g'), ref('a'))), 'f((g(a)))'],
  ['qualified-reference', 'Pkg.f(x)', app(ref('Pkg.f'), ref('x')), 'Pkg.f(x)'],
];

const supportedCases = [
  {
    name: 'newline-commands-and-imports',
    source: 'import Ps.Foundation.Source\nimport Ps.Syntax.Ast\n' +
      'def first : Nat := 1\ndef second : Nat := 2\n',
    declarations: ['definition', 'definition'],
    imports: ['Ps.Foundation.Source', 'Ps.Syntax.Ast'],
  },
  {
    name: 'one-typed-comma-parameter-group',
    source: 'def first(x : Nat, y : Nat,) : Nat := x\n',
    declarations: ['definition'], binders: ['x', 'y'],
    kinds: ['explicit', 'explicit'],
  },
  {
    name: 'nonexplicit-prefix-before-typed-group',
    source: 'def first {alpha : Type} {{beta : Type}} [witness : Witness alpha]' +
      '(x : alpha, y : beta) : alpha := x\n',
    declarations: ['definition'],
    binders: ['alpha', 'beta', 'witness', 'x', 'y'],
    kinds: ['implicit', 'strictImplicit', 'instanceImplicit', 'explicit', 'explicit'],
  },
  {
    name: 'dependent-typed-parameter',
    source: 'def dependent(F : Nat -> Type, x : Nat, y : F x) : Nat := x\n',
    declarations: ['definition'], binders: ['F', 'x', 'y'],
  },
  {
    name: 'grouped-callee-in-binder-type',
    source: 'def dependent(F : Type -> Type, A : Type, value : (F)(A)) : Nat := 0\n',
    declarations: ['definition'], binders: ['F', 'A', 'value'],
  },
  {
    name: 'typed-parenthesized-lambda-callback',
    source: 'def callback : Nat := use((fun (x : Nat) (y : Nat) => x))\n',
    declarations: ['definition'], callbackBinders: ['x', 'y'],
  },
  {
    name: 'typed-lambda-native-callback',
    source: 'def callback : Nat := use (fun (x : Nat) => x)\n',
    declarations: ['definition'], callbackBinders: ['x'],
  },
  {
    name: 'grouped-lambda-callee',
    source: 'def callback : Nat := (fun (x : Nat) => x)(value)\n',
    declarations: ['definition'], valueKind: 'app',
  },
  {
    name: 'braced-single-term-definition',
    source: 'def braced : Nat := { 7 }\n',
    declarations: ['definition'], valueKind: 'natural',
  },
  {
    name: 'let-newline-sequence',
    source: 'def sequence : Nat :=\nlet x := 1\nx\n',
    declarations: ['definition'], valueKind: 'letE',
  },
  {
    name: 'typed-let-within-match',
    source: 'def select(x : Nat) : Nat := match x with {\n' +
      '  | Nat.zero => let y : Nat := 7\n    y\n' +
      '  | Nat.succ rest => rest\n}\n',
    declarations: ['definition'], valueKind: 'matchE',
  },
  {
    name: 'if-braced-branches',
    source: 'def choose : Nat := if (true) { 1 } else { 2 }\n',
    declarations: ['definition'], valueKind: 'ifE',
  },
  {
    name: 'constructor-unified-parameter-groups',
    source: 'inductive Choice(alpha : Type) where {\n' +
      '  | none\n  | some(value : alpha, extra : alpha)\n}\n',
    declarations: ['inductiveDecl'], constructors: [['none', []], ['some', ['value', 'extra']]],
  },
  {
    name: 'newline-structure-fields-and-comma-record',
    source: 'structure Pair where {\n  first : Nat\n  second : Nat\n}\n' +
      'def pair : Pair := { first := 1, second := 2, }\n',
    declarations: ['structureDecl', 'definition'], fields: ['first', 'second'],
  },
  {
    name: 'record-in-definition-wrapper',
    source: 'def pair : Pair := { { first := 1, second := 2 } }\n',
    declarations: ['definition'], valueKind: 'record',
  },
  {
    name: 'empty-record-body',
    source: 'def empty : Empty := {}\n',
    declarations: ['definition'], valueKind: 'record',
  },
  {
    name: 'annotated-parameterless-const-alias',
    source: 'const answer : Nat := 42\n',
    declarations: ['definition'], binders: [],
  },
  {
    name: 'annotated-positive-arity-function-alias',
    source: 'function first(x : Nat, y : Nat) : Nat := x\n',
    declarations: ['definition'], binders: ['x', 'y'],
  },
  {
    name: 'base-partial-and-typed-theorem',
    source: 'partial def loop(n : Nat) : Nat := loop(n)\n' +
      'theorem identity {P : Prop}(p : P) : P := p\n',
    declarations: ['partialDefinition', 'theoremDecl'],
  },
  {
    name: 'literal-round-trips',
    source: 'def word : String := "é_猫"\n' +
      "def letter : Char := 'é'\n" +
      'def flag : Bool := true\ndef nothing : Unit := ()\n',
    declarations: ['definition', 'definition', 'definition', 'definition'],
  },
  {
    name: 'nested-comment-native-gap',
    source: '-- first comment\n' +
      'def probe : Nat := f/- outer /- inner -/ done -/x\n',
    declarations: ['definition'], valueKind: 'app',
  },
  {
    name: 'indented-native-continuation',
    source: 'def probe : Nat :=\nf\n x\n',
    declarations: ['definition'], valueKind: 'app',
  },
];

const parseRefusals = [
  ['semicolon-after-import', 'import Ps.Syntax.Ast;\n'],
  ['semicolon-after-definition', 'def probe : Nat := 0;\n'],
  ['semicolon-let-sequence', 'def probe : Nat := let x := 0; x\n'],
  ['semicolon-structure-field', 'structure Pair where { first : Nat; }\n'],
  ['semicolon-constructor', 'inductive Choice where { | none; }\n'],
  ['semicolon-match-alternative', 'def probe : Nat := match x with { | Nat.zero => 0; }\n'],
  ['same-line-commands', 'def first : Nat := 0 def second : Nat := 1\n'],
  ['same-line-structure-fields', 'structure Pair where { first : Nat second : Nat }\n'],
  ['comma-structure-fields', 'structure Pair where { first : Nat, second : Nat }\n'],
  ['newline-only-record-fields', 'def pair : Pair := { first := 1\nsecond := 2 }\n'],
  ['repeated-declaration-groups', 'def first(x : Nat)(y : Nat) : Nat := x\n'],
  ['repeated-constructor-groups', 'inductive Pair where { | mk(x : Nat)(y : Nat) }\n'],
  ['nonexplicit-binder-after-explicit-group', 'def first(x : Nat) {alpha : Type} : Nat := x\n'],
  ['empty-def-parameter-group', 'def probe() : Nat := 0\n'],
  ['empty-function-parameter-group', 'function probe() : Nat := 0\n'],
  ['function-without-explicit-parameters', 'function probe : Nat := 0\n'],
  ['const-with-parameters', 'const probe(x : Nat) : Nat := x\n'],
  ['omitted-result-annotation', 'def probe := 0\n'],
  ['omitted-parameter-annotation', 'def probe(x) : Nat := x\n'],
  ['default-parameter', 'function probe(x : Nat := 1) : Nat := x\n'],
  ['named-call-argument', 'def probe : Nat := f(x := 1)\n'],
  ['untyped-lambda', 'def probe : Nat := f((fun x => x))\n'],
  ['do-block-not-enabled', 'def probe : Nat := do { return 1 }\n'],
  ['tuple-not-enabled', 'def probe : Nat := (x, y)\n'],
  ['spaced-parentheses-are-not-argument-group', 'def probe : Nat := f (x, y)\n'],
  ['comment-gap-is-not-call-adjacency', 'def probe : Nat := f/- comment -/(x, y)\n'],
  ['unindented-native-continuation', 'def probe : Nat :=\nf\nx\n'],
  ['newline-in-comment-changes-layout', 'def probe : Nat := f/-\n-/x\n'],
  ['qualified-declaration-name', 'def Pkg.probe : Nat := 0\n'],
  ['arbitrary-result-projection-not-enabled', 'def probe : Nat := (f(x)).field\n'],
  ['where-block-not-enabled', 'def probe : Nat := 0 where { helper : Nat := 1 }\n'],
  ['contract-not-enabled', 'function probe(x : Nat) : Nat requires { true } := x\n'],
  ['axiom-not-enabled', 'axiom admitted : Nat\n'],
  ['namespace-not-enabled', 'namespace Demo\nend Demo\n'],
  ['unconsumed-final-token', 'def probe : Nat := 0\nunowned\n'],
];

function checkSupportedShape(module, test) {
  const declarations = array(module.declarations);
  assert.deepEqual(declarations.map(tag), test.declarations, test.name + ': declarations');
  if (test.imports) {
    assert.deepEqual(array(module.imports).map((item) => nameText(item.moduleName)),
      test.imports, test.name + ': imports');
  }
  const first = declarations[0];
  if (test.binders) {
    const binders = array(first.binders);
    assert.deepEqual(binders.map((binder) => nameText(binder.fst.name)), test.binders,
      test.name + ': binder order');
    if (test.kinds) assert.deepEqual(binders.map((binder) => tag(binder.fst.kind)), test.kinds,
      test.name + ': binder kinds');
  }
  if (test.valueKind) assert.equal(tag(first.value), test.valueKind, test.name + ': value');
  if (test.callbackBinders) {
    assert.equal(tag(first.value), 'app', test.name + ': callback application');
    const args = array(first.value.args);
    assert.equal(args.length, 1, test.name + ': callback argument count');
    assert.equal(tag(args[0]), 'lambda', test.name + ': callback lambda');
    assert.deepEqual(array(args[0].binders).map((binder) => nameText(binder.fst.name)),
      test.callbackBinders, test.name + ': lambda binder order');
  }
  if (test.constructors) {
    assert.deepEqual(array(first.constructors).map((constructor) => [
      nameText(constructor.name),
      array(constructor.fields).map((field) => nameText(field.fst.name)),
    ]), test.constructors, test.name + ': constructor parameters');
  }
  if (test.fields) {
    assert.deepEqual(array(first.fields).map((field) => nameText(field.fst.name)),
      test.fields, test.name + ': field order');
    assert.equal(tag(declarations[1].value), 'record', test.name + ': record');
    assert.deepEqual(array(declarations[1].value.fields).map((field) => nameText(field.fst)),
      test.fields, test.name + ': record field order');
  }
}

function positionData(position) {
  for (const key of ['byteOffset', 'line', 'column']) {
    assert.equal(typeof position[key], 'bigint', 'PSC0_SH1_GRAMMAR_POSITION_' + key);
  }
  return { byteOffset: position.byteOffset, line: position.line, column: position.column };
}

function checkLexical(compiler) {
  const positions = [];
  const sources = [
    ['ascii-lf', 'def first : Nat := 1\n  def second : Nat := 2\n', 0n],
    ['leading-bom-crlf-utf8', '\uFEFFdef first : String := "é"\r\n  def second : Nat := 2\r\n', 3n],
  ];
  for (const [name, source, initialOffset] of sources) {
    const tokens = array(ok(compiler.psLexProofScript(source), name + '_LEX'));
    const definitions = tokens.filter((token) => token.text === 'def');
    assert.equal(definitions.length, 2, name + ': command tokens');
    assert.deepEqual(positionData(definitions[0].span.start),
      { byteOffset: initialOffset, line: 1n, column: 1n }, name + ': initial position');
    const secondIndex = source.indexOf('def second');
    assert.deepEqual(positionData(definitions[1].span.start), {
      byteOffset: BigInt(Buffer.byteLength(source.slice(0, secondIndex))),
      line: 2n, column: 3n,
    }, name + ': second position');
    const end = tokens.at(-1);
    assert.equal(tag(end.kind), 'endOfInput', name + ': final token');
    assert.deepEqual(positionData(end.span.start), {
      byteOffset: BigInt(Buffer.byteLength(source)), line: 3n, column: 1n,
    }, name + ': original byte offsets');
    assert.deepEqual(positionData(end.span.stop), positionData(end.span.start), name + ': empty end span');
    assert.equal(array(parse(compiler, source, name).declarations).length, 2, name + ': parse');
    positions.push({ name, sourceSha256: sha256(source),
      first: diagnostic(definitions[0].span.start),
      second: diagnostic(definitions[1].span.start), end: diagnostic(end.span.start) });
  }
  const literalAndCommentSource =
    '/- \t\r\uFEFF outer /- nested -/ comment -/\n' +
    'def word : String := "a\tb"\n';
  ok(compiler.psLexProofScript(literalAndCommentSource), 'COMMENT_LITERAL_WHITESPACE_LEX');
  const rejected = [];
  for (const [name, source, offset] of [
    ['tab-outside-comment-or-literal', 'def\tprobe : Nat := 0\n', 3n],
    ['lone-cr-outside-comment-or-literal', 'def probe : Nat := 0\rdef next : Nat := 1\n', 20n],
    ['lone-cr-at-end', 'def probe : Nat := 0\r', 20n],
    ['repeated-bom', '\uFEFF\uFEFFdef probe : Nat := 0\n', 3n],
    ['nonleading-bom', ' \uFEFFdef probe : Nat := 0\n', 1n],
  ]) {
    const result = compiler.psLexProofScript(source);
    const observation = refused(result, name, ['invalidSource']);
    assert.equal(result.error.span.start.byteOffset, offset, name + ': offending byte');
    refused(compiler.psCompilerParseSource(compiler.PsCompilerSourceKind.proofScript, source),
      name + '_FRONTEND', ['proofScriptFrontend', 'lex', 'invalidSource']);
    rejected.push({ ...observation, sourceSha256: sha256(source),
      start: diagnostic(result.error.span.start) });
  }
  return { positions, commentAndLiteralWhitespace: {
    sourceSha256: sha256(literalAndCommentSource), result: 'accepted',
  }, refusals: rejected, rawUtf8ByteValidation: 'host input boundary; not exercised by the String API' };
}

function checkEmptyCallMeaning(compiler) {
  const ps = compiler.PsCompilerSourceKind.proofScript;
  const prefix = 'def unitTarget(value : Unit) : Nat := 7\n';
  const acceptedSource = prefix + 'def accepted : Nat := unitTarget(())\n';
  ok(compiler.psCompilerPrepareSource(ps, acceptedSource), 'EXPLICIT_UNIT_PREPARE');
  const refusals = [];
  for (const [name, source] of [
    ['empty-call-completion-not-enabled', prefix + 'def rejected : Nat := unitTarget()\n'],
    ['empty-call-preserved-under-native-application',
      'def target(value : Unit, other : Nat) : Nat := other\n' +
      'def rejected : Nat := target() 7\n'],
    ['grouped-empty-call-preserved-under-native-application',
      'def target(value : Unit, other : Nat) : Nat := other\n' +
      'def rejected : Nat := (target()) 7\n'],
  ]) {
    parse(compiler, source, name);
    refusals.push({ ...refused(compiler.psCompilerPrepareSource(ps, source),
      name, ['emptyCallUnsupported']), sourceSha256: sha256(source) });
  }
  return {
    explicitUnit: { sourceSha256: sha256(acceptedSource), preparation: 'accepted' },
    automaticOrDefaultCompletion: 'explicitly refused', refusals,
  };
}

export function runSh1GrammarConformance({ compiler, compilerSha256 }) {
  requireApi(compiler, compilerSha256);
  const applications = [];
  for (const [name, expression, expected, expectedCanonical] of applicationCases) {
    const source = 'def probe : Nat := ' + expression + '\n';
    const result = roundTrip(compiler, source, name);
    const declarations = array(result.parsed.declarations);
    assert.equal(declarations.length, 1, name + ': single probe');
    assert.deepEqual(applicationShape(declarations[0].value), expected,
      'PSC0_SH1_GRAMMAR_APPLICATION_BOUNDARY_' + name);
    assert.equal(result.canonical, 'def probe : Nat := ' + expectedCanonical + '\n',
      'PSC0_SH1_GRAMMAR_CANONICAL_APPLICATION_' + name);
    applications.push(result.receipt);
  }
  const supported = [];
  for (const test of supportedCases) {
    const result = roundTrip(compiler, test.source, test.name);
    checkSupportedShape(result.parsed, test);
    supported.push(result.receipt);
  }
  const refusals = parseRefusals.map(([name, source]) => ({
    ...refused(compiler.psCompilerParseSource(compiler.PsCompilerSourceKind.proofScript, source),
      name, ['proofScriptFrontend', 'parse']),
    sourceSha256: sha256(source),
  }));
  const lexical = checkLexical(compiler);
  const emptyCallMeaning = checkEmptyCallMeaning(compiler);
  const interleavedSource = 'def probe(x : Nat) {alpha : Type} : Nat := x\n';
  const printerRefusal = {
    ...refused(compiler.psCompilerTranslateSource(compiler.PsCompilerSourceKind.lean,
      compiler.PsCompilerSourceKind.proofScript, interleavedSource),
    'printer-refuses-binder-reordering', ['unsupportedSourceForm']),
    sourceSha256: sha256(interleavedSource),
  };
  return {
    schemaVersion: 1,
    evidence: 'generated-compiler-source-grammar-api',
    compilerSha256,
    sourceGrammar: sh1GrammarProfile,
    corpusSha256: sha256(JSON.stringify({
      applicationCases, supportedCases, parseRefusals,
      lexicalSources: lexical.positions.concat(lexical.commentAndLiteralWhitespace, lexical.refusals)
        .map((item) => item.sourceSha256),
      elaborationSources: [emptyCallMeaning.explicitUnit, ...emptyCallMeaning.refusals]
        .map((item) => item.sourceSha256),
      printerSource: printerRefusal.sourceSha256,
    })),
    counts: {
      applicationBoundaries: applications.length,
      supportedSyntax: supported.length,
      canonicalRoundTrips: applications.length + supported.length,
      parseRefusals: refusals.length,
      lexicalPositionCases: lexical.positions.length,
      lexicalRefusals: lexical.refusals.length,
      emptyCallRefusals: emptyCallMeaning.refusals.length,
      printerRefusals: 1,
    },
    applications, supported, refusals, lexical, emptyCallMeaning, printerRefusal,
    scope: {
      finiteCorpus: true,
      smallGrammarCasesUseProofScriptRoundTrips: true,
      fullClosureRoundTrip: 'separate optional N1 gate',
      fullStandardConformance: false,
      fullPscvConformance: false,
      kernelChecked: false,
    },
  };
}

// The qualifier invokes this once with its already captured N1 closure. The
// generated stages run the small gate above; do not repeat this full closure
// merely to obtain another receipt. This checks canonical source correspondence,
// not equality of whole-program semantics or a provider/kernel proof.
export function runSh1GrammarClosureRoundTrip({ compiler, compilerSha256, closure }) {
  requireApi(compiler, compilerSha256);
  assert(closure && Array.isArray(closure.ordered) && closure.ordered.length > 0,
    'PSC0_SH1_GRAMMAR_CLOSURE_INPUT');
  assert.equal(closure.moduleCount, closure.ordered.length, 'PSC0_SH1_GRAMMAR_CLOSURE_COUNT');
  const manifest = closure.ordered.map((item) => {
    assert.equal(typeof item.path, 'string', 'PSC0_SH1_GRAMMAR_CLOSURE_PATH');
    assert.equal(typeof item.source, 'string', 'PSC0_SH1_GRAMMAR_CLOSURE_SOURCE');
    assert.equal(sha256(item.source), item.sha256, 'PSC0_SH1_GRAMMAR_CLOSURE_SOURCE_DIGEST');
    return { path: item.path, sha256: item.sha256 };
  });
  assert.equal(new Set(manifest.map((item) => item.path)).size, manifest.length,
    'PSC0_SH1_GRAMMAR_CLOSURE_DUPLICATE');
  assert.deepEqual(manifest, closure.manifest, 'PSC0_SH1_GRAMMAR_CLOSURE_MANIFEST');
  assert.equal(sha256(JSON.stringify(manifest)), closure.sha256, 'PSC0_SH1_GRAMMAR_CLOSURE_DIGEST');
  const lean = compiler.PsCompilerSourceKind.lean;
  const ps = compiler.PsCompilerSourceKind.proofScript;
  const modules = [];
  const canonicalSurfaceSources = [];
  for (const item of closure.ordered) {
    const canonicalLean = translate(compiler, lean, lean, item.source, item.path + '_LEAN');
    const newProofScript = translate(compiler, lean, ps, item.source, item.path + '_PS');
    const recoveredLean = translate(compiler, ps, lean, newProofScript, item.path + '_BACK');
    assert.equal(recoveredLean, canonicalLean, 'PSC0_SH1_GRAMMAR_CLOSURE_CORRESPONDENCE_' + item.path);
    assert.equal(translate(compiler, ps, ps, newProofScript, item.path + '_IDEMPOTENT'), newProofScript,
      'PSC0_SH1_GRAMMAR_CLOSURE_PRINTER_IDEMPOTENCE_' + item.path);
    canonicalSurfaceSources.push({ path: item.path.replace(/\.lean$/u, '.ps'), source: newProofScript });
    modules.push({
      path: item.path, rawSourceSha256: item.sha256,
      proofScriptSha256: sha256(newProofScript),
      canonicalLeanSha256: sha256(canonicalLean),
      proofScriptBytes: Buffer.byteLength(newProofScript),
    });
  }
  return {
    schemaVersion: 1,
    evidence: 'full-authored-closure-canonical-source-correspondence',
    compilerSha256,
    sourceGrammar: sh1GrammarProfile,
    closureSha256: closure.sha256,
    canonicalSurfaceSourceSha256: sha256(JSON.stringify(canonicalSurfaceSources, null, 2) + '\n'),
    moduleCount: modules.length,
    rawSourceBytes: closure.ordered.reduce((total, item) => total + Buffer.byteLength(item.source), 0),
    proofScriptBytes: modules.reduce((total, item) => total + item.proofScriptBytes, 0),
    comparison: 'Lean canonical text equals Lean -> new ProofScript -> Lean; new ProofScript is idempotent',
    modules,
    fullStandardConformance: false,
    fullPscvConformance: false,
    kernelChecked: false,
  };
}
