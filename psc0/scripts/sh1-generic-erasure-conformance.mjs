import assert from 'node:assert/strict';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { compileTypeScript, runCommand, sha256, unwrap, valueTag } from './sh1-capabilities.mjs';

const cases = [
  { name: 'sh1GenericCopy', types: ['T0'], parameters: ['values'] },
  { name: 'sh1GenericMap', types: ['T0', 'T1'], parameters: ['convert', 'values'] },
  { name: 'sh1GenericTriple', types: ['T0', 'T1', 'T2'], parameters: ['first', 'second', 'third', 'fuel'] },
  { name: 'sh1GenericMono', types: [], parameters: ['fuel', 'value'] },
];

function list(value, label) {
  const result = [];
  while (valueTag(value) === 'cons') {
    assert(result.length < 1024, 'PSC0_SH1_GENERIC_LIST_BOUND: ' + label);
    result.push(value.head);
    value = value.tail;
  }
  assert.equal(valueTag(value), 'nil', 'PSC0_SH1_GENERIC_LIST_SHAPE: ' + label);
  return result;
}

function recursiveCalls(body, owner) {
  const result = [];
  const pending = [{ value: body, at: 'declaration:' + owner + '/body' }];
  const seen = new Set();
  while (pending.length) {
    const { value, at } = pending.pop();
    if (value === null || typeof value !== 'object' || seen.has(value)) continue;
    seen.add(value);
    assert(seen.size <= 10000, 'PSC0_SH1_GENERIC_IR_BOUND: ' + owner);
    if (valueTag(value) === 'call' && valueTag(value.fn) === 'var' && value.fn.name === owner) {
      result.push({ expression: value, at });
    }
    for (const [key, child] of Object.entries(value)) {
      pending.push({ value: child, at: at + '/' + key });
    }
  }
  return result;
}

// Expectations come from each fixture's declared telescope, independently of
// the context record used by the implementation. Preserve the observed IR paths.
function checkOriginalIr(ir) {
  const declarations = new Map(list(ir.declarations, 'declarations').map((item) => [item.name, item]));
  return cases.map((expected) => {
    const declaration = declarations.get(expected.name);
    assert(declaration, 'PSC0_SH1_GENERIC_DECLARATION_MISSING: ' + expected.name);
    assert.deepEqual(list(declaration.typeParameters, expected.name).map((item) => item.name),
      expected.types, 'PSC0_SH1_GENERIC_DECLARATION_TYPES: ' + expected.name);
    assert.deepEqual(list(declaration.parameters, expected.name).map((item) => item.name),
      expected.parameters, 'PSC0_SH1_GENERIC_RUNTIME_PARAMETERS: ' + expected.name);
    const calls = recursiveCalls(declaration.body, expected.name);
    assert.equal(calls.length, 1, 'PSC0_SH1_GENERIC_RECURSIVE_CALL_COUNT: ' + expected.name);
    return {
      declaration: expected.name,
      declarationTypeParameters: expected.types,
      runtimeParameters: expected.parameters,
      calls: calls.map(({ expression, at }) => {
        const arguments_ = list(expression.typeArguments, at);
        const names = arguments_.map((argument) => {
          assert.equal(valueTag(argument), 'typeParameter', 'PSC0_SH1_GENERIC_ARGUMENT_FORM: ' + at);
          return argument.name;
        });
        assert.deepEqual(names, expected.types, 'PSC0_SH1_GENERIC_ARGUMENT_ORDER: ' + at);
        const runtimeArity = list(expression.arguments, at).length;
        assert.equal(runtimeArity, expected.parameters.length, 'PSC0_SH1_GENERIC_RUNTIME_ARITY: ' + at);
        return { at, typeArguments: names, runtimeArity };
      }),
    };
  });
}

function checkBehavior(runtime, label) {
  const from = (values) => values.reduceRight((tail, head) => runtime.List.cons(head, tail), runtime.List.nil());
  let observations = 0;
  for (const values of [[], [7n], [2n, 5n, 11n], ['first', 'second']]) {
    assert.deepEqual(list(runtime.sh1GenericCopy(from(values)), label), values);
    observations++;
  }
  for (const values of [[], [7n], [2n, 5n, 11n]]) {
    const convert = (value) => 'n=' + value.toString();
    assert.deepEqual(list(runtime.sh1GenericMap(convert, from(values)), label), values.map(convert));
    observations++;
  }
  for (const fuel of [0n, 1n, 7n, 31n]) {
    for (const [first, second, third] of [[7n, 'word', true], ['left', 19n, false]]) {
      const actual = runtime.sh1GenericTriple(first, second, third, fuel);
      assert.deepEqual([actual.fst, actual.snd.fst, actual.snd.snd], [first, second, third],
        label + ': erased proof and interleaved type/runtime binders');
      observations++;
    }
    assert.equal(runtime.sh1GenericMono(fuel, 53n), 53n, label + ': monomorphic recursion');
    observations++;
  }
  return { observations, status: 'pass', exhaustiveForAllInputs: false };
}

export async function runGenericErasureConformance({
  compiler, compilerSha256, root, outDir, tsc, nativeCompiler,
}) {
  const fixture = path.join(root, 'test/fixtures/selfhost-sh1-generic-erasure.lean');
  const source = await readFile(fixture, 'utf8');
  const prepared = unwrap(compiler.psCompilerPrepareSource(compiler.PsCompilerSourceKind.lean, source),
    'GENERIC_ERASURE_PREPARE');
  const ir = unwrap(compiler.psCompilerVerifiedIrFromPrepared(prepared), 'GENERIC_ERASURE_ORIGINAL_IR');
  const observations = checkOriginalIr(ir);
  const admissions = unwrap(compiler.psCompilerAdmissionsFromPrepared(prepared), 'GENERIC_ERASURE_ADMISSIONS');
  const typeScript = unwrap(compiler.psTsEmitModule(ir), 'GENERIC_ERASURE_EMIT');
  const outputJs = await compileTypeScript(typeScript, path.join(outDir, 'generated'), tsc, root);
  const behavior = checkBehavior(await import(pathToFileURL(outputJs).href), 'generated PSC');
  const receipt = {
    schemaVersion: 1,
    evidence: 'scoped-recursive-generic-erasure',
    compilerSha256,
    sourceKind: 'raw-authoritative-lean',
    sourceSha256: sha256(source),
    originalIr: {
      checks: [
        'one, two, and three declaration generics in exact declaration order',
        'interleaved type, erased proposition/proof, and runtime binders',
        'recursive calls retain the complete runtime argument count',
        'monomorphic recursive calls retain zero type arguments',
      ],
      observations,
      emittedIr: 'The exact original IR inspected above is passed to psTsEmitModule.',
      strictSh1Qualified: false,
    },
    artifacts: {
      admissionsSha256: sha256(admissions),
      typescriptSha256: sha256(typeScript),
      javascriptSha256: sha256(await readFile(outputJs)),
    },
    behavior,
    provider: { status: 'not-attempted', kernelChecked: false },
  };
  if (nativeCompiler) {
    const native = runCommand(nativeCompiler, ['typescript', fixture], {
      cwd: root, encoding: 'utf8', stdio: 'pipe', timeout: 120000,
      maxBuffer: 16 * 1024 * 1024,
    });
    assert.equal(native.stdout, typeScript, 'PSC0_SH1_GENERIC_NATIVE_TYPESCRIPT_PARITY');
    const nativeJs = await compileTypeScript(native.stdout, path.join(outDir, 'native'), tsc, root);
    receipt.native = {
      typescriptSha256: sha256(native.stdout),
      behavior: checkBehavior(await import(pathToFileURL(nativeJs).href), 'native PSC'),
    };
  }
  await mkdir(outDir, { recursive: true });
  await writeFile(path.join(outDir, 'admissions.json'), admissions);
  await writeFile(path.join(outDir, 'receipt.json'), JSON.stringify(receipt, null, 2) + '\n');
  process.stdout.write('PSC0_SH1_GENERIC_ERASURE: ' + JSON.stringify(receipt) + '\n');
  return receipt;
}
