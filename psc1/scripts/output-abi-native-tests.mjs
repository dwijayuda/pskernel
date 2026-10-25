// Native reference qualification of the existing unified compiler's opt-in IO
// request. This is not a generated G1/G2/G3 or package qualification.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import { pathToFileURL } from 'node:url';
import { compilerSourceClosureDigest, runIndependentChecker } from '../host-tools/compiler-host-protocol.mjs';
import { createLosslessSourceTool, createSourceOwnershipTool, createCheckedSourceConverter } from '../host-tools/source-refactoring.mjs';
import { applicationFixtures, executeApplication } from './output-abi-applications.mjs';
import { boundedRun } from '../host-tools/generated-target-tools.mjs';
const hash = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const file = name => path.resolve('.lake/build/bin/' + name);
const lexer = file('psc1_lossless_source'), executable = file('psc1_output_abi_probe');
const checker = file('psc1_independent_checker'), helper = file('psc1_source_ownership');
const lexical = createLosslessSourceTool({ executable: lexer, sha256: hash(fs.readFileSync(lexer)) });
const ownership = createSourceOwnershipTool({
  lexicalTool: lexical, executable: helper, sha256: hash(fs.readFileSync(helper)),
  checkerExecutable: checker, checkerSha256: hash(fs.readFileSync(checker)),
});
const work = fs.mkdtempSync(path.join(os.tmpdir(), 'psc1-output-abi-'));
fs.writeFileSync(path.join(work, 'package.json'), '{"type":"module"}\n');
const records = [];
const requestInventory = [];
let negatives = 0;
function native(target, request) {
  const input = path.join(work, 'request.json'), output = path.join(work, 'response.json');
  fs.writeFileSync(input, JSON.stringify(request)); fs.rmSync(output, { force: true });
  const result = boundedRun('prlimit', ['--as=4294967296', '--stack=8388608', '--',
    executable, target, input, output], { timeoutMs: 240000, timeoutPolicy: 'standard-240s',
    env: { ...process.env, LEAN_MAIN_USE_THREAD: '0', LEAN_NUM_THREADS: '0', LEAN_STACK_SIZE_KB: '8192' } });
  assert.equal(result.error, null, result.stderr);
  assert.equal(result.status, 0, result.stderr);
  const candidate = JSON.parse(fs.readFileSync(output, 'utf8'));
  requestInventory.push({ target, request, candidateSha256: hash(JSON.stringify(candidate)),
    status: candidate.status, protocol: candidate.protocol, outputAbi: candidate.outputAbi ?? null });
  return candidate;
}
try {
  for (const grammar of ['lean', 'ps']) for (const assurance of ['checked', 'ordinary-checked']) {
    const text = grammar === 'lean'
      ? 'def run (input : String) (dispatch : String -> String) : String := dispatch input\n'
      : 'def run(input : String, dispatch : String -> String) : String := dispatch(input)\n';
    const sources = [{ module: 'Entry', kind: grammar, text }];
    const digest = compilerSourceClosureDigest(sources), requestId = grammar + '-' + assurance;
    const scalar = ['psc1-compiler-service/1', requestId, digest, grammar, assurance, 'Entry',
      sources.map(source => [source.module, source.text])];
    const snapshots = sources.map(source => lexical.capture({
      module: source.module, grammar, bytes: Buffer.from(source.text),
    }));
    const index = ownership.analyze({ snapshots, entry: 'Entry', assurance });
    const legacy = native('js', scalar);
    assert.equal(legacy.status, 'refused');
    assert.equal(legacy.phase, 'public-api'); negatives++;
    const request = ['psc1-compiler-service/2', ...scalar.slice(1), 'io-dispatcher'];
    const candidate = native('js', request);
    assert.equal(candidate.status, 'candidate', JSON.stringify(candidate));
    assert.equal(candidate.protocol, 'psc1-compiler-service/2');
    assert.equal(candidate.outputAbi, 'io-dispatcher');
    assert.equal(candidate.target, 'js');
    assert.equal(candidate.requestId, requestId);
    assert.equal(candidate.sourceClosureDigest, digest);
    assert.equal(candidate.admission, 'not-run');
    assert.equal(candidate.candidateOnly, true);
    assert.equal(hash(candidate.admissionRequest.admissions), index.admissionsSha256);
    assert.equal(hash(JSON.stringify(candidate.originalIr)), index.originalIrSha256);
    assert.equal(candidate.sourceDeclarations, index.sourceCoreDeclarations);
    assert.equal(candidate.logicalDeclarations, index.logicalCoreDeclarations);
    assert.deepEqual(candidate.partialNames, index.partialNames);
    const independent = runIndependentChecker(checker, candidate.admissionRequest.admissions);
    assert.equal(independent.leanVersion, '4.35.0');
    const modulePath = path.join(work, grammar + '-' + assurance + '.mjs');
    fs.writeFileSync(modulePath, candidate.source);
    const api = await import(pathToFileURL(modulePath).href);
    assert.deepEqual(Object.keys(api), ['run']);
    assert.equal(api.run('λ🙂', value => 'ok:' + value), 'ok:λ🙂');
    const trap = new Error('opaque-dispatcher-trap');
    assert.throws(() => api.run('x', () => { throw trap; }), error => error === trap);
    assert.throws(() => api.run('x', 0), TypeError);
    const unsupported = native('wasm-core', request);
    assert.equal(unsupported.status, 'refused');
    assert.equal(unsupported.code, 'PSC1_IO_DISPATCHER_ABI_TARGET_UNSUPPORTED'); negatives++;
    for (const change of [
      wire => { wire[7] = 'arbitrary-callback'; },
      wire => { wire[7] = {}; },
      wire => { wire[4] = 'verified'; },
      wire => { wire.push('extra'); },
      wire => { wire[0] = 'psc1-compiler-service/1'; },
    ]) {
      const bad = structuredClone(request); change(bad);
      assert.equal(native('js', bad).status, 'refused'); negatives++;
    }
    records.push({ grammar, assurance, sourceClosureDigest: digest,
      admissionsSha256: index.admissionsSha256, originalIrSha256: index.originalIrSha256,
      sourceSha256: hash(candidate.source), independentAdmission: true,
      strictIr: true, runtime: 'executed', outputAbi: candidate.outputAbi });
  }
  const scalarSources = [{ module: 'Entry', kind: 'lean', text: 'def answer : Nat := 42\n' }];
  const ordinaryScalar = ['psc1-compiler-service/1', 'scalar-preserved',
    compilerSourceClosureDigest(scalarSources), 'lean', 'checked', 'Entry',
    scalarSources.map(source => [source.module, source.text])];
  const scalarCandidate = native('js', ordinaryScalar);
  assert.equal(scalarCandidate.status, 'candidate');
  assert.equal(scalarCandidate.protocol, 'psc1-compiler-service/1');
  assert.equal(Object.hasOwn(scalarCandidate, 'outputAbi'), false);
  const noDispatcher = ['psc1-compiler-service/2', ...ordinaryScalar.slice(1), 'io-dispatcher'];
  assert.equal(native('js', noDispatcher).code, 'PSC1_IO_DISPATCHER_PARAMETER_REQUIRED'); negatives++;
  const invalid = ['psc1-compiler-service/2', 'invalid-body', 'invalid-body', 'lean', 'checked',
    'Entry', [['Entry', 'def bad : Nat := true\n']], 'io-dispatcher'];
  assert.equal(native('js', invalid).status, 'refused'); negatives++;
  const applications = [];
  const converter = createCheckedSourceConverter({ ownershipTool: ownership });
  const toPs = (sources, entry) => {
    const snapshots = sources.map(source => lexical.capture({
      module: source.module, grammar: 'lean', bytes: Buffer.from(source.text),
    }));
    const index = ownership.analyze({ snapshots, entry, assurance: 'ordinary-checked' });
    const report = converter.convert({ index, snapshots, targetGrammar: 'ps', commentPolicy: 'owner-notes' });
    assert.equal(report.admissionsSha256, index.admissionsSha256);
    assert.equal(report.originalIrSha256, index.originalIrSha256);
    return sources.map(source => ({ module: source.module, kind: 'ps',
      text: new TextDecoder('utf-8', { fatal: true }).decode(converter.readCandidate(report, source.module)) }));
  };
  for (const fixture of applicationFixtures(toPs)) {
    const snapshots = fixture.sources.map(source => lexical.capture({
      module: source.module, grammar: fixture.grammar, bytes: Buffer.from(source.text),
    }));
    const index = ownership.analyze({ snapshots, entry: fixture.entry, assurance: 'ordinary-checked' });
    const digest = compilerSourceClosureDigest(fixture.sources);
    const request = ['psc1-compiler-service/2', fixture.id, digest, fixture.grammar,
      'ordinary-checked', fixture.entry, fixture.sources.map(source => [source.module, source.text]),
      'io-dispatcher'];
    const candidate = native('js', request);
    assert.equal(candidate.status, 'candidate', JSON.stringify(candidate));
    assert.equal(candidate.outputAbi, 'io-dispatcher');
    assert.equal(hash(candidate.admissionRequest.admissions), index.admissionsSha256);
    assert.equal(hash(JSON.stringify(candidate.originalIr)), index.originalIrSha256);
    assert.equal(runIndependentChecker(checker, candidate.admissionRequest.admissions).leanVersion, '4.35.0');
    const modulePath = path.join(work, fixture.id + '.mjs');
    fs.writeFileSync(modulePath, candidate.source);
    const cases = executeApplication(fixture, modulePath, path.join(work, fixture.id));
    applications.push({ id: fixture.id, application: fixture.application, grammar: fixture.grammar, modules: fixture.sources.length,
      sourceClosureDigest: digest, admissionsSha256: index.admissionsSha256,
      originalIrSha256: index.originalIrSha256, sourceSha256: hash(candidate.source),
      contractSha256: fixture.contractSha256, cases });
    console.log('PSC1_OUTPUT_ABI_NATIVE_APPLICATION: ' + JSON.stringify(applications.at(-1)));
  }
  fs.mkdirSync('dist/output-abi', { recursive: true });
  fs.writeFileSync('dist/output-abi/native-reference.json', JSON.stringify({
    schema: 'psc1-output-abi-native-reference/1', testedCommit: process.env.GITHUB_SHA,
    records, requestInventory, applications, negatives, generatedSelfHosting: 'not-run', publication: false,
  }, null, 2) + '\n');
  console.log('PSC1_OUTPUT_ABI_NATIVE: PASS', JSON.stringify({ cases: records.length, negatives }));
} finally { fs.rmSync(work, { recursive: true, force: true }); }
