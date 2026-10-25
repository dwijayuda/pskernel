// Actual G1 engines emit JS/TS/Rust IO candidates. SDK consumers are separate
// from compiler execution. G1 evidence does not qualify G2/G3 or npm promotion.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { readQualifiedArtifact, sha256 as sha } from './kernel435-qualified-artifact.mjs';
import { compilerSourceClosureDigest, createCompilerHostSession } from '../host-tools/compiler-host-protocol.mjs';
import { verifyArtifact, boundedRun } from '../host-tools/generated-target-tools.mjs';
import { consumeIoCandidates } from './io-candidate-consumers.mjs';
const inputs = JSON.parse(fs.readFileSync('scripts/generated-io-g1-inputs.json'));
const out = path.resolve('dist/generated-io-mappings');
fs.mkdirSync(out, { recursive: true });
const checker = path.resolve('.lake/build/bin/psc1_independent_checker');
const checkerHash = sha(fs.readFileSync(checker));
const disabled = path.resolve('.lake/build/disabled-io-mappings-native-tools');
fs.mkdirSync(disabled, { recursive: true });
for (const name of fs.readdirSync('.lake/build/bin')) {
  if (name === 'psc1_independent_checker') continue;
  const file = path.resolve('.lake/build/bin', name);
  if (fs.statSync(file).isFile()) fs.renameSync(file, path.join(disabled, name));
}
const candidates = [], report = { schema: 'psc1-generated-io-mappings/1',
  testedCommit: process.env.GITHUB_SHA, compilerSourceClosureDigest: inputs.compilerSourceClosureDigest,
  nativeDelegationBoundary: 'qualified G1 artifacts; native compiler executables removed',
  checkerSha256: checkerHash, status: 'running', requests: [], records: [],
  fixedPoint: 'not-claimed', npmQualification: 'not-run' };
const checkpoint = () => fs.writeFileSync(path.join(out, 'qualification.json'),
  JSON.stringify(report, null, 2) + '\n');
try {
  for (const [engine, input] of Object.entries(inputs.engines)) {
    const archive = await readQualifiedArtifact(input, path.join(out, engine, 'input'));
    const directory = path.join(archive, 'generated-unified-' + engine + '-compiler');
    const qualified = JSON.parse(fs.readFileSync(path.join(directory, 'qualification.json')));
    assert.equal(qualified.status, 'passed');
    assert.equal(qualified.correctnessQualification, 'G1-only');
    assert.equal(qualified.sourceClosureDigest, inputs.compilerSourceClosureDigest);
    const manifest = path.join(directory, 'G1-service/artifact.json');
    const manifestHash = sha(fs.readFileSync(manifest));
    assert.equal(manifestHash, qualified.generations[0].artifactSha256);
    const artifact = verifyArtifact(manifest, manifestHash);
    if (engine === 'rust') fs.chmodSync(path.join(artifact.directory, artifact.executable), 0o755);
    for (const grammar of ['lean', 'ps']) {
      const text = grammar === 'lean'
        ? 'def run (input : String) (dispatch : String -> String) : String := dispatch input\n'
        : 'def run(input : String, dispatch : String -> String) : String := dispatch(input)\n';
      const sources = [{ module: 'Entry', kind: grammar, text }];
      const digest = compilerSourceClosureDigest(sources);
      for (const target of ['js', 'ts', 'rust', 'wasm-core']) {
        const id = engine + '-' + grammar + '-' + target;
        const request = JSON.stringify(['psc1-unified-compiler-service/2', target,
          ['psc1-compiler-service/2', id, digest, grammar, 'checked', 'Entry',
            sources.map(source => [source.module, source.text]), 'io-dispatcher']]);
        const requestFile = path.join(out, id + '.request.json'), outputFile = path.join(out, id + '.candidate.json');
        fs.writeFileSync(requestFile, request);
        const result = boundedRun(process.execPath, [path.resolve('scripts/generated-target-runner.mjs'),
          manifest, manifestHash, requestFile, outputFile, 'performance-240s'], {
          timeoutMs: 240000, timeoutPolicy: 'standard-240s', logDirectory: path.join(out, id + '-process'),
        });
        assert.equal(result.error, null, result.stderr); assert.equal(result.status, 0, result.stderr);
        verifyArtifact(manifest, manifestHash);
        assert.equal(sha(fs.readFileSync(checker)), checkerHash);
        const candidateBytes = fs.readFileSync(outputFile), candidate = JSON.parse(candidateBytes);
        const execution = JSON.parse(result.stdout.trim());
        assert.equal(execution.serviceSha256, manifestHash);
        assert.equal(execution.requestSha256, sha(request));
        assert.equal(execution.responseSha256, sha(candidateBytes));
        const event = { engine, grammar, target, elapsedMs: result.elapsedMs,
          maxRssKiB: result.maxRssKiB, peakTreeRssKiB: result.peakTreeRssKiB };
        report.requests.push(event); checkpoint();
        if (target === 'wasm-core') {
          assert.equal(candidate.status, 'refused');
          assert.equal(candidate.code, 'PSC1_IO_DISPATCHER_ABI_TARGET_UNSUPPORTED');
          assert.equal(candidate.source, undefined);
          candidates.push({ engine, grammar, target, refused: true }); continue;
        }
        for (const [key, value] of Object.entries({ status: 'candidate', protocol: 'psc1-compiler-service/2',
          requestId: id, sourceClosureDigest: digest, grammar, assurance: 'checked',
          outputAbi: 'io-dispatcher', target, candidateOnly: true, admission: 'not-run' }))
          assert.equal(candidate[key], value, id + ':' + key);
        assert.deepEqual(candidate.publicNames, ['run']);
        const session = createCompilerHostSession({ requestId: id, target, sources,
          canonicalAdmissions: candidate.admissionRequest.admissions, checkerExecutable: checker });
        const receipt = session.admit(JSON.stringify(candidate.admissionRequest));
        assert.equal(receipt.accepted, true);
        candidates.push({ engine, grammar, target, source: candidate.source, publicNames: candidate.publicNames,
          admissionsSha256: receipt.admissionsDigest, kernels: ['official Lean 4.35 native'] });
      }
    }
  }
  report.records = consumeIoCandidates(candidates, path.join(out, 'consumers'), row => { report.records.push(row); checkpoint(); });
  assert.equal(report.records.filter(row => row.runtime === 'executed').length, 24);
  assert.equal(report.records.filter(row => row.refused).length, 8);
  report.status = 'passed';
} catch (error) { report.status = 'failed'; report.failure = error.message; throw error; }
finally { checkpoint(); console.log('PSC1_GENERATED_IO_MAPPINGS: ' + JSON.stringify({
  status: report.status, requests: report.requests.length,
  executed: report.records.filter(row => row.runtime === 'executed').length,
  refused: report.records.filter(row => row.refused).length, failure: report.failure })); }
