// Consolidate successful scoped CI evidence. This is not a proof certificate.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const output = path.join(root, 'dist/scoped-correctness');
const read = relative => JSON.parse(fs.readFileSync(path.join(root, relative), 'utf8'));
const runtime = read('dist/scoped-correctness/runtime-conformance/results.json');
const scripts = read('dist/scoped-correctness/script-backends/results.json');
const whileRuntime = read('dist/scoped-correctness/ordinary-while-conformance/results.json');
const minimumWhile = read('dist/scoped-correctness/ordinary-while-conformance-python314/results.json');
const architecture = read('dist/scoped-correctness/backend-architecture/results.json');
const minimumRuntime = read('dist/scoped-correctness/runtime-conformance-python314/results.json');
const minimumScripts = read('dist/scoped-correctness/script-backends-python314/results.json');
const distribution = read('dist/scoped-correctness/npm-native/qualification.json');
const library = read(distribution.optionalLibraryReceipt);
const namespaceBoundaries = ['lean', 'ps'].map(syntax =>
  read('dist/scoped-correctness/namespace-boundaries/' + syntax + '.json'));
const targets = ['js', 'ts', 'rust', 'wasm-core', 'wasm-component', 'python', 'php'];

const typedErrors = read('dist/scoped-correctness/typed-errors/results.json');
const minimumErrors = read('dist/scoped-correctness/typed-errors-python314/results.json');
const components = read('dist/scoped-correctness/wasm-component-direct.json');
const compilerProtocol = read('dist/scoped-correctness/compiler-host-protocol/results.json');
const compilerCensus = read('dist/scoped-correctness/compiler-source-census/inventory.json');
const compilerStages = read('dist/scoped-correctness/compiler-source-census/stages.json');
const compilerPsStages = read('dist/scoped-correctness/compiler-source-census/stages-ps.json');
const compilerStrict = read('dist/scoped-correctness/compiler-source-census/strict-semantic.json');
for (const [data, expectedTargets] of [[typedErrors, targets], [minimumErrors, ['python']]]) {
  assert.equal(data.testedCommit, process.env.GITHUB_SHA || null);
  assert.equal(data.branchHeadCommit, process.env.PSC1_HEAD_SHA || null);
  assert.equal(data.leanCommit, runtime.nativeLean.commit);
  assert.equal(data.passed, true);
  assert.deepEqual(data.failures, []);
  assert.equal(data.nativeObservations, 34);
  const expectedPairs = ['checked', 'ordinary'].flatMap(lane =>
    ['lean', 'ps'].flatMap(syntax => expectedTargets.map(target => lane + '/' + syntax + '/' + target)));
  assert.deepEqual(data.records.map(row => row.lane + '/' + row.syntax + '/' + row.target).sort(),
    expectedPairs.sort(), 'complete unique typed-error target/source pairs');
  for (const row of data.records) {
    assert.equal(row.passed, true);
    assert.equal(row.observations, row.lane === 'checked' ? 32 : 2);
    assert.equal(row.refusals, row.lane === 'checked' ? 2 : 3);
  }
}
assert.equal(components.sourceCommit, process.env.GITHUB_SHA || null);
assert.deepEqual(components.results.map(row => row.syntax).sort(), ['lean', 'ps']);
assert.ok(components.results.every(row => row.status === 'pass' && row.directEncoding &&
  row.exactEmbeddedCore && row.deterministic && row.refusalPreservesGeneration));
assert.equal(compilerProtocol.commit, process.env.GITHUB_SHA || null);
assert.equal(compilerProtocol.fixedPoint, false);
assert.equal(compilerProtocol.sourceClosureSelfCompilation, false);
assert.deepEqual(compilerProtocol.records.map(row => row.target).sort(), ['js', 'rust']);
assert.ok(compilerProtocol.records.every(row => row.transportExecution === 'passed' &&
  row.independentAdmission === 'passed' && row.selfHosting === false));
assert.equal(compilerCensus.commit, process.env.GITHUB_SHA || null);
assert.equal(compilerCensus.probe.completed, true);
assert.equal(compilerCensus.probe.status, 0);
assert.equal(compilerCensus.modules.length, compilerStages.records.length);
assert.equal(compilerStages.admission, 'not-run');
assert.equal(compilerStages.ir, 'not-run');
assert.equal(compilerStages.generatedExecution, 'not-run');
assert.equal(compilerStages.fixedPoint, 'not-run');
for (const [grammar, stages] of [['lean', compilerStages], ['ps', compilerPsStages]]) {
  const lane = compilerCensus.lanes[grammar];
  assert.equal(lane.probe.completed, true);
  assert.equal(lane.probe.status, 0);
  assert.equal(lane.probe.integrityError, null);
  assert.equal(stages.grammar, grammar);
  assert.equal(stages.records.length, compilerCensus.modules.length);
  assert.equal(stages.sourceDerivation, lane.sourceDerivation);
  assert.equal(stages.admission, 'not-run');
  assert.equal(stages.ir, 'not-run');
  assert.equal(stages.generatedExecution, 'not-run');
  assert.equal(stages.fixedPoint, 'not-run');
}
for (const row of compilerPsStages.records.filter(row => row.translation === 'accepted')) {
  assert.ok(row.inputArtifact.startsWith('translated-ps/'));
  assert.match(row.inputSha256, /^[0-9a-f]{64}$/);
}
assert.equal(compilerStrict.commit, process.env.GITHUB_SHA || null);
assert.equal(compilerStrict.passed, true);
assert.equal(compilerStrict.phase, 'semantic-compiler');
assert.equal(compilerStrict.expectedAcceptance, compilerStrict.measured.lean && compilerStrict.measured.ps);
assert.equal(compilerStrict.status === 0, compilerStrict.expectedAcceptance);
for (const syntax of ['lean', 'ps']) {
  for (const group of ['runtime-intrinsic-hygiene', 'prototype-property-hygiene']) {
    assert.ok(architecture.records.some(row => row.group === syntax + '-' + group && row.passed),
      'missing source hygiene execution: ' + syntax + '/' + group);
  }
}

assert.equal(runtime.records.length, targets.length * 2);
assert.equal(runtime.failures.length, 0);
assert.equal(minimumRuntime.failures.length, 0);
assert.deepEqual([...new Set(runtime.records.map(x => x.target))].sort(), [...targets].sort());
assert.equal(minimumRuntime.records.length, 2);
assert.ok(minimumRuntime.records.every(x => x.target === 'python'));
for (const data of [runtime, scripts, architecture, minimumRuntime, minimumScripts, whileRuntime, minimumWhile]) {
  assert.equal(data.commit, process.env.GITHUB_SHA || null);
  assert.ok(data.records.length && data.records.every(x => x.passed === true));
}
for (const [data, expectedTargets] of [[scripts, ['python', 'php']], [minimumScripts, ['python']]]) {
  for (const target of expectedTargets) {
    const record = data.records.find(x => x.group === target + '-self-tail-value-semantics');
    assert.ok(record, 'missing direct self-tail value regression: ' + target);
    assert.equal(record.passed, true);
    assert.equal(record.observations.parallelArgumentSnapshots, true);
    assert.equal(record.observations.capturedParameterValues, true);
    assert.equal(record.observations.shadowedSelfCall, true);
    assert.deepEqual(record.observations.observations, ['21', '12', '7', '9', '12', '12']);
  }
}
for (const [data, expectedTargets] of [[whileRuntime, targets], [minimumWhile, ['python']]]) {
  assert.equal(data.records.length, expectedTargets.length * 2);
  assert.equal(data.divergence.length, expectedTargets.length * 2);
  assert.deepEqual([...new Set(data.records.map(x => x.target))].sort(), [...expectedTargets].sort());
  assert.deepEqual([...new Set(data.divergence.map(x => x.target))].sort(), [...expectedTargets].sort());
  assert.equal(data.failures.length, 0);
  assert.equal(data.assurance, 'ordinary-checked');
  assert.equal(data.behaviorallyVerified, false);
  assert.equal(data.nativeLean.commit, runtime.nativeLean.commit);
  assert.equal(data.oracleFields.length, 18);
  assert.equal(data.loopChecks.length, 8);
  assert.equal(data.longLoopIterations, 100000);
  assert.equal(data.rejections.length, 16);
  assert.ok(data.rejections.every(x => x.passed));
  assert.ok(data.divergence.every(x => x.passed && x.exitCode === 124 &&
    x.earlyReturnPreflight && x.unusedNonvalueCallEvaluated));
  assert.equal(data.patternStrictness.length, expectedTargets.length * 2);
  assert.deepEqual(data.patternStrictness.map(x => x.syntax + '/' + x.target).sort(),
    ['lean', 'ps'].flatMap(syntax => expectedTargets.map(target => syntax + '/' + target)).sort());
  assert.ok(data.patternStrictness.every(x => x.passed && x.exitCode === 124 &&
    x.externalTimeoutMs === 2000 && x.earlyReturnPreflight && x.unusedPatternRhsEvaluated));
}
assert.equal(distribution.qualification, 'passed');
assert.equal(library.independentlyAdmitted, true);
assert.deepEqual(library.checkedControlFlow, ['Id', 'let-mut', 'assignment', 'conditional', 'early-return']);
assert.equal(runtime.controlFlowOracle, 'pinned-native-Lean');
assert.deepEqual(runtime.controlFlowChecks,
  ['mutationcheck', 'capturecheck', 'earlycheck', 'shadowcheck', 'danglingcheck',
   'errorcheck', 'forlistcheck', 'forarraycheck', 'forrangecheck']);
assert.deepEqual(runtime.handwrittenLiteralSyntaxes, ['lean', 'ps']);
assert.deepEqual(runtime.handwrittenOptionalIndexSyntaxes, ['lean', 'ps']);
for (const data of [runtime, minimumRuntime]) {
  assert.deepEqual(data.handwrittenTuplePatternSyntaxes, ['lean', 'ps']);
  assert.deepEqual(data.handwrittenNamespaceSyntaxes, ['lean', 'ps']);
  assert.deepEqual(data.tuplePatternChecks, ['tuplepatterncheck', 'tuplepatterndocheck']);
  assert.deepEqual(data.namespaceChecks, ['namespacecheck']);
}
for (const [index, boundary] of namespaceBoundaries.entries()) {
  assert.equal(boundary.commit, process.env.GITHUB_SHA || null);
  assert.equal(boundary.branchHeadCommit, process.env.PSC1_HEAD_SHA || null);
  assert.equal(boundary.syntax, ['lean', 'ps'][index]);
  assert.equal(boundary.passed, true);
  assert.equal(boundary.importedHelperPrivate, true);
  assert.deepEqual(boundary.publicNames, ['exposed']);
  assert.deepEqual(boundary.executedChecks, [['exposed', false, true]]);
  assert.equal(boundary.entryNamespaceExported, true);
  assert.equal(boundary.entryNamespacePublicNames.length, 1);
  assert.deepEqual(boundary.refusals.map(x => x.name),
    ['duplicate-qualified-name', 'mismatched-end', 'unterminated-namespace', 'unmatched-end',
     'unresolved-namespace-name', 'imported-helper-export']);
  assert.ok(boundary.refusals.every(x => x.passed));
  assert.ok(boundary.refusals.slice(0, 5).every(x => x.previousArtifactsPreserved));
  assert.equal(boundary.refusals[5].noArtifact, true);
}
assert.equal(runtime.rustPrivateClosures.length, 2);
assert.deepEqual(runtime.rustPrivateClosures.map(x => x.syntax).sort(), ['lean', 'ps']);
assert.equal(minimumRuntime.rustPrivateClosures.length, 0);
for (const record of runtime.rustPrivateClosures) {
  assert.equal(record.target, 'rust');
  assert.equal(record.passed, true);
  assert.equal(record.privateExecution, true);
  assert.equal(record.publicRefusal, true);
  assert.deepEqual(record.publicNames, ['privatehighercheck']);
  assert.deepEqual(record.oracleFields, ['rustPrivateFalse', 'rustPrivateTrue']);
  assert.equal(record.refusalReason, 'nested-function-parameter:f');
}

const practicalNative = [
  ['psc1_do_tests', 'PSC1_DO_TESTS: PASS'],
  ['psc1_data_tests', 'PSC1_DATA_TESTS: PASS'],
  ['psc1_while_tests', 'PSC1_WHILE_TESTS: PASS'],
  ['psc1_namespace_tests', 'PSC1_NAMESPACE_TESTS: PASS']
].map(([suite, marker]) => {
  const evidence = 'practical-core/' + suite + '.log';
  const log = fs.readFileSync(path.join(output, evidence), 'utf8');
  assert.ok(log.includes(marker), 'missing native suite success: ' + suite);
  return { suite, passed: true, evidence };
});
function version(command, args) {
  const result = spawnSync(command, args, { cwd: root, encoding: 'utf8', timeout: 10000, maxBuffer: 1024 * 1024 });
  if (result.error || result.status !== 0) throw Error('PSC1_QUALIFICATION_VERSION: ' + command + '\n' + result.stdout + result.stderr);
  return (result.stdout || result.stderr).trim().split('\n')[0];
}
const versions = {
  lean: version('lean', ['--version']),
  node: process.version,
  npm: version('npm', ['--version']),
  typescriptConsumer: version(process.execPath, [process.env.PSC1_TSC, '--version']),
  rust: version('rustc', ['--version']),
  cargo: version('cargo', ['--version']),
  wasmTools: version('wasm-tools', ['--version']),
  wasmtime: version('wasmtime', ['--version']),
  python: version(process.env.PSC1_PYTHON || 'python3', ['--version']),
  pythonMinimum: version(process.env.PSC1_PYTHON_314, ['--version']),
  php: version(process.env.PSC1_PHP || 'php', ['--version'])
};
const receipt = {
  schema: 'psc1-seven-backend-qualification/1',
  qualification: 'passed-scoped-execution',
  testedCommit: process.env.GITHUB_SHA || null,
  branchHeadCommit: process.env.PSC1_HEAD_SHA || null,
  runUrl: process.env.GITHUB_RUN_ID ? 'https://github.com/' + process.env.GITHUB_REPOSITORY + '/actions/runs/' + process.env.GITHUB_RUN_ID : null,
  logicalChecker: runtime.nativeLean,
  runtimeContract: 'psc1-runtime-semantics/1',
  assurance: { checked: true, explicitOrdinary: true, behavioralCertificate: false, verifiedRequest: 'refused' },
  versions,
  sourceSyntaxes: ['lean', 'ps'],
  targetExecutionBundles: runtime.records.length,
  scriptingRegressionGroups: scripts.records.length,
  scriptingArtifactBundles: scripts.records.filter(x => typeof x.sourceBytes === 'number').length,
  architectureRegressionGroups: architecture.records.length,
  minimumPython: { targetExecutionBundles: minimumRuntime.records.length, scriptingRegressionGroups: minimumScripts.records.length,
    artifactBundles: minimumScripts.records.filter(x => typeof x.sourceBytes === 'number').length,
    runtimeEvidence: 'runtime-conformance-python314/results.json', scriptingEvidence: 'script-backends-python314/results.json' },
  practicalCore: {
    nativeSuites: practicalNative,
    controlFlowChecks: runtime.controlFlowChecks,
    referenceOracle: runtime.controlFlowOracle,
    handwrittenLiteralSyntaxes: runtime.handwrittenLiteralSyntaxes,
    handwrittenOptionalIndexSyntaxes: runtime.handwrittenOptionalIndexSyntaxes,
    tuplePatterns: {
      checks: runtime.tuplePatternChecks,
      handwrittenSyntaxes: runtime.handwrittenTuplePatternSyntaxes,
      referenceFields: ['tuplePatternFalse', 'tuplePatternTrue', 'tuplePatternDoFalse', 'tuplePatternDoTrue'],
      strictRhsEvaluation: {
        targetSourceBundles: whileRuntime.patternStrictness.length,
        minimumPythonBundles: minimumWhile.patternStrictness.length,
        externalDeadlineMs: 2000,
        earlyReturnPreflight: true,
        evidence: 'ordinary-while-conformance/results.json:patternStrictness',
        minimumPythonEvidence: 'ordinary-while-conformance-python314/results.json:patternStrictness'
      }
    },
    namespaces: {
      nativeSuite: 'psc1_namespace_tests',
      checks: runtime.namespaceChecks,
      handwrittenSyntaxes: runtime.handwrittenNamespaceSyntaxes,
      referenceFields: ['namespaceFalse', 'namespaceTrue'],
      importedHelpersPrivate: true,
      entryNamespaceExported: true,
      boundaryChecks: namespaceBoundaries.map(x => ({ syntax: x.syntax, passed: x.passed,
        refusalChecks: x.refusals.length, previousArtifactPreservationChecks: 5,
        evidence: 'namespace-boundaries/' + x.syntax + '.json' }))
    },
    rustPrivateClosures: runtime.rustPrivateClosures,
    ordinaryWhile: {
      targetExecutionBundles: whileRuntime.records.length,
      externalDivergenceDeadlines: whileRuntime.divergence.length,
      refusalChecks: whileRuntime.rejections.length,
      loopChecks: whileRuntime.loopChecks,
      longLoopIterations: whileRuntime.longLoopIterations,
      referenceFields: whileRuntime.oracleFields,
      minimumPythonBundles: minimumWhile.records.length,
      minimumPythonDeadlines: minimumWhile.divergence.length,
      evidence: 'ordinary-while-conformance/results.json',
      minimumPythonEvidence: 'ordinary-while-conformance-python314/results.json'
    },
    completeFamilies: false
  },
  programs: runtime.records.map(x => ({
    target: x.target, syntax: x.syntax, publicNames: x.publicNames,
    artifactBytes: x.sourceBytes, executedChecks: x.checks,
    runtimeVersion: x.runtime.runtimeVersion, runtimeEncoding: x.runtime.runtimeEncoding,
    runtimeBytes: x.runtime.runtimeBytes, runtimeSha256: x.runtime.runtimeSha256,
    runtimeRequirements: x.runtime.runtimeRequirements
  })),
  runtimeFreeScriptingExamples: scripts.records.filter(x => x.runtime?.runtimeFree).map(x => ({
    group: x.group, artifactBytes: x.sourceBytes,
    runtimeBytes: x.runtime.runtimeBytes, runtimeSha256: x.runtime.runtimeSha256
  })),
  architectureFoundation: {
    typedErrors: { nativeObservations: typedErrors.nativeObservations,
      targetSourceBundles: typedErrors.records.length,
      refusalChecks: typedErrors.records.reduce((n, row) => n + row.refusals, 0),
      minimumPythonBundles: minimumErrors.records.length,
      evidence: 'typed-errors/results.json', minimumEvidence: 'typed-errors-python314/results.json' },
    directComponents: { grammars: components.results.map(row => row.syntax),
      evidence: 'wasm-component-direct.json', publicAbi: 'Bool-only' },
    generatedCompilerProtocol: { targets: ['js', 'rust'], transportExecuted: true,
      selfHosting: false, fixedPoint: false, evidence: 'compiler-host-protocol/results.json' },
    compilerSourceCensus: { diagnosticCompleted: true, grammar: 'lean', grammars: ['lean', 'ps'],
      psSourceDerivation: 'owned-canonical-translation-from-lean',
      independentlyAuthoredPsCompiler: false,
      strictSemantic: { policyCheckPassed: compilerStrict.passed,
        closureAccepted: compilerStrict.expectedAcceptance, status: compilerStrict.status },
      phases: compilerCensus.phases.map(phase => {
        const rows = compilerStages.records.filter(row => phase.modules.includes(row.module));
        return { name: phase.name, modules: rows.length,
          parseAccepted: rows.filter(row => row.parse === 'accepted').length,
          elaborationAccepted: rows.filter(row => row.elaboration === 'accepted').length,
          firstRefusals: ['parse', 'elaboration'].map(stage => {
            const first = rows.find(row => row[stage] === 'refused');
            return first ? { stage, module: first.module, detail: first.detail } : null;
          }).filter(Boolean) };
      }),
      admission: 'not-run', ir: 'not-run', generatedExecution: 'not-run',
      selfCompilation: 'not-run', fixedPoint: 'not-run',
      psPhases: compilerCensus.phases.map(phase => {
        const rows = compilerPsStages.records.filter(row => phase.modules.includes(row.module));
        return { name: phase.name, modules: rows.length,
          translationAccepted: rows.filter(row => row.translation === 'accepted').length,
          parseAccepted: rows.filter(row => row.parse === 'accepted').length,
          elaborationAccepted: rows.filter(row => row.elaboration === 'accepted').length,
          firstRefusals: ['translation', 'parse', 'elaboration'].map(stage => {
            const first = rows.find(row => row[stage] === 'refused');
            return first ? { stage, module: first.module, detail: first.detail } : null;
          }).filter(Boolean) };
      }),
      inventory: 'compiler-source-census/inventory.json', stages: 'compiler-source-census/stages.json',
      psStages: 'compiler-source-census/stages-ps.json' }
  },
  npm: distribution,
  optionalLibrary: library,
  evidence: {
    runtime: 'runtime-conformance/results.json',
    nativeOracle: 'runtime-conformance/lean-runtime-oracle.json',
    scripting: 'script-backends/results.json',
    directIr: 'script-ir/',
    combinedPublication: 'backend-architecture/results.json',
    npm: 'npm-native/qualification.json'
  },
  exclusions: [
    'full Practical Core feature families', 'unrestricted Lean',
    'Int division/modulo', 'fixed-width/floating runtime scalars',
    'Python/PHP public compound ABI', 'non-Bool component public ABI',
    'formal backend preservation', 'full self-host/fixed-point qualification',
    'npm registry publication', 'non-Linux native package qualification'
  ]
};
fs.writeFileSync(path.join(output, 'SEVEN_BACKEND_QUALIFICATION.json'), JSON.stringify(receipt, null, 2) + '\n');
console.log('PSC1_SEVEN_BACKEND_QUALIFICATION: ' + JSON.stringify(receipt));
