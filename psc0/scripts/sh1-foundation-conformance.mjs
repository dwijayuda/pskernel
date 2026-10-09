import assert from 'node:assert/strict';
import { invokeCompilerValueEntry } from './sh1-function-entry.mjs';
import { createHash } from 'node:crypto';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { compileTypeScript, sha256, unwrap, valueTag } from './sh1-capabilities.mjs';

const publicNames = [
  'psListLength', 'psListIsEmpty', 'psListAny', 'psListReverseAcc', 'psListReverse',
  'psListAppend', 'psListMap', 'psListMapExcept', 'psListTake', 'psListZip',
];
const referenceBlob = 'faf906bd6e2f872887c87eb43c4ad90957da91fc';

function arrayFromList(value) {
  const result = [];
  while (valueTag(value) === 'cons') {
    assert(result.length < 10000, 'PSC0_SH1_LIBRARY_RESULT_BOUND');
    result.push(value.head);
    value = value.tail;
  }
  assert.equal(valueTag(value), 'nil', 'PSC0_SH1_LIBRARY_LIST_SHAPE');
  return result;
}

function listFromArray(runtime, values) {
  return values.reduceRight((tail, head) => runtime.List.cons(head, tail), runtime.List.nil());
}

function publicType(compiler, prepared, name) {
  let declarations = prepared.declarations;
  const target = compiler.psRootName(name);
  while (valueTag(declarations) === 'cons') {
    const declaration = declarations.head;
    if (invokeCompilerValueEntry(compiler, 'psNameEq', [compiler.psDeclarationName(declaration), target])) {
      return compiler.psDeclarationType(declaration);
    }
    declarations = declarations.tail;
  }
  throw new Error('PSC0_SH1_PUBLIC_DECLARATION_MISSING: ' + name);
}

function boundedLists() {
  const lists = [[]];
  let layer = [[]];
  for (let length = 1; length <= 3; length++) {
    layer = layer.flatMap((prefix) => [prefix.concat(0n), prefix.concat(1n)]);
    lists.push(...layer);
  }
  return lists;
}

function checkLibrary(runtime, sourceLabel) {
  assert(['reference', 'current'].includes(sourceLabel), 'PSC0_SH1_LIBRARY_SOURCE_LABEL');
  // The immutable reference definitions return a closure after their first
  // structural argument. The migrated definitions put both values in headers.
  const returnedClosure = sourceLabel === 'reference';
  for (const name of ['psListReverseAcc', 'psListAppend', 'psListTake', 'psListZip']) {
    assert.equal(runtime[name].length, returnedClosure ? 1 : 2,
      'PSC0_SH1_LIBRARY_SOURCE_ENTRY_ARITY: ' + name);
  }
  const reverseAcc = returnedClosure ? (values, acc) => runtime.psListReverseAcc(values)(acc) :
    runtime.psListReverseAcc;
  const append = returnedClosure ? (left, right) => runtime.psListAppend(left)(right) :
    runtime.psListAppend;
  const take = returnedClosure ? (count, values) => runtime.psListTake(count)(values) :
    runtime.psListTake;
  const zip = returnedClosure ? (left, right) => runtime.psListZip(left)(right) :
    runtime.psListZip;
  const lists = boundedLists();
  let observations = 0;
  for (const left of lists) {
    const a = listFromArray(runtime, left);
    assert.equal(runtime.psListLength(a), BigInt(left.length));
    assert.equal(runtime.psListIsEmpty(a), left.length === 0);
    assert.deepEqual(arrayFromList(runtime.psListReverse(a)), [...left].reverse());
    observations += 3;
    for (let count = 0; count <= 8; count++) {
      const expected = left.slice(0, count);
      assert.deepEqual(arrayFromList(take(BigInt(count), a)), expected);
      assert.deepEqual(arrayFromList(runtime.sh1TakeCurried(BigInt(count), a)), expected);
      observations += 2;
    }
    for (const right of lists) {
      const b = listFromArray(runtime, right);
      assert.deepEqual(arrayFromList(reverseAcc(a, b)), [...left].reverse().concat(right));
      assert.deepEqual(arrayFromList(runtime.sh1ReverseCurried(a, b)), [...left].reverse().concat(right));
      assert.deepEqual(arrayFromList(append(a, b)), left.concat(right));
      assert.deepEqual(arrayFromList(runtime.sh1AppendCurried(a, b)), left.concat(right));
      const expectedPairs = left.slice(0, right.length).map((item, index) => [item, right[index]]);
      for (const pairs of [zip(a, b), runtime.sh1ZipCurried(a, b)]) {
        assert.deepEqual(arrayFromList(pairs).map((pair) => [pair.fst, pair.snd]), expectedPairs);
      }
      observations += 6;
    }
  }
  const words = listFromArray(runtime, ['first', 'second']);
  assert.deepEqual(arrayFromList(runtime.sh1ZipText(listFromArray(runtime, [7n, 9n, 11n]), words))
    .map((pair) => [pair.fst, pair.snd]), [[7n, 'first'], [9n, 'second']]);
  return { lists: lists.length, maxLength: 3, elementValues: ['0', '1'], counts: [0, 8], observations: observations + 1 };
}

export async function runFoundationConformance({
  compiler, compilerSha256, executingCompiler, root, outDir, tsc,
}) {
  const reference = await readFile(path.join(root, 'test/fixtures/selfhost-sh1-foundation-reference.lean'), 'utf8');
  const referenceBytes = Buffer.from(reference);
  assert.equal(createHash('sha1').update('blob ' + referenceBytes.length + '\0')
    .update(referenceBytes).digest('hex'), referenceBlob, 'PSC0_SH1_LIBRARY_REFERENCE_IDENTITY');
  const current = await readFile(path.join(root, 'packages/foundation/src/Ps/Foundation/List.lean'), 'utf8');
  if (current === reference) {
    const receipt = {
      schemaVersion: 1, status: 'unchanged-library-source', compilerSha256,
      sourceSha256: sha256(current), referenceGitBlob: referenceBlob,
      behaviorComparison: 'not-run: current and preserved library source bytes are identical',
    };
    await mkdir(outDir, { recursive: true });
    await writeFile(path.join(outDir, 'receipt.json'), JSON.stringify(receipt, null, 2) + '\n');
    return receipt;
  }
  const probe = await readFile(path.join(root, 'test/fixtures/selfhost-sh1-foundation-probe.lean'), 'utf8');
  const outputs = [];
  let referencePrepared;
  for (const [label, source] of [['reference', reference], ['current', current]]) {
    const sources = compiler.List.cons(source, compiler.List.cons(probe, compiler.List.nil()));
    const prepared = unwrap(compiler.psCompilerPrepareSources(compiler.PsCompilerSourceKind.lean, sources),
      'FOUNDATION_PREPARE_' + label);
    if (label === 'reference') referencePrepared = prepared;
    else {
      for (const name of publicNames) {
        assert.equal(invokeCompilerValueEntry(compiler, 'psExprAlphaEq', [
          publicType(compiler, referencePrepared, name),
          publicType(compiler, prepared, name)]), true, 'PSC0_SH1_PUBLIC_TYPE_CHANGED: ' + name);
      }
    }
    const admissions = unwrap(compiler.psCompilerAdmissionsFromPrepared(prepared), 'FOUNDATION_ADMISSIONS');
    const typeScript = unwrap(compiler.psCompilerTypeScriptFromPrepared(prepared), 'FOUNDATION_EMIT');
    const outputJs = await compileTypeScript(typeScript, path.join(outDir, label), tsc, root);
    const coverage = checkLibrary(await import(pathToFileURL(outputJs).href), label);
    outputs.push({
      source: label, sourceSha256: sha256(source),
      admissionsSha256: sha256(admissions),
      typescriptSha256: sha256(typeScript),
      javascriptSha256: sha256(await readFile(outputJs)),
      coverage,
    });
    await writeFile(path.join(outDir, label, 'admissions.json'), admissions);
  }
  const receipt = {
    schemaVersion: 1,
    evidence: 'bounded-foundation-source-correspondence',
    compilerSha256,
    executingCompiler,
    referenceSourceRef: '37f63c39d4a07189938046c64152bba25d789450',
    referenceGitBlob: referenceBlob,
    authoredProbeSha256: sha256(probe),
    publicTypes: { comparison: 'psExprAlphaEq including binder kinds and parameter order', names: publicNames, result: 'pass' },
    behavior: 'independent JS sequence expectations plus typed PSC partial-application probes',
    outputs,
    kernelChecked: false,
    exhaustiveForAllInputs: false,
  };
  await mkdir(outDir, { recursive: true });
  await writeFile(path.join(outDir, 'receipt.json'), JSON.stringify(receipt, null, 2) + '\n');
  process.stdout.write('PSC0_SH1_FOUNDATION_CONFORMANCE: ' + JSON.stringify(receipt) + '\n');
  return receipt;
}
