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
const targets = ['js', 'ts', 'rust', 'wasm-core', 'wasm-component', 'python', 'php'];
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
  ['psc1_while_tests', 'PSC1_WHILE_TESTS: PASS']
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
