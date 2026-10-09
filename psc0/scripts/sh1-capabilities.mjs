import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { spawnSync } from 'node:child_process';
import { expectedTypeScriptVersion, typeScriptProfileArgs } from './typescript-cli.mjs';
import { runProjectionResolutionConformance } from './sh1-projection-conformance.mjs';
import { runSh1GrammarConformance } from './sh1-grammar-conformance.mjs';
import { readProofScriptSource } from './proofscript-source.mjs';
import { runMigrationWorkerConformance } from './sh1-migration-worker-conformance.mjs';

export function sha256(value) {
  return createHash('sha256').update(value).digest('hex');
}

export function valueTag(value) {
  if (value === null || typeof value !== 'object') return undefined;
  for (const symbol of Object.getOwnPropertySymbols(value)) {
    const tag = value[symbol];
    if (typeof tag === 'string') return tag;
  }
  return undefined;
}

function diagnosticValue(value) {
  if (typeof value === 'bigint') return value.toString();
  if (Array.isArray(value)) return value.map(diagnosticValue);
  if (value !== null && typeof value === 'object') {
    const result = {};
    const tag = valueTag(value);
    if (tag !== undefined) result.tag = tag;
    for (const [key, item] of Object.entries(value)) result[key] = diagnosticValue(item);
    return result;
  }
  return value;
}

export function unwrap(value, stage) {
  const tag = valueTag(value);
  if (tag === 'ok') return value.value;
  if (tag === 'error') {
    throw new Error('PSC0_SH1_' + stage + ': ' + JSON.stringify(diagnosticValue(value.error)));
  }
  throw new Error('PSC0_SH1_' + stage + '_RESULT_SHAPE');
}

export function runCommand(command, args, options = {}) {
  const result = spawnSync(command, args, {
    stdio: 'inherit',
    timeout: 40 * 60 * 1000,
    ...options,
  });
  if (result.error) throw result.error;
  if (result.status !== 0) {
    throw new Error('PSC0_SH1_COMMAND_FAILED: ' + command + ' ' + args.join(' ') + '\n' +
      [result.stdout, result.stderr].filter((item) => typeof item === 'string').join('\n').slice(-32000));
  }
  return result;
}

export async function compileTypeScript(source, directory, tsc, cwd, version = expectedTypeScriptVersion()) {
  await mkdir(directory, { recursive: true });
  const input = path.join(directory, 'index.ts');
  await writeFile(input, source, 'utf8');
  runCommand(process.execPath, [tsc, ...typeScriptProfileArgs([
    input, '--target', 'ES2022', '--module', 'ES2022',
    '--moduleResolution', 'bundler', '--strict', '--declaration',
    '--sourceMap', '--noEmitOnError', '--skipLibCheck', '--pretty', 'false',
  ], version)], { cwd, timeout: 120000 });
  return path.join(directory, 'index.js');
}

function assertBehavior(runtime, label) {
  for (const fuel of [0n, 1n, 2n, 31n, 20000n]) {
    assert.equal(runtime.sh1OuterHypothesis(fuel, 0n), fuel, label + ': outer IH through unrelated zero match');
    assert.equal(runtime.sh1OuterHypothesis(fuel, 5n), fuel + 5n, label + ': outer IH through unrelated successor match');
    assert.equal(runtime.sh1NatAcc(fuel, 11n), 11n + 3n * fuel, label + ': Nat state');
    const expectedSwap = fuel % 2n === 0n ? 11n : 23n;
    assert.equal(runtime.sh1Swap(fuel, 11n, 23n), expectedSwap, label + ': simultaneous swap');
    assert.equal(runtime.sh1WorkerReference(fuel, 11n, 23n), expectedSwap, label + ': existing worker');
    assert.equal(runtime.sh1FunctionResult(fuel, 7n, 13n), 20n + 2n * fuel, label + ': function result');
    assert.equal(runtime.sh1WithProof(fuel, 17n), 17n + fuel, label + ': erased proof parameter');
  }
  assert.equal(runtime.sh1Shadow(37n, 0n), 37n, label + ': shadowed state base');
  assert.equal(runtime.sh1Shadow(37n, 5n), 1n, label + ': pattern binder identity');
  assert.equal(runtime.sh1Partial(9n), 21n, label + ': partial public application');
  for (const values of [[], [7n], [2n, 5n, 11n]]) {
    const input = values.reduceRight((tail, head) => runtime.List.cons(head, tail), runtime.List.nil());
    assert.equal(runtime.sh1StateBefore(19n, input), 19n + values.reduce((a, b) => a + b, 0n),
      label + ': state before major');
    let reversed = runtime.sh1ReverseInto(input, runtime.List.cons(29n, runtime.List.nil()));
    for (const expected of [...values].reverse().concat(29n)) {
      assert.equal(reversed.head, expected, label + ': generic reverse');
      reversed = reversed.tail;
    }
    assert.equal(valueTag(reversed), 'nil', label + ': preserved output suffix');
  }
  // A second erased type instantiation must share the ordinary public interface.
  const words = runtime.List.cons('first', runtime.List.cons('second', runtime.List.nil()));
  const reversedWords = runtime.sh1ReverseInto(words, runtime.List.nil());
  assert.equal(reversedWords.head, 'second', label + ': generic text value');
  assert.equal(reversedWords.tail.head, 'first', label + ': generic text tail');
}


function assertProjectionBehavior(runtime, label) {
  const state = runtime.sh1ProjectionStateValue(7n, 3n);
  const other = runtime.sh1ProjectionStateValue(29n, 5n);
  const box = runtime.sh1ProjectionBoxValue(state);
  let observations = 0;
  const equal = (actual, expected, purpose) => {
    assert.equal(actual, expected, label + ': ' + purpose);
    observations += 1;
  };
  for (const fuel of [0n, 1n, 2n, 31n, 20000n]) {
    const accumulated = 7n + 3n * fuel;
    equal(runtime.sh1ProjectionAcc(fuel, state), accumulated, 'changing record state');
    equal(runtime.sh1ProjectionFixed(state, fuel, 17n), 17n + accumulated, 'fixed record option');
    equal(runtime.sh1ProjectionNested(fuel, box, 17n), 17n + accumulated, 'nested field suffix');
    equal(runtime.sh1ProjectionBefore(state, fuel), accumulated, 'record state before major');
    equal(runtime.sh1ProjectionLambda(fuel, state), accumulated, 'lambda binder shadows record');
    equal(runtime.sh1ProjectionLet(fuel, state), accumulated, 'let initializer old scope and body new scope');
    equal(runtime.sh1ProjectionSwap(fuel, state, other), fuel % 2n === 0n ? 7n : 29n,
      'simultaneous record swap');
  }
  equal(runtime.sh1ProjectionPartial(state), 19n, 'public partial application');
  for (const values of [[], [state], [state, other]]) {
    const input = values.reduceRight((tail, head) => runtime.List.cons(head, tail), runtime.List.nil());
    const expected = values.length === 0 ? 7n : values.at(-1).count + values.at(-1).step;
    equal(runtime.sh1ProjectionPattern(input, state), expected, 'pattern binder shadows record');
  }
  return { observations, behavior: 'pass', maximumFuel: '20000' };
}

function assertGrammarBehavior(runtime, label) {
  let observations = 0;
  const equal = (actual, expected, purpose) => {
    assert.equal(actual, expected, label + ': ' + purpose);
    observations += 1;
  };
  equal(runtime.sh1GrammarConstant, 23n, 'annotated const');
  equal(runtime.sh1GrammarUnitCall, 19n, 'explicit Unit call');
  for (const value of [0n, 1n, 17n, 9007199254740993n]) {
    equal(runtime.sh1GrammarAdd(value, 2n), value + 2n, 'function comma header');
    equal(runtime.sh1GrammarIncrement(value), value + 1n, 'function-valued const');
    equal(runtime.sh1GrammarCallback(value), value + 3n, 'typed callback argument');
    equal(runtime.sh1GrammarGrouped(value), value + 5n, 'grouped lambda callee');
    equal(runtime.sh1GrammarChain(value), value + 7n, 'grouped repeated call');
    equal(runtime.sh1GrammarNative(value), value + 11n, 'native application continuation');
    equal(runtime.sh1GrammarRecord(value), value + 13n, 'record comma and trailing comma');
    equal(runtime.sh1GrammarNestedLet(value), value + 19n, 'nested let initializer boundary');
  }
  return { observations, behavior: 'pass', edition: 'ps-0.9-r3', mode: 'new-only' };
}

const negativeCases = [
  {
    name: 'narrowed-nested-induction-hypothesis',
    expected: 'structuralRecursionNotDecreasing',
    source: 'def sh1BadNarrow (fuel : Nat) (state : Nat) : Nat -> Nat :=\n' +
      '  match fuel with\n  | Nat.zero => fun (value : Nat) => value\n' +
      '  | Nat.succ remaining =>\n      match remaining with\n' +
      '      | Nat.zero => fun (value : Nat) => Nat.add state value\n' +
      '      | Nat.succ next =>\n' +
      '          let bad := sh1BadNarrow next (Nat.succ state);\n' +
      '          fun (value : Nat) => Nat.add bad value\n',
  },

  {
    name: 'unsaturated-recursive-call',
    expected: 'structuralRecursionArity',
    source: 'def sh1BadArity (fuel : Nat) (state : Nat) : Nat :=\n' +
      '  match fuel with\n  | Nat.zero => state\n' +
      '  | Nat.succ remaining => sh1BadArity remaining\n',
  },
  {
    name: 'nondecreasing-major',
    expected: 'structuralRecursionNotDecreasing',
    source: 'def sh1BadSame (fuel : Nat) (state : Nat) : Nat :=\n' +
      '  match fuel with\n  | Nat.zero => state\n' +
      '  | Nat.succ remaining => sh1BadSame fuel (Nat.succ state)\n',
  },
  {
    name: 'unrelated-constructor-child',
    expected: 'structuralRecursionNotDecreasing',
    source: 'def sh1BadOther (fuel : Nat) (other : Nat) (state : Nat) : Nat :=\n' +
      '  match fuel with\n  | Nat.zero => state\n' +
      '  | Nat.succ remaining =>\n      match other with\n' +
      '      | Nat.zero => state\n' +
      '      | Nat.succ outsider => sh1BadOther outsider other (Nat.succ state)\n',
  },
  {
    name: 'escaping-self-reference',
    expected: 'structuralRecursionEscapingReference',
    source: 'def sh1BadEscape (fuel : Nat) (state : Nat) : Nat :=\n' +
      '  match fuel with\n  | Nat.zero => state\n' +
      '  | Nat.succ remaining =>\n' +
      '      let self : Nat -> Nat -> Nat := sh1BadEscape;\n' +
      '      self remaining (Nat.succ state)\n',
  },
  {
    name: 'major-dependent-parameter',
    expected: 'structuralRecursionDependentParameter',
    source: 'def sh1BadDependent (family : Nat -> Type) (fuel : Nat) (value : family fuel) (state : Nat) : Nat :=\n' +
      '  match fuel with\n  | Nat.zero => 0\n' +
      '  | Nat.succ remaining => sh1BadDependent family remaining value (Nat.succ state)\n',
  },
];

function diagnosticTags(value) {
  const tags = [];
  const visit = (item) => {
    if (item === null || typeof item !== 'object') return;
    const tag = valueTag(item);
    if (tag !== undefined) tags.push(tag);
    for (const child of Object.values(item)) visit(child);
  };
  visit(value);
  return tags;
}

export async function runSh1Capabilities({
  compiler, compilerSha256, root, outDir, tsc, nativeCompiler,
}) {
  const projectionResolution = runProjectionResolutionConformance(compiler, valueTag);
  const grammar = runSh1GrammarConformance({ compiler, compilerSha256 });
  const workerMigration = runMigrationWorkerConformance(compiler, valueTag);
  const results = [];
  for (const extension of ['lean', 'ps']) {
    const fixture = path.join(root, 'test/fixtures/selfhost-sh1-accumulators.' + extension);
    const source = extension === 'ps'
      ? await readProofScriptSource(fixture) : await readFile(fixture, 'utf8');
    const kind = extension === 'lean'
      ? compiler.PsCompilerSourceKind.lean : compiler.PsCompilerSourceKind.proofScript;
    const prepared = unwrap(compiler.psCompilerPrepareSource(kind, source), 'CAPABILITY_PREPARE_' + extension);
    const admissions = unwrap(compiler.psCompilerAdmissionsFromPrepared(prepared), 'CAPABILITY_ADMISSIONS');
    const generatedTs = unwrap(compiler.psCompilerTypeScriptFromPrepared(prepared), 'CAPABILITY_EMIT');
    const generatedJs = await compileTypeScript(generatedTs, path.join(outDir, extension, 'generated'), tsc, root);
    const runtime = await import(pathToFileURL(generatedJs).href);
    assertBehavior(runtime, 'generated ' + extension);
    const projectionBehavior = assertProjectionBehavior(runtime, 'generated ' + extension);
    const grammarBehavior = assertGrammarBehavior(runtime, 'generated ' + extension);
    const result = {
      sourceKind: extension,
      sourceSha256: sha256(source),
      admissionsSha256: sha256(admissions),
      typescriptSha256: sha256(generatedTs),
      javascriptSha256: sha256(await readFile(generatedJs)),
      generatedCompilerConsumedRawSource: true,
      behavior: 'pass',
      projectionBehavior,
      grammarBehavior,
    };
    if (nativeCompiler) {
      const native = runCommand(nativeCompiler, ['typescript', fixture], {
        cwd: root, encoding: 'utf8', stdio: 'pipe', timeout: 120000,
        maxBuffer: 16 * 1024 * 1024,
      });
      const nativeJs = await compileTypeScript(native.stdout,
        path.join(outDir, extension, 'native'), tsc, root);
      const nativeRuntime = await import(pathToFileURL(nativeJs).href);
      assertBehavior(nativeRuntime, 'native PSC ' + extension);
      result.nativeProjectionBehavior = assertProjectionBehavior(nativeRuntime, 'native PSC ' + extension);
      result.nativeGrammarBehavior = assertGrammarBehavior(nativeRuntime, 'native PSC ' + extension);
      result.nativePscBehavior = 'pass';
      result.nativeTypeScriptSha256 = sha256(native.stdout);
    }
    await writeFile(path.join(outDir, extension, 'admissions.json'), admissions);
    results.push(result);
  }
  const rejected = [];
  for (const test of negativeCases) {
    const result = compiler.psCompilerPrepareSource(compiler.PsCompilerSourceKind.lean, test.source);
    assert.equal(valueTag(result), 'error', 'PSC0_SH1_NEGATIVE_ACCEPTED: ' + test.name);
    const tags = diagnosticTags(result.error);
    assert(tags.includes(test.expected), 'PSC0_SH1_NEGATIVE_DIAGNOSTIC: ' + test.name +
      '; expected ' + test.expected + ', got ' + JSON.stringify(diagnosticValue(result.error)));
    rejected.push({ name: test.name, sourceSha256: sha256(test.source), diagnosticTags: tags });
  }
  const stableSource =
    'inductive ListInv (alpha : Type) where | nil | cons (head : alpha) (tail : ListInv alpha)\n' +
    'def badInv (base : Nat) (xs : ListInv Nat) : Nat := ' +
    'match xs with | ListInv.nil => base | ListInv.cons head tail => badInv head tail\n';
  const stableParsed = unwrap(compiler.psCompilerParseSource(
    compiler.PsCompilerSourceKind.lean, stableSource), 'STABLE_PARSE');
  const stablePrelude = compiler.psSelfHostProdPreludeEnvironment;
  const stableInductive = unwrap(compiler.psElabDeclarationBatchStable(
    stablePrelude, stableParsed.declarations.head), 'STABLE_INDUCTIVE');
  const stableEnvironment = unwrap(compiler.psAddDeclarationList(
    stablePrelude, stableInductive.declarations), 'STABLE_ENVIRONMENT');
  const stableResult = compiler.psElabDeclarationBatchStable(
    stableEnvironment, stableParsed.declarations.tail.head);
  assert.equal(valueTag(stableResult), 'error', 'PSC0_SH1_STABLE_MODE_ACCEPTED_CHANGED_STATE');
  assert.equal(valueTag(stableResult.error), 'structuralRecursionInvariantArgument');
  rejected.push({
    name: 'explicit-historical-stable-mode',
    sourceSha256: sha256(stableSource),
    diagnosticTags: diagnosticTags(stableResult.error),
  });
  const receipt = {
    schemaVersion: 1,
    compilerSha256,
    evidence: 'raw-source-generated-execution',
    sourceKinds: results,
    negativeCases: rejected,
    projectionResolution,
    grammar,
    workerMigration,
    independentExpectedBehavior: [
      'Nat accumulation', 'simultaneous state swapping', 'state before structural major',
      'function results', 'erased stable proof binder', 'generic List at Nat and String',
      'public partial application', 'existing worker correspondence',
      'record projections through changing, fixed, shadowed, and nested local bases',
      'new-only grammar aliases, typed callbacks, grouped callees, layout, records, and explicit Unit',
    ],
    provider: { status: 'not-attempted', kernelChecked: false },
  };
  await mkdir(outDir, { recursive: true });
  await writeFile(path.join(outDir, 'receipt.json'), JSON.stringify(receipt, null, 2) + '\n');
  process.stdout.write('PSC0_SH1_CAPABILITIES: ' + JSON.stringify(receipt) + '\n');
  return receipt;
}
