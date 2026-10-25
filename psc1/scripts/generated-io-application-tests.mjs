// Actual generated G1 application/session qualification. This is not npm/G3
// qualification. Immutable downloaded G1 resources supply all compiler semantics.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { readQualifiedArtifact, sha256 as sha } from './kernel435-qualified-artifact.mjs';
import { createGeneratedJsCompilerSession } from '../host-tools/generated-compiler-session.mjs';
import { verifyArtifact } from '../host-tools/generated-target-tools.mjs';
import { executeApplication } from './output-abi-applications.mjs';
const inputs = JSON.parse(fs.readFileSync('scripts/generated-io-g1-inputs.json'));
assert.equal(inputs.schema, 'psc1-generated-io-g1-inputs/1');
const reference = JSON.parse(fs.readFileSync('dist/output-abi/native-reference.json'));
assert.equal(reference.applications.length, 4);
const checker = path.resolve('.lake/build/bin/psc1_independent_checker');
const checkerSha256 = sha(fs.readFileSync(checker));
const disabled = path.resolve('.lake/build/disabled-io-application-native-tools');
fs.mkdirSync(disabled, { recursive: true });
for (const name of fs.readdirSync('.lake/build/bin')) {
  if (name === 'psc1_independent_checker') continue;
  const file = path.resolve('.lake/build/bin', name);
  if (fs.statSync(file).isFile()) fs.renameSync(file, path.join(disabled, name));
}
const out = path.resolve('dist/generated-io-applications');
fs.mkdirSync(out, { recursive: true });
const records = [], report = { schema: 'psc1-generated-io-applications/1',
  testedCommit: process.env.GITHUB_SHA, sourceClosureDigest: inputs.compilerSourceClosureDigest,
  compilerSemantics: 'actual generated G1; native compiler executables removed',
  independentChecker: 'official Lean 4.35.0 native', checkerSha256,
  status: 'running', records, npmQualification: 'not-run', fixedPoint: 'not-claimed' };
const checkpoint = () => fs.writeFileSync(path.join(out, 'qualification.json'),
  JSON.stringify(report, null, 2) + '\n');
try {
  for (const [engine, input] of Object.entries(inputs.engines)) {
    const archive = await readQualifiedArtifact(input, path.join(out, engine, 'input'));
    const directory = path.join(archive, 'generated-unified-' + engine + '-compiler');
    const qualification = JSON.parse(fs.readFileSync(path.join(directory, 'qualification.json')));
    assert.equal(qualification.status, 'passed');
    assert.equal(qualification.correctnessQualification, 'G1-only');
    assert.equal(qualification.sourceClosureDigest, inputs.compilerSourceClosureDigest);
    assert.equal(qualification.testedCommit, input.commit);
    assert.equal(qualification.generations.length, 1);
    const manifestFile = path.join(directory, 'G1-service/artifact.json');
    const manifestHash = sha(fs.readFileSync(manifestFile));
    assert.equal(manifestHash, qualification.generations[0].artifactSha256);
    const artifact = verifyArtifact(manifestFile, manifestHash);
    assert.equal(artifact.target, engine);
    const executable = path.join(path.dirname(manifestFile), artifact.executable);
    if (engine === 'rust') fs.chmodSync(executable, 0o755);
    const adapter = path.join(out, engine, 'service.mjs');
    let imports, invoke, transports = [];
    if (engine === 'js' || engine === 'ts') {
      imports = 'import {psCompilerServiceCandidate as candidate} from ' +
        JSON.stringify(pathToFileURL(executable).href) + ';\n';
      invoke = 'candidate(envelope)';
    } else if (engine === 'wasm-core') {
      imports = 'import {loadWasmArtifact} from ' +
        JSON.stringify(pathToFileURL(path.resolve('host-tools/generated-wasm-transport.mjs')).href) +
        ';\nconst {psCompilerServiceCandidate:candidate}=loadWasmArtifact(' + JSON.stringify(manifestFile) + ');\n';
      invoke = 'candidate(envelope)';
      transports = ['host-tools/generated-wasm-transport.mjs'];
    } else {
      imports = 'import {runGeneratedRustCompiler} from ' +
        JSON.stringify(pathToFileURL(path.resolve('host-tools/generated-rust-transport.mjs')).href) + ';\n';
      invoke = 'runGeneratedRustCompiler({executable:' + JSON.stringify(executable) +
        ',executableSha256:' + JSON.stringify(sha(fs.readFileSync(executable))) + ',request:envelope})';
      transports = ['host-tools/generated-rust-transport.mjs', 'host-tools/generated-rust-guard.mjs'];
    }
    fs.writeFileSync(adapter, imports +
      'export function psCompilerJsServiceCandidate(request){const envelope=JSON.stringify(["psc1-unified-compiler-service/2","js",JSON.parse(request)]);return ' + invoke + ';}\n');
    const dependencies = [manifestFile, ...artifact.files.map(file =>
      path.join(path.dirname(manifestFile), file.path)), ...transports.map(file => path.resolve(file))]
      .map(file => ({ path: file, sha256: sha(fs.readFileSync(file)) }));
    for (const expected of reference.applications) {
      verifyArtifact(manifestFile, manifestHash);
      assert.deepEqual(fs.readdirSync('.lake/build/bin').filter(name =>
        fs.statSync(path.join('.lake/build/bin', name)).isFile()), ['psc1_independent_checker']);
      const native = reference.requestInventory.find(item => item.request[1] === expected.id);
      assert.ok(native);
      const wire = native.request, sources = wire[6].map(([module, text]) => ({ module, kind: wire[3], text }));
      const store = path.join(out, engine, expected.id, 'store');
      const session = createGeneratedJsCompilerSession({
        requestId: wire[1], sources, entryModule: wire[5], assurance: wire[4],
        outputAbi: 'io-dispatcher', serviceFile: adapter, serviceSha256: sha(fs.readFileSync(adapter)),
        runnerFile: path.resolve('scripts/generated-compiler-runner.mjs'),
        runnerSha256: sha(fs.readFileSync('scripts/generated-compiler-runner.mjs')),
        checkerExecutable: checker, checkerSha256, publicationRoot: store, serviceDependencies: dependencies,
      });
      const receipt = session.execute();
      assert.equal(receipt.logicalAdmission, 'accepted');
      assert.equal(receipt.outputAbi, 'io-dispatcher');
      assert.equal(receipt.sourceClosureDigest, expected.sourceClosureDigest);
      assert.equal(receipt.admissionsSha256, expected.admissionsSha256);
      assert.equal(receipt.originalIrSha256, expected.originalIrSha256);
      assert.equal(receipt.sourceSha256, expected.sourceSha256);
      const candidate = JSON.parse(fs.readFileSync(path.join(session.stagingDirectory, 'candidate.json')));
      assert.equal(sha(JSON.stringify(candidate)), native.candidateSha256);
      const published = session.publish();
      const contractFile = expected.application === 'cli-json'
        ? 'docs/PSC1_APPLICATION_EXECUTION_CONTRACT.json' : 'docs/PSC1_COMPILER_APPLICATION_CONTRACT.json';
      assert.equal(sha(fs.readFileSync(contractFile)), expected.contractSha256);
      const fixture = { ...expected, contract: JSON.parse(fs.readFileSync(contractFile)) };
      const cases = executeApplication(fixture, published.target,
        path.join(out, engine, expected.id, 'executions'));
      const comparable = rows => rows.map(({ id, exitCode, stdoutSha256, outputSha256, preservedPrevious }) =>
        ({ id, exitCode, stdoutSha256, outputSha256, preservedPrevious }));
      assert.deepEqual(comparable(cases), comparable(expected.cases));
      records.push({ engine, id: expected.id, modules: expected.modules,
        sourceClosureDigest: receipt.sourceClosureDigest, admissionsSha256: receipt.admissionsSha256,
        originalIrSha256: receipt.originalIrSha256, sourceSha256: receipt.sourceSha256,
        generation: published.generation, cases });
      checkpoint();
      console.log('PSC1_GENERATED_IO_APPLICATION: ' + JSON.stringify({
        engine, id: expected.id, cases: cases.length, generation: published.generation }));
    }
  }
  assert.equal(records.length, 16);
  assert.equal(records.reduce((count, record) => count + record.cases.length, 0), 264);
  report.status = 'passed';
} catch (error) { report.status = 'failed'; report.failure = error.message; throw error; }
finally { checkpoint(); console.log('PSC1_GENERATED_IO_APPLICATIONS: ' + JSON.stringify({
  status: report.status, applications: records.length,
  cases: records.reduce((count, record) => count + record.cases.length, 0), failure: report.failure })); }
