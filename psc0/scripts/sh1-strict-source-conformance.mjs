import assert from 'node:assert/strict';
import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { createHash } from 'node:crypto';
import { compileStrictSources, strictSourceOptions } from './sh1-strict-source.mjs';

const sha256 = (value) => createHash('sha256').update(value).digest('hex');
const input = (source, tail = 'StrictCase') => ({
  moduleName: ['Ps', 'Compiler', tail], source,
});
const literal = 'def sh1Literal : Nat := 7\n';


function reservedRuntimeNameCases() {
  const definitions = [
  {
    "name": "Bool.and",
    "lean": "def Bool.and (left : Bool) (right : Bool) : Bool := true\n",
    "ps": "def Bool.and(left : Bool, right : Bool) : Bool := true\n"
  },
  {
    "name": "Bool.or",
    "lean": "def Bool.or (left : Bool) (right : Bool) : Bool := false\n",
    "ps": "def Bool.or(left : Bool, right : Bool) : Bool := false\n"
  },
  {
    "name": "Bool.not",
    "lean": "def Bool.not (value : Bool) : Bool := value\n",
    "ps": "def Bool.not(value : Bool) : Bool := value\n"
  },
  {
    "name": "Array.getInternal",
    "lean": "def Array.getInternal {alpha : Type} (values : Array alpha) (index : Nat) (fallback : alpha) : alpha := fallback\n",
    "ps": "def Array.getInternal {alpha : Type}(values : Array alpha, index : Nat, fallback : alpha) : alpha := fallback\n"
  },
  {
    "name": "Array.set",
    "lean": "def Array.set {alpha : Type} (values : Array alpha) (index : Nat) (value : alpha) (ignored : Nat) : Array alpha := values\n",
    "ps": "def Array.set {alpha : Type}(values : Array alpha, index : Nat, value : alpha, ignored : Nat) : Array alpha := values\n"
  },
  {
    "name": "String.Pos.Raw",
    "policyCode": "source-builtin-type-name-reserved",
    "lean": "inductive String.Pos.Raw where\n  | marker\n",
    "ps": "inductive String.Pos.Raw where {\n  | marker\n}\n"
  }
];
  return definitions.flatMap((definition) => ['lean', 'ps'].map((kind) => ({
    id: 'reserved-runtime-name-' + definition.name + '-' + kind, kind,
    inputs: [input(definition[kind])],
    code: kind === 'lean' ? definition.policyCode ?? 'source-intrinsic-name-reserved' : 'source-compiler',
    ...(kind === 'lean' ? { exactName: definition.name } : {}),
    boundary: kind === 'lean' ? 'portable-source-name-policy' : 'new-only-ps-declared-name-grammar',
  })));
}

function sourceCases() {
  return [
    { id: 'empty-bundle', inputs: [], code: 'source-empty-bundle' },
    { id: 'duplicate-module', inputs: [input(literal), input(literal)], code: 'source-module-duplicate' },
    { id: 'forbidden-module', inputs: [{ moduleName: ['Ps', 'Kernel', 'StrictCase'], source: literal }],
      code: 'source-module-package' },
    { id: 'empty-module-segment', inputs: [{ moduleName: ['Ps', 'Compiler', ''], source: literal }],
      code: 'source-module-name' },
    { id: 'missing-import', inputs: [input('import Ps.Compiler.Missing\n' + literal)],
      code: 'source-import-unresolved' },
    { id: 'forward-import', inputs: [input('import Ps.Compiler.Later\n' + literal), input('', 'Later')],
      code: 'source-import-unresolved' },
    { id: 'self-import', inputs: [input('import Ps.Compiler.StrictCase\n' + literal)],
      code: 'source-import-unresolved' },
    { id: 'forbidden-import', inputs: [input('import Ps.Kernel.Forbidden\n' + literal)],
      code: 'source-import-package' },
    { id: 'non-package-import', inputs: [input('import Lean\n' + literal)],
      code: 'source-import-package' },
    { id: 'partial-definition',
      inputs: [input('partial def sh1Partial (value : Nat) : Nat := value\n')],
      code: 'source-partial-definition' },
    { id: 'do-expansion', inputs: [input('def sh1Do : Nat := do return 7\n')],
      code: 'source-do-unsupported', exactDoSpan: true },
    { id: 'missing-result-signature', inputs: [input('def sh1Missing (value : Nat) := value\n')],
      code: 'source-compiler' },
    { id: 'axiom-command', inputs: [input('axiom sh1Axiom : Nat\n')], code: 'source-compiler' },
    { id: 'opaque-command', inputs: [input('opaque sh1Opaque : Nat := 7\n')], code: 'source-compiler' },
    { id: 'old-ps-semicolon', kind: 'ps', inputs: [input('def sh1Old : Nat := 7;\n')],
      code: 'source-compiler' },
    { id: 'module-budget', inputs: [input(literal)], limits: { maxModules: 0 }, code: 'source-module-limit' },
    { id: 'input-byte-budget', inputs: [input(literal)], limits: { maxInputBytes: 25 },
      code: 'source-input-byte-limit' },
    { id: 'name-traversal-budget', inputs: [input(literal)], limits: { maxSyntaxSteps: 0 },
      code: 'source-name-limit' },
    { id: 'syntax-budget', inputs: [input(literal)], limits: { maxSyntaxSteps: 3 },
      code: 'source-syntax-limit' },
    { id: 'type-position-budget', inputs: [input(literal)], limits: { maxTypeSteps: 0 },
      code: 'source-type-limit' },
    { id: 'term-position-budget', inputs: [input(literal)], limits: { maxTermSteps: 0 },
      code: 'source-term-limit' },
    ...reservedRuntimeNameCases(),
  ];
}

export async function runStrictSourceConformance({ compiler, compilerSha256, outDir }) {
  const accepted = [];
  const libraries = {
    lean: 'structure Sh1DoField where\n  do : Nat\n' +
      'def sh1ExplicitHelpers (compilerPure : Nat -> Nat) (compilerBind : Nat -> Nat) (value : Nat) : Nat := compilerBind (compilerPure value)\n' +
      '-- do compilerPure compilerBind are comment text.\n' +
      'def sh1OriginWords : String := "do compilerPure compilerBind"\n',
    ps: 'structure Sh1DoField where {\n  do : Nat\n}\n' +
      'def sh1ExplicitHelpers(compilerPure : Nat -> Nat, compilerBind : Nat -> Nat, value : Nat) : Nat := compilerBind(compilerPure(value))\n' +
      '-- do compilerPure compilerBind are comment text.\n' +
      'def sh1OriginWords : String := "do compilerPure compilerBind"\n',
  };
  for (const kind of ['lean', 'ps']) {
    const library = input(libraries[kind], 'StrictLibrary');
    const entry = input('import Ps.Compiler.StrictLibrary\n' +
      (kind === 'lean' ? 'def sh1ReadDo (value : Sh1DoField) : Nat := value.do\n'
        : 'def sh1ReadDo(value : Sh1DoField) : Nat := value.do\n'), 'StrictEntry');
    const result = compileStrictSources(compiler, [library, entry], { compilerSha256, sourceKind: kind });
    assert.equal(result.evidence.sourcePolicy.importCount, 1);
    assert.equal(result.evidence.sourcePolicy.stats.declarationCount, 4);
    assert.equal(result.evidence.sourcePolicy.moduleCount, 2);
    accepted.push({ id: kind + '-raw-imports-and-ordinary-do-spellings', ...result.evidence });
  }
  const refused = [];
  for (const test of sourceCases()) {
    let failure;
    try {
      compileStrictSources(compiler, test.inputs, { compilerSha256, sourceKind: test.kind ?? 'lean',
        sourceOptions: strictSourceOptions(compiler, test.limits ?? {}) });
    } catch (error) {
      failure = error.strictFailure;
      if (!failure) throw error;
    }
    assert(failure, 'PSC0_SH1_SOURCE_REFUSAL_MISSING: ' + test.id);
    assert.equal(failure.code, test.code, 'PSC0_SH1_SOURCE_REFUSAL_CODE: ' + test.id);
    if (test.exactName) {
      const offset = test.inputs[0].source.indexOf(test.exactName);
      assert.equal(failure.owner, test.exactName);
      assert.equal(failure.span?.start?.byteOffset, offset);
      assert.equal(failure.span?.stop?.byteOffset, offset + test.exactName.length);
    }
    if (test.exactDoSpan) {
      const offset = test.inputs[0].source.indexOf('do return');
      assert.equal(failure.span?.start?.byteOffset, offset);
      assert.equal(failure.span?.stop?.byteOffset, offset + 2);
    }
    refused.push({ id: test.id, sourceKind: test.kind ?? 'lean',
      inputSha256: sha256(JSON.stringify(test.inputs)), limits: test.limits ?? {},
      ...(test.boundary ? { boundary: test.boundary } : {}), failure });
  }
  const badText = [String.fromCharCode(0xd800), String.fromCharCode(0xdc00)];
  const carrierRefusals = [];
  for (let index = 0; index < badText.length; index++) {
    assert.throws(() => compileStrictSources(compiler,
      [input('def sh1Text : String := "' + badText[index] + '"\n')], { compilerSha256 }),
    /PSC0_SH1_SOURCE_UNICODE/u);
    carrierRefusals.push({ id: index === 0 ? 'lone-high-surrogate' : 'lone-low-surrogate',
      boundary: 'host-source-carrier-before-portable-call', refused: true });
  }
  const receipt = {
    schemaVersion: 1, evidence: 'portable-source-boundary-conformance', compilerSha256,
    accepted, refused, carrierRefusals,
    sourcePolicyGenerations: 'This exact executing compiler only; full current closure has its separate generation receipt.',
    strictSh1Qualified: false, semanticContractQualified: false,
    provider: { status: 'not-attempted', kernelChecked: false },
  };
  await mkdir(outDir, { recursive: true });
  await writeFile(path.join(outDir, 'source-cases.json'), JSON.stringify(sourceCases(), null, 2) + '\n');
  await writeFile(path.join(outDir, 'receipt.json'), JSON.stringify(receipt, null, 2) + '\n');
  process.stdout.write('PSC0_SH1_STRICT_SOURCE: ' + JSON.stringify(receipt) + '\n');
  return receipt;
}
