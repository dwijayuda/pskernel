// Retain the existing authored corpus, native Lean oracles and sealed inputs.
// Native frontends are used here only; execution is a separate job and process.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { suites, root, read, write, run, sha, capturedSources } from './modular-corpus-common.mjs';
import {
  compilerSourceClosureDigest,
  runIndependentChecker,
} from '../host-tools/compiler-host-protocol.mjs';
import {
  createLosslessSourceTool,
  createSourceOwnershipTool,
  createCheckedSourceConverter,
} from '../host-tools/source-refactoring.mjs';

fs.mkdirSync(root, { recursive: true });
const reference = [];
for (const [suite, prefix] of suites) {
  const result = spawnSync(
    process.execPath,
    ['scripts/compiler-m-conformance-tests.mjs', '--' + suite],
    {
      env: {
        ...process.env,
        [prefix + '_TARGETS']: 'js',
        PSC1_RETAIN_CORPUS_INPUTS: '1',
        PSC1_FOCUSED_FAIL_FAST: '1',
      },
      stdio: 'inherit',
      timeout: 900000,
    },
  );
  assert.equal(result.error, undefined);
  assert.equal(result.status, 0, suite);
  const evidence = read('dist/scoped-correctness/' + suite + '/results.json');
  assert.equal(evidence.passed, true);
  assert.equal(evidence.retainedInputs.length, 2);
  for (const fixture of evidence.retainedInputs)
    reference.push({ ...fixture, suite, captured: capturedSources(fixture.sources) });
}
const executable = (name) => path.resolve('.lake/build/bin/' + name);
const checker = executable('psc1_independent_checker');
const probe = executable('psc1_output_abi_probe');
const lexical = createLosslessSourceTool({
  executable: executable('psc1_lossless_source'),
  sha256: sha(fs.readFileSync(executable('psc1_lossless_source'))),
});
const ownership = createSourceOwnershipTool({
  lexicalTool: lexical,
  executable: executable('psc1_source_ownership'),
  sha256: sha(fs.readFileSync(executable('psc1_source_ownership'))),
  checkerExecutable: checker,
  checkerSha256: sha(fs.readFileSync(checker)),
});
// The native .ps fixtures import authoritative .lean libraries. Convert just the
// library closure, keep every authored .ps fixture/application body, and require
// the original native admissions to match. The homogeneous wire stays unchanged.
const libraries = new Map();
for (const fixture of reference.filter((row) => row.syntax === 'lean')) {
  for (const source of fixture.captured.filter((row) => row.module.startsWith('ProofScript.'))) {
    if (libraries.has(source.module)) assert.equal(libraries.get(source.module).text, source.text);
    else libraries.set(source.module, source);
  }
}
const librarySources = [
  ...libraries.values(),
  {
    module: 'Entry',
    kind: 'lean',
    text:
      [...libraries.keys()].map((name) => 'import ' + name).join('\n') +
      '\ndef modularstdlibsentinel : Nat := 0\n',
  },
];
const snapshots = librarySources.map((row) =>
  lexical.capture({
    module: row.module,
    grammar: 'lean',
    bytes: Buffer.from(row.text),
  }),
);
const index = ownership.analyze({ snapshots, entry: 'Entry', assurance: 'ordinary-checked' });
const converter = createCheckedSourceConverter({ ownershipTool: ownership });
const conversion = converter.convert({
  index,
  snapshots,
  targetGrammar: 'ps',
  commentPolicy: 'owner-notes',
});
assert.equal(conversion.admissionsSha256, index.admissionsSha256);
assert.equal(conversion.originalIrSha256, index.originalIrSha256);
const psLibraries = new Map(
  [...libraries.keys()].map((module) => [
    module,
    new TextDecoder('utf-8', { fatal: true }).decode(converter.readCandidate(conversion, module)),
  ]),
);
const records = [];
const toolPins = [checker, probe].map((file) => [file, sha(fs.readFileSync(file))]);
function candidate(id, target, sources, assurance) {
  for (const [file, expected] of toolPins) assert.equal(sha(fs.readFileSync(file)), expected);
  const wire = [
    'psc1-compiler-service/1',
    id,
    compilerSourceClosureDigest(sources),
    sources[0].kind,
    assurance,
    'Entry',
    sources.map((row) => [row.module, row.text]),
  ];
  const input = path.join(root, 'native', id + '-' + target + '.request.json');
  const output = path.join(root, 'native', id + '-' + target + '.candidate.json');
  write(input, wire);
  run('prlimit', ['--as=4294967296', '--stack=8388608', '--', probe, target, input, output], {
    timeoutMs: 240000,
    timeoutPolicy: 'standard-240s',
    logDirectory: path.join(root, 'native-processes', id + '-' + target),
    env: {
      ...process.env,
      LEAN_MAIN_USE_THREAD: '0',
      LEAN_NUM_THREADS: '0',
      LEAN_STACK_SIZE_KB: '8192',
    },
  });
  return read(output);
}
for (const fixture of reference) {
  const id = fixture.suite + '-' + fixture.syntax;
  const sources = fixture.captured.map((row) => {
    if (fixture.syntax === 'ps' && row.module.startsWith('ProofScript.')) {
      assert.ok(psLibraries.has(row.module));
      return { ...row, kind: 'ps', text: psLibraries.get(row.module) };
    }
    assert.equal(row.kind, fixture.syntax, 'authored fixture grammar is preserved');
    return row;
  });
  const expected = {};
  for (const target of ['js', 'ts', 'rust', 'wasm-core']) {
    const c = candidate(id, target, sources, fixture.assurance);
    assert.equal(c.status, 'candidate', JSON.stringify(c));
    assert.equal(c.target, target);
    assert.deepEqual(c.publicNames, fixture.publicNames);
    assert.equal(
      sha(c.admissionRequest.admissions),
      fixture.admissionsSha256,
      'authored/native admission changed: ' + id,
    );
    runIndependentChecker(checker, c.admissionRequest.admissions);
    expected[target] = {
      candidateSha256: sha(JSON.stringify(c)),
      admissionsSha256: sha(c.admissionRequest.admissions),
      originalIrSha256: sha(JSON.stringify(c.originalIr)),
      specializedIrSha256: sha(JSON.stringify(c.specializedIr)),
      sourceSha256: sha(c.source),
    };
  }
  const negatives = [];
  for (const n of fixture.negativeCases) {
    const wrong = sources.map((row) => (row.module === 'Entry' ? { ...row, text: n.text } : row));
    const c = candidate(id + '-negative-' + n.id, 'js', wrong, fixture.assurance);
    assert.equal(c.status, 'refused', id + '/' + n.id);
    negatives.push({ ...n, phase: c.phase, code: c.code });
  }
  records.push({
    id,
    suite: fixture.suite,
    grammar: fixture.syntax,
    sources,
    assurance: fixture.assurance,
    publicNames: fixture.publicNames,
    contractFile: fixture.contractFile,
    contract: fixture.contract,
    oracle: fixture.oracle,
    nativeBundleManifestSha256: fixture.nativeBundleManifestSha256,
    nativeSourceSnapshotSha256: fixture.nativeSourceSnapshotSha256,
    expected,
    negatives,
  });
  write(path.join(root, 'prepared.json'), {
    schema: 'psc1-modular-retained-corpus/1',
    testedCommit: process.env.GITHUB_SHA,
    records,
    libraryConversion: {
      modules: [...libraries.keys()],
      admissionsSha256: conversion.admissionsSha256,
      originalIrSha256: conversion.originalIrSha256,
      policy: 'checked conversion of libraries only; authored lean/ps fixture bodies retained',
    },
  });
  console.log(
    'PSC1_MODULAR_CORPUS_PREPARED ' +
      JSON.stringify({ id, modules: sources.length, negatives: negatives.length }),
  );
}
assert.equal(records.length, 16);
