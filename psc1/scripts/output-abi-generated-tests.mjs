// Execute opt-in IO requests through an actual generated G1 service after the
// sole seed phase has removed every native compiler executable.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { sha, verifyArtifact, boundedRun } from '../host-tools/generated-target-tools.mjs';
import { runIndependentChecker } from '../host-tools/compiler-host-protocol.mjs';
const [engine] = process.argv.slice(2);
assert.ok(['js', 'ts', 'rust', 'wasm-core'].includes(engine));
const directory = path.resolve('dist/generated-unified-' + engine + '-compiler');
const qualification = JSON.parse(fs.readFileSync(path.join(directory, 'qualification.json')));
assert.equal(qualification.status, 'passed');
assert.equal(qualification.correctnessQualification, 'G1-only');
assert.deepEqual(fs.readdirSync('.lake/build/bin').filter(name =>
  fs.statSync(path.join('.lake/build/bin', name)).isFile()), ['psc1_independent_checker']);
const checker = path.resolve('.lake/build/bin/psc1_independent_checker');
const checkerSha256 = sha(fs.readFileSync(checker));
const artifact = qualification.serviceArtifact;
const referenceFile = path.resolve('dist/output-abi/native-reference.json');
const referenceBytes = fs.readFileSync(referenceFile), reference = JSON.parse(referenceBytes);
assert.equal(reference.schema, 'psc1-output-abi-native-reference/1');
assert.equal(reference.testedCommit, process.env.GITHUB_SHA);
assert.equal(reference.records.length, 4);
assert.equal(reference.negatives, 30);
const destination = path.join(directory, 'output-abi');
fs.mkdirSync(destination, { recursive: true });
fs.writeFileSync(path.join(destination, 'package.json'), '{"type":"module"}\n');
const events = [], cases = [];
const report = { schema: 'psc1-output-abi-generated/1', testedCommit: process.env.GITHUB_SHA,
  engine, sourceClosureDigest: qualification.sourceClosureDigest,
  sourceModules: qualification.sourceModules, serviceSha256: artifact.sha256,
  nativeReferenceSha256: sha(referenceBytes), checkerSha256,
  nativeDelegationBoundary: qualification.nativeDelegationBoundary,
  status: 'running', cases, events, publication: false, fixedPoint: 'not-requested' };
const checkpoint = () => fs.writeFileSync(path.join(destination, 'qualification.json'),
  JSON.stringify(report, null, 2) + '\n');
try {
  for (const [index, item] of reference.requestInventory.entries()) {
    verifyArtifact(artifact.file, artifact.sha256);
    assert.equal(sha(fs.readFileSync(checker)), checkerSha256);
    assert.equal(sha(fs.readFileSync(referenceFile)), report.nativeReferenceSha256);
    const input = path.join(destination, index + '.request.json');
    const output = path.join(destination, index + '.candidate.json');
    const request = JSON.stringify(['psc1-unified-compiler-service/2', item.target, item.request]);
    assert.ok(Buffer.byteLength(request) <= 32 * 1024 * 1024);
    fs.writeFileSync(input, request);
    const result = boundedRun(process.execPath, [path.resolve('scripts/generated-target-runner.mjs'),
      artifact.file, artifact.sha256, input, output, 'performance-240s'], {
      logDirectory: path.join(destination, index + '-process'),
      timeoutMs: 240000, timeoutPolicy: 'standard-240s',
    });
    const event = { index, elapsedMs: result.elapsedMs, maxRssKiB: result.maxRssKiB,
      peakTreeRssKiB: result.peakTreeRssKiB, sampledCpuSeconds: result.sampledCpuSeconds,
      status: result.status, error: result.error, timeoutMs: 240000 };
    events.push(event); checkpoint();
    assert.equal(result.error, null, result.stderr);
    assert.equal(result.status, 0, result.stderr);
    const bytes = fs.readFileSync(output), candidate = JSON.parse(bytes);
    const execution = JSON.parse(result.stdout.trim());
    assert.equal(execution.protocol, 'psc1-generated-target-run/1');
    assert.equal(execution.target, engine);
    assert.equal(execution.serviceSha256, artifact.sha256);
    assert.equal(execution.requestSha256, sha(request));
    assert.equal(execution.responseSha256, sha(bytes));
    assert.equal(sha(JSON.stringify(candidate)), item.candidateSha256,
      'generated/native complete candidate mismatch at request ' + index);
    const row = { index, target: item.target, status: candidate.status,
      candidateSha256: item.candidateSha256, outputAbi: candidate.outputAbi ?? null };
    if (candidate.status === 'candidate') {
      const receipt = runIndependentChecker(checker, candidate.admissionRequest.admissions);
      assert.equal(receipt.leanVersion, '4.35.0');
      row.independentAdmission = true;
      const modulePath = path.join(destination, index + '.mjs');
      fs.writeFileSync(modulePath, candidate.source);
      const api = await import(pathToFileURL(modulePath).href);
      if (candidate.outputAbi === 'io-dispatcher') {
        assert.equal(api.run('λ🙂', value => 'ok:' + value), 'ok:λ🙂');
        const trap = new Error('explicit-dispatcher-trap');
        assert.throws(() => api.run('x', () => { throw trap; }), error => error === trap);
        assert.throws(() => api.run('x', 0), TypeError);
      } else assert.equal(api.answer, 42n);
      row.runtime = 'executed';
    } else {
      assert.equal(candidate.source, undefined);
      assert.equal(candidate.admission, 'not-run');
    }
    cases.push(row); checkpoint();
    console.log('PSC1_OUTPUT_ABI_GENERATED_REQUEST: ' + JSON.stringify({ engine, ...row, ...event }));
  }
  assert.equal(cases.filter(row => row.status === 'candidate').length, 5);
  assert.equal(cases.filter(row => row.status === 'refused').length, 30);
  verifyArtifact(artifact.file, artifact.sha256);
  assert.equal(sha(fs.readFileSync(checker)), checkerSha256);
  report.status = 'passed';
} catch (error) { report.status = 'failed'; report.failure = error.message; throw error; }
finally {
  checkpoint();
  console.log('PSC1_OUTPUT_ABI_GENERATED: ' + JSON.stringify({
    engine, status: report.status, cases: cases.length, failure: report.failure,
    sourceClosureDigest: report.sourceClosureDigest, serviceSha256: artifact.sha256 }));
}
