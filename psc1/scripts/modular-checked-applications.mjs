// Retained real application cases through the same checked host, using complete
// modular compiler engines. Native compiler executables are removed first.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import { loadExecutableCompiler } from '../host-tools/executable/loader.mjs';
import { createExecutableCompilerSession } from '../host-tools/executable/session.mjs';
import { readManifestBytes, verify } from '../host-tools/executable/verify.mjs';
import { files, sha256 as sha } from '../host-tools/executable/tools.mjs';
import { requireSupportedRuntime } from '../host-tools/runtime-policy.mjs';
import { executeApplication } from './output-abi-applications.mjs';

const out = path.resolve('dist/modular-checked');
const prepared = JSON.parse(fs.readFileSync(path.join(out, 'prepared.json')));
assert.equal(prepared.schema, 'psc1-modular-application-preparation/1');
const runtime = requireSupportedRuntime();
const graph = {
  graphRoot: prepared.graphRoot,
  manifestFile: prepared.manifestFile,
  manifestSha256: prepared.manifestSha256,
};
const manifest = verify(
  graph.graphRoot,
  readManifestBytes(graph.manifestFile),
  graph.manifestSha256,
);
const checker = path.resolve('.lake/build/bin/psc1_independent_checker');
const checkerSha256 = sha(fs.readFileSync(checker));
const disabled = path.resolve('.lake/build/modular-application-native-disabled');
fs.mkdirSync(disabled, { recursive: true });
for (const name of fs.readdirSync('.lake/build/bin')) {
  if (name === 'psc1_independent_checker') continue;
  const file = path.resolve('.lake/build/bin', name);
  if (fs.lstatSync(file).isFile()) fs.renameSync(file, path.join(disabled, name));
}
const noFrontend = () =>
  assert.deepEqual(
    fs
      .readdirSync('.lake/build/bin')
      .filter((name) => fs.lstatSync(path.join('.lake/build/bin', name)).isFile()),
    ['psc1_independent_checker'],
  );
noFrontend();
const sdkRoots = ['typescript', '@typescript/typescript-linux-x64'].map((name) =>
  path.resolve('../node_modules', name),
);
for (const sdkRoot of sdkRoots)
  assert.equal(JSON.parse(fs.readFileSync(path.join(sdkRoot, 'package.json'))).version, '7.0.2');
const sdkPins = sdkRoots.flatMap((root) =>
  files(root).map((row) => ({ path: path.join(root, row.path), sha256: row.sha256 })),
);
const elf = sdkPins.filter((row) => {
  if (!row.path.startsWith(sdkRoots[1] + path.sep)) return false;
  const fd = fs.openSync(row.path, 'r'),
    prefix = Buffer.alloc(4);
  try {
    fs.readSync(fd, prefix, 0, 4, 0);
  } finally {
    fs.closeSync(fd);
  }
  return prefix.equals(Buffer.from([127, 69, 76, 70]));
});
assert.equal(elf.length, 1, 'one locked native TypeScript consumer');
const typescript = {
  entry: path.join(sdkRoots[0], 'bin/tsc'),
  executable: elf[0].path,
  pins: sdkPins,
};
const records = [],
  negatives = [];
const report = {
  schema: 'psc1-modular-checked-applications/1',
  testedCommit: process.env.GITHUB_SHA,
  compilerSourceClosureDigest: manifest.sourceClosureDigest,
  runtime,
  compilerSemantics: 'complete generated modular graph; native frontends removed',
  independentChecker: 'official Lean 4.35.0',
  status: 'running',
  records,
  negatives,
  defaultDistributionChanged: false,
  fullModularSelfHosting: false,
};
const checkpoint = () =>
  fs.writeFileSync(
    path.join(out, 'qualification-' + runtime.name + '.json'),
    JSON.stringify(report, null, 2) + '\n',
  );
let serial = 0;
function session(variant, options) {
  const adapter = path.join(out, 'adapters', variant + '-' + serial++ + '.mjs');
  fs.mkdirSync(path.dirname(adapter), { recursive: true });
  return createExecutableCompilerSession({
    ...graph,
    variant,
    adapterFile: adapter,
    checkerExecutable: checker,
    checkerSha256,
    publicationProtocol: 'portable-file',
    ...options,
  });
}
const comparable = (rows) =>
  rows.map(({ id, exitCode, stdoutSha256, outputSha256, preservedPrevious }) => ({
    id,
    exitCode,
    stdoutSha256,
    outputSha256,
    preservedPrevious,
  }));

try {
  const config = {
    root: graph.graphRoot,
    manifestFile: graph.manifestFile,
    manifestSha256: graph.manifestSha256,
    variant: 'js',
  };
  await assert.rejects(
    () => loadExecutableCompiler({ ...config, manifestSha256: '0'.repeat(64) }),
    /PSC1_EXECUTABLE_MANIFEST_HASH/,
  );
  negatives.push({ case: 'wrong-manifest-refused-before-import' });
  await assert.rejects(
    () => loadExecutableCompiler({ ...config, variant: 'python' }),
    /PSC1_EXECUTABLE_LOAD_ARGUMENTS/,
  );
  negatives.push({ case: 'unsupported-engine-refused-before-import' });
  assert.throws(
    () => createExecutableCompilerSession({
      ...graph, variant: 'js',
      adapterFile: path.join(out, 'reserved.mjs'),
      serviceKind: 'unified-embedded',
    }),
    /PSC1_EXECUTABLE_SESSION_TOOL_OVERRIDE/,
  );
  negatives.push({ case: 'reserved-tool-override-refused' });
  assert.throws(
    () => createExecutableCompilerSession({
      ...graph, variant: 'js',
      adapterFile: path.join(graph.graphRoot, 'adapter.mjs'),
    }),
    /PSC1_EXECUTABLE_ADAPTER_INSIDE_GRAPH/,
  );
  negatives.push({ case: 'mutable-adapter-inside-graph-refused' });
  for (const variant of ['js', 'ts']) {
    for (const expected of prepared.records) {
      noFrontend();
      const fixture = prepared.reference.applications.find((row) => row.id === expected.id);
      assert.ok(fixture);
      const wire = expected.request;
      const sources = wire[6].map(([module, text]) => ({ module, kind: wire[3], text }));
      const store = path.join(
        out,
        'executions',
        runtime.name,
        variant,
        expected.id,
        expected.target,
      );
      const active = session(variant, {
        requestId: wire[1],
        sources,
        entryModule: wire[5],
        assurance: wire[4],
        target: expected.target,
        outputAbi: 'io-dispatcher',
        publicationRoot: path.join(store, 'store'),
        ...(expected.target === 'ts' ? { typescript } : {}),
      });
      const admitted = active.execute();
      assert.equal(admitted.logicalAdmission, 'accepted');
      assert.equal(admitted.outputAbi, 'io-dispatcher');
      assert.equal(admitted.admissionsSha256, expected.admissionsSha256);
      assert.equal(admitted.originalIrSha256, expected.originalIrSha256);
      assert.equal(admitted.specializedIrSha256, expected.specializedIrSha256);
      assert.equal(admitted.candidateSourceSha256, expected.sourceSha256);
      const candidate = JSON.parse(
        fs.readFileSync(path.join(active.stagingDirectory, 'candidate.json')),
      );
      assert.equal(sha(JSON.stringify(candidate)), expected.candidateSha256);
      const published = active.publish();
      const contractFile =
        fixture.application === 'cli-json'
          ? 'docs/PSC1_APPLICATION_EXECUTION_CONTRACT.json'
          : 'docs/PSC1_COMPILER_APPLICATION_CONTRACT.json';
      const contractBytes = fs.readFileSync(contractFile);
      assert.equal(sha(contractBytes), fixture.contractSha256);
      const cases = executeApplication(
        { ...fixture, contract: JSON.parse(contractBytes) },
        published.runtimeTarget,
        path.join(store, 'cases'),
      );
      assert.deepEqual(comparable(cases), comparable(fixture.cases));
      noFrontend();
      records.push({
        variant,
        outputTarget: expected.target,
        id: expected.id,
        modules: fixture.modules,
        sourceClosureDigest: admitted.sourceClosureDigest,
        admissionsSha256: admitted.admissionsSha256,
        originalIrSha256: admitted.originalIrSha256,
        sourceSha256: admitted.candidateSourceSha256,
        generation: published.generation,
        processEvents: active.events,
        cases,
      });
      checkpoint();
      console.log(
        'PSC1_MODULAR_CHECKED_APPLICATION ' +
          JSON.stringify({
            runtime: runtime.name,
            variant,
            id: expected.id,
            target: expected.target,
            cases: cases.length,
          }),
      );
    }
  }

  // Real checked-session failures must preserve an existing portable generation.
  const source = [
    {
      module: 'Entry',
      kind: 'lean',
      text: 'def run (input : String) (dispatch : String -> String) : String := dispatch input\n',
    },
  ];
  for (const variant of ['js', 'ts']) {
    const store = path.join(out, 'negative-stores', variant);
    const options = {
      requestId: 'negative-' + variant,
      sources: source,
      entryModule: 'Entry',
      assurance: 'checked',
      target: 'js',
      outputAbi: 'io-dispatcher',
      publicationRoot: store,
    };
    const accepted = session(variant, options);
    accepted.execute();
    accepted.publish();
    const pointer = fs.readFileSync(path.join(store, 'current.json'));
    const blocked = session(variant, {
      ...options,
      requestId: 'refused-' + variant,
      sources: [{ module: 'Entry', kind: 'lean', text: 'def invalid : Nat := true\n' }],
    });
    assert.throws(() => blocked.execute(), /COMPILER_REFUSED:elaboration/);
    assert.throws(() => blocked.publish(), /NOT_ADMITTED/);
    assert.deepEqual(fs.readFileSync(path.join(store, 'current.json')), pointer);
    negatives.push({ variant, case: 'typing-refusal-preserves-generation' });

    const sealed = session(variant, { ...options, requestId: 'resource-' + variant });
    sealed.execute();
    const row = manifest.files.find((row) => row.path.endsWith('.mjs'));
    const file = path.join(graph.graphRoot, row.path),
      prior = fs.readFileSync(file);
    try {
      fs.appendFileSync(file, '\n// tampered after checking\n');
      assert.throws(() => sealed.publish(), /TOOL_IDENTITY_CHANGED/);
      assert.deepEqual(fs.readFileSync(path.join(store, 'current.json')), pointer);
    } finally {
      fs.writeFileSync(file, prior);
    }
    negatives.push({ variant, case: 'graph-change-prevents-publication' });
  }

  const row = manifest.files.find((row) => row.path.endsWith('.mjs'));
  const file = path.join(graph.graphRoot, row.path),
    prior = fs.readFileSync(file);
  const originalRead = fs.readFileSync;
  try {
    fs.truncateSync(file, 33554433);
    fs.readFileSync = function (selected, ...args) {
      assert.notEqual(selected, file, 'oversized declared file must be rejected before reading');
      return originalRead.call(fs, selected, ...args);
    };
    assert.throws(
      () => verify(graph.graphRoot, readManifestBytes(graph.manifestFile), graph.manifestSha256),
      /PSC1_EXECUTABLE_FILE_SIZE/,
    );
  } finally {
    fs.readFileSync = originalRead;
    fs.writeFileSync(file, prior);
  }
  negatives.push({ case: 'oversized-file-refused-before-reading' });
  const unsafe = path.join(graph.graphRoot, 'unexpected-empty-directory');
  try {
    fs.mkdirSync(unsafe);
    assert.throws(
      () => verify(graph.graphRoot, readManifestBytes(graph.manifestFile), graph.manifestSha256),
      /UNEXPECTED_DIRECTORY/,
    );
  } finally {
    fs.rmdirSync(unsafe);
  }
  negatives.push({ case: 'unexpected-directory-refused' });
  verify(graph.graphRoot, readManifestBytes(graph.manifestFile), graph.manifestSha256);
  assert.equal(records.length, 16);
  assert.equal(
    records.reduce((count, row) => count + row.cases.length, 0),
    264,
  );
  assert.equal(negatives.length, 10);
  report.status = 'passed';
} catch (error) {
  report.status = 'failed';
  report.failure = error.message;
  throw error;
} finally {
  checkpoint();
  console.log('PSC1_MODULAR_CHECKED_APPLICATIONS ' + JSON.stringify(report));
}
