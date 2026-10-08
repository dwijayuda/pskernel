import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { stripBootstrapImports } from './sh1-source-snapshot.mjs';
import { compileTypeScript, sha256, unwrap, valueTag } from './sh1-capabilities.mjs';

const referenceRef = '5e3338bf0f389d3704b49958debe496625593197';
const referenceBlob = '8b00617b9798b65696f03b3613b90888c97a07ba';
const publicNames = [
  'psExprApplyManyWorker', 'psExprApplyMany',
  'psExprAppViewAccWorker', 'psExprAppViewAcc', 'psExprAppView',
  'psErasureAddUniqueStringWorker', 'psErasureAddUniqueString',
];
const sourceFiles = [
  {
    path: 'packages/elab/src/Ps/Elab/Term.lean',
    referenceGitBlob: '6a2282248cbb01301e8eb1dad1476f1773b4e63a',
    spans: [
      ['def psExprApplyManyWorker\n', 'def psElabIf\n'],
      ['structure PsExprAppView where\n', 'def psExprHasConst\n'],
    ],
  },
  {
    path: 'packages/erasure/src/Ps/Erasure/Definition.lean',
    referenceGitBlob: '77f63f76daf5fd0c569545df8835fb94b6d554c9',
    spans: [['def psErasureStringInList ', 'structure PsErasureNameState where\n']],
  },
];
const dependencyFiles = [
  'packages/foundation/src/Ps/Foundation/Name.lean',
  'packages/core/src/Ps/Core/Level.lean',
  'packages/core/src/Ps/Core/Expr.lean',
];

function list(runtime, values) {
  return values.reduceRight((tail, head) => runtime.List.cons(head, tail), runtime.List.nil());
}

function array(value) {
  const result = [];
  while (valueTag(value) === 'cons') {
    assert(result.length < 1000, 'PSC0_SH1_HELPER_LIST_BOUND');
    result.push(value.head);
    value = value.tail;
  }
  assert.equal(valueTag(value), 'nil', 'PSC0_SH1_HELPER_LIST_SHAPE');
  return result;
}

// Strip module-local constructor symbols when comparing immutable data.
// No tagged value crosses generated-module instances.
function data(value) {
  if (value === null || typeof value !== 'object') return value;
  return [valueTag(value), ...Object.keys(value).sort().map((key) => [key, data(value[key])])];
}

function publicType(compiler, prepared, name) {
  const target = compiler.psRootName(name);
  for (const declaration of array(prepared.declarations)) {
    if (compiler.psNameEq(compiler.psDeclarationName(declaration), target)) {
      return compiler.psDeclarationType(declaration);
    }
  }
  throw new Error('PSC0_SH1_HELPER_PUBLIC_DECLARATION_MISSING: ' + name);
}

function sourceSpan(source, start, end) {
  const first = source.indexOf(start);
  const last = source.indexOf(end, first + start.length);
  assert(first >= 0 && last > first && source.indexOf(start, first + start.length) === -1,
    'PSC0_SH1_HELPER_SOURCE_BOUNDARY: ' + start);
  return source.slice(first, last).trim() + '\n';
}

function checkHelpers(runtime, withProbes) {
  for (const name of publicNames) assert.equal(typeof runtime[name], 'function', name);
  const e = runtime.PsExpr;
  const anonymous = runtime.PsName.anonymous;
  const named = runtime.PsName.str(anonymous, 'Head');
  const a = e.fvar(11n), b = e.fvar(23n);
  const nested = e.app(e.fvar(31n), e.bvar(0n));
  const heads = [
    e.bvar(0n), e.fvar(1n), e.mvar(2n), e.sortE(runtime.PsLevel.zero),
    e.constE(named, list(runtime, [])),
    e.lam(anonymous, a, nested, runtime.PsBinderInfo.explicit),
    e.forallE(anonymous, b, nested, runtime.PsBinderInfo.implicit),
    e.letE(anonymous, a, nested, b),
    e.lit(runtime.PsLiteral.natural(17n)),
    e.lit(runtime.PsLiteral.string('é_猫')),
    e.proj(named, 1n, nested),
  ];
  const argumentLists = [[], [a], [b], [a, b], [b, a], [a, a], [a, b, nested]];
  const prefixes = [[], [nested]];
  const suffixes = [[], [b, a]];
  const apply = (head, arguments_) => arguments_.reduce((fn, arg) => e.app(fn, arg), head);
  let expressionObservations = 0;
  function assertView(view, head, arguments_) {
    assert.deepEqual(data(view.head), data(head), 'PSC0_SH1_HELPER_VIEW_HEAD');
    assert.deepEqual(array(view.args).map(data), arguments_.map(data),
      'PSC0_SH1_HELPER_VIEW_ARGUMENTS');
    expressionObservations++;
  }
  for (const head of heads) {
    for (const prefix of prefixes) {
      const initial = apply(head, prefix);
      for (const arguments_ of argumentLists) {
        const args = list(runtime, arguments_);
        const expected = apply(head, prefix.concat(arguments_));
        const applied = [
          runtime.psExprApplyMany(initial, args),
          runtime.psExprApplyManyWorker(args, initial),
        ];
        if (withProbes) applied.push(runtime.sh1ApplyManyCurried(args, initial));
        for (const result of applied) {
          assert.deepEqual(data(result), data(expected), 'PSC0_SH1_HELPER_APPLY_ORDER');
          expressionObservations++;
        }
        const view = runtime.psExprAppView(expected);
        assertView(view, head, prefix.concat(arguments_));
        assert.deepEqual(data(runtime.psExprApplyMany(view.head, view.args)), data(expected),
          'PSC0_SH1_HELPER_VIEW_ROUND_TRIP');
        expressionObservations++;
        for (const suffix of suffixes) {
          const values = list(runtime, suffix);
          const views = [
            runtime.psExprAppViewAcc(expected, values),
            runtime.psExprAppViewAccWorker(expected, values),
          ];
          if (withProbes) views.push(runtime.sh1AppViewAccCurried(expected, values));
          for (const output of views) assertView(output, head, prefix.concat(arguments_, suffix));
        }
      }
    }
  }
  let stringObservations = 0;
  for (const base of ['x', '', 'é_猫']) {
    const usedLists = [
      [], [base], [base, base], [base, base + '_'], [base + '_'],
      [base + '_', base, base + '__'],
      [base, base + '_', base + '__', base + '___'],
    ];
    for (const used of usedLists) {
      for (let attempts = 0; attempts <= 7; attempts++) {
        // The allowed candidates are a finite sequence. Exhaustion preserves
        // the original suffix even when the next name would otherwise be free.
        const candidates = Array.from({ length: attempts },
          (_, index) => base + '_'.repeat(index));
        const expected = candidates.find((candidate) => !used.includes(candidate))
          ?? base + '_'.repeat(attempts) + '_overflow';
        const values = list(runtime, used);
        const outputs = [
          runtime.psErasureAddUniqueString(values, base, BigInt(attempts)),
          runtime.psErasureAddUniqueStringWorker(values, BigInt(attempts), base),
        ];
        if (withProbes) outputs.push(runtime.sh1UniqueStringCurried(values, BigInt(attempts), base));
        for (const output of outputs) {
          assert.equal(output, expected, 'PSC0_SH1_HELPER_NAME_EXHAUSTION');
          stringObservations++;
        }
      }
    }
  }
  return {
    nonApplicationHeads: heads.length, argumentLists: argumentLists.length,
    prefixes: prefixes.length, suffixes: suffixes.length,
    nameBases: 3, usedNameListsPerBase: 7, attempts: [0, 7],
    typedPartialApplications: withProbes,
    expressionObservations, stringObservations,
    observations: expressionObservations + stringObservations,
  };
}

export async function runHelperRuntimeConformance({ compiler, compilerSha256, outDir }) {
  const receipt = {
    schemaVersion: 1, evidence: 'generated-compiler-exported-helper-behavior',
    compilerSha256, coverage: checkHelpers(compiler, false),
    behavior: 'independent application-spine and finite unique-name expectations',
    kernelChecked: false, exhaustiveForAllInputs: false,
  };
  await mkdir(outDir, { recursive: true });
  await writeFile(path.join(outDir, 'helper-runtime.json'), JSON.stringify(receipt, null, 2) + '\n');
  process.stdout.write('PSC0_SH1_HELPER_RUNTIME: ' + JSON.stringify(receipt) + '\n');
  return receipt;
}

export async function runHelperConformance({
  compiler, compilerSha256, executingCompiler, root, outDir, tsc,
}) {
  const reference = await readFile(path.join(root, 'test/fixtures/selfhost-sh1-helpers-reference.lean'), 'utf8');
  const bytes = Buffer.from(reference);
  assert.equal(createHash('sha1').update('blob ' + bytes.length + '\0').update(bytes).digest('hex'),
    referenceBlob, 'PSC0_SH1_HELPER_REFERENCE_IDENTITY');
  const probe = await readFile(path.join(root, 'test/fixtures/selfhost-sh1-helpers-probe.lean'), 'utf8');
  const dependencies = [];
  const dependencySources = [];
  for (const file of dependencyFiles) {
    const source = await readFile(path.join(root, file), 'utf8');
    dependencies.push({ path: file, sha256: sha256(source) });
    dependencySources.push(stripBootstrapImports(source));
  }
  const currentSpans = [];
  const currentSourceFiles = [];
  for (const file of sourceFiles) {
    const source = await readFile(path.join(root, file.path), 'utf8');
    currentSourceFiles.push({
      path: file.path, sha256: sha256(source), referenceGitBlob: file.referenceGitBlob,
    });
    for (const [start, end] of file.spans) currentSpans.push(sourceSpan(source, start, end));
  }
  const current = currentSpans.join('\n');
  const outputs = [];
  let referencePrepared;
  for (const [label, source] of [['reference', reference], ['current', current]]) {
    const sources = dependencySources.concat(source, probe);
    const prepared = unwrap(compiler.psCompilerPrepareSources(
      compiler.PsCompilerSourceKind.lean, list(compiler, sources)), 'HELPER_PREPARE_' + label);
    if (label === 'reference') referencePrepared = prepared;
    else for (const name of publicNames) {
      assert.equal(compiler.psExprAlphaEq(publicType(compiler, referencePrepared, name),
        publicType(compiler, prepared, name)), true, 'PSC0_SH1_HELPER_PUBLIC_TYPE_CHANGED: ' + name);
    }
    const admissions = unwrap(compiler.psCompilerAdmissionsFromPrepared(prepared), 'HELPER_ADMISSIONS');
    const typeScript = unwrap(compiler.psCompilerTypeScriptFromPrepared(prepared), 'HELPER_EMIT');
    const outputJs = await compileTypeScript(typeScript, path.join(outDir, label), tsc, root);
    const coverage = checkHelpers(await import(pathToFileURL(outputJs).href), true);
    outputs.push({
      source: label, sourceSha256: sha256(source), coverage,
      admissionsSha256: sha256(admissions), typescriptSha256: sha256(typeScript),
      javascriptSha256: sha256(await readFile(outputJs)),
    });
    await writeFile(path.join(outDir, label, 'source.lean'), sources.join('\n\n'));
    await writeFile(path.join(outDir, label, 'admissions.json'), admissions);
  }
  const receipt = {
    schemaVersion: 1, evidence: 'bounded-compiler-helper-source-correspondence',
    compilerSha256, executingCompiler, referenceSourceRef: referenceRef,
    referenceGitBlob: referenceBlob, currentSourceFiles, dependencies,
    authoredProbeSha256: sha256(probe),
    publicTypes: {
      comparison: 'psExprAlphaEq including binder kinds and parameter order',
      names: publicNames, result: 'pass',
    },
    behavior: 'independent JS application-spine and finite name-candidate expectations; typed PSC partial application',
    sourceScope: 'Exact helper declarations and real shared Name/Level/Expr modules; full compiler integration is qualified separately.',
    outputs, kernelChecked: false, exhaustiveForAllInputs: false,
  };
  await mkdir(outDir, { recursive: true });
  await writeFile(path.join(outDir, 'receipt.json'), JSON.stringify(receipt, null, 2) + '\n');
  process.stdout.write('PSC0_SH1_HELPER_CONFORMANCE: ' + JSON.stringify(receipt) + '\n');
  return receipt;
}
