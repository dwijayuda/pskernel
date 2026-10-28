// Linux test preparation only. The native compiler produces an independently
// checked oracle before it is removed from the modular execution phase.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import { readQualifiedArtifact, sha256 as sha } from './kernel435-qualified-artifact.mjs';
import { boundedRun } from '../host-tools/generated-target-tools.mjs';
import { readOwnedCompilerSources } from '../host-tools/compiler-source-inputs.mjs';
import {
  compilerSourceClosureDigest,
  runIndependentChecker,
} from '../host-tools/compiler-host-protocol.mjs';
import { readManifestBytes, verify } from '../host-tools/executable/verify.mjs';

const out = path.resolve('dist/modular-checked');
fs.mkdirSync(out, { recursive: true });
const input = JSON.parse(fs.readFileSync('scripts/modular-checked-input.json'));
assert.equal(input.schema, 'psc1-modular-checked-input/1');
const sources = readOwnedCompilerSources('Ps.CompilerUnified.Service').map((row) => ({
  module: row.module,
  kind: 'lean',
  text: row.text,
}));
assert.equal(compilerSourceClosureDigest(sources), input.compilerSourceClosureDigest);
const archive = await readQualifiedArtifact(input.artifact, path.join(out, 'input'));
const graphRoot = path.join(archive, 'compiler/candidate');
const manifestFile = path.join(archive, 'compiler/manifest.json');
const manifest = verify(graphRoot, readManifestBytes(manifestFile), input.manifestSha256);
assert.equal(manifest.sourceClosureDigest, input.compilerSourceClosureDigest);
const native = path.resolve('.lake/build/bin/psc1_output_abi_probe');
const checker = path.resolve('.lake/build/bin/psc1_independent_checker');
const nativeHash = sha(fs.readFileSync(native)),
  checkerHash = sha(fs.readFileSync(checker));
const reference = JSON.parse(fs.readFileSync('dist/output-abi/native-reference.json'));
assert.equal(reference.applications.length, 4);
const records = [];
for (const fixture of reference.applications) {
  const captured = reference.requestInventory.find((row) => row.request[1] === fixture.id);
  assert.ok(captured);
  for (const target of ['js', 'ts']) {
    const id = fixture.id + '-' + target;
    const requestFile = path.join(out, id + '.request.json');
    const responseFile = path.join(out, id + '.candidate.json');
    fs.writeFileSync(requestFile, JSON.stringify(captured.request), { flag: 'wx' });
    const run = boundedRun(
      'prlimit',
      ['--as=4294967296', '--stack=8388608', '--', native, target, requestFile, responseFile],
      {
        timeoutMs: 240000,
        timeoutPolicy: 'standard-240s',
        logDirectory: path.join(out, 'native-processes', id),
        env: {
          ...process.env,
          LEAN_MAIN_USE_THREAD: '0',
          LEAN_NUM_THREADS: '0',
          LEAN_STACK_SIZE_KB: '8192',
        },
      },
    );
    assert.equal(run.error, null, run.stderr);
    assert.equal(run.status, 0, run.stderr);
    assert.equal(sha(fs.readFileSync(native)), nativeHash);
    assert.equal(sha(fs.readFileSync(checker)), checkerHash);
    const bytes = fs.readFileSync(responseFile),
      candidate = JSON.parse(bytes);
    assert.equal(candidate.status, 'candidate');
    assert.equal(candidate.target, target);
    assert.equal(candidate.outputAbi, 'io-dispatcher');
    assert.equal(
      runIndependentChecker(checker, candidate.admissionRequest.admissions).leanVersion,
      '4.35.0',
    );
    assert.equal(sha(candidate.admissionRequest.admissions), fixture.admissionsSha256);
    assert.equal(sha(JSON.stringify(candidate.originalIr)), fixture.originalIrSha256);
    if (target === 'js') assert.equal(sha(candidate.source), fixture.sourceSha256);
    records.push({
      id: fixture.id,
      target,
      request: captured.request,
      candidateSha256: sha(JSON.stringify(candidate)),
      admissionsSha256: sha(candidate.admissionRequest.admissions),
      originalIrSha256: sha(JSON.stringify(candidate.originalIr)),
      specializedIrSha256: sha(JSON.stringify(candidate.specializedIr)),
      sourceSha256: sha(candidate.source),
    });
  }
}
fs.writeFileSync(
  path.join(out, 'prepared.json'),
  JSON.stringify(
    {
      schema: 'psc1-modular-application-preparation/1',
      testedCommit: process.env.GITHUB_SHA,
      input,
      graphRoot,
      manifestFile,
      manifestSha256: input.manifestSha256,
      reference,
      records,
    },
    null,
    2,
  ) + '\n',
);
console.log(
  'PSC1_MODULAR_APPLICATION_PREPARED ' +
    JSON.stringify({ applications: 4, records: records.length }),
);
