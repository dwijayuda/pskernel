// Generated JS/Rust protocol transport + external official checker, not self-hosting.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { createCompilerHostSession } from '../host-tools/compiler-host-protocol.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const native = process.env.PSC1_NATIVE || path.join(root, '.lake/build/bin/psc1');
const checker = process.env.PSC1_INDEPENDENT_CHECKER || path.join(root, '.lake/build/bin/psc1_independent_checker');
const work = fs.mkdtempSync(path.join(os.tmpdir(), 'psc1-compiler-protocol-'));
const evidence = path.join(root, 'dist/scoped-correctness/compiler-host-protocol');
const env = { ...process.env, PSC1_HOST_TOOLS: path.join(root, 'host-tools/artifacts.mjs') };
const records = [];
const sha256 = text => crypto.createHash('sha256').update(text).digest('hex');
function command(program, args, options = {}) {
  const result = spawnSync(program, args, { env, encoding: 'utf8',
    timeout: 120000, maxBuffer: 32 * 1024 * 1024, ...options });
  assert.equal(result.error, undefined, result.error?.message);
  assert.equal(result.status, 0, result.stdout + result.stderr);
  return result.stdout;
}
try {
  fs.mkdirSync(evidence, { recursive: true });
  fs.writeFileSync(path.join(work, 'package.json'), '{"type":"module"}\n');
  const fixture = path.join(work, 'Payload.lean');
  const text = 'def answer : Nat := 42\n';
  fs.writeFileSync(fixture, text);
  // Stage 0 supplies this tiny graph. The generated code below is the transport,
  // not a purported generated frontend, eraser, compiler or fixed-point result.
  const admissions = command(native, ['admissions', fixture]);
  const input = path.join(root, 'packages/bridge/src/Ps/Bridge/CompilerHost.lean');
  for (const target of ['js', 'rust']) {
    const output = path.join(work, 'protocol-' + target + (target === 'js' ? '.js' : '.rs'));
    command(native, ['build', input, '--target', target, '--out', output]);
    let encode, matches;
    if (target === 'js') {
      const api = await import(pathToFileURL(fs.realpathSync(output)).href);
      encode = (...args) => api.psCompilerHostAdmissionRequest(...args);
      matches = (...args) => api.psCompilerHostReceiptMatches(...args);
    } else {
      const crate = path.join(work, 'rust-consumer');
      fs.cpSync(fs.realpathSync(output.replace(/\.rs$/, '.cargo')), crate, { recursive: true });
      fs.mkdirSync(path.join(crate, 'src/bin'), { recursive: true });
      fs.writeFileSync(path.join(crate, 'src/bin/protocol_consumer.rs'), [
        'use psc1_generated::*;',
        'fn main() { let a: Vec<String> = std::env::args().skip(1).collect();',
        'if a[0] == "request" { println!("{}", psCompilerHostAdmissionRequest(a[1].clone(),a[2].clone(),a[3].clone(),a[4].clone())); }',
        'else { println!("{}", psCompilerHostReceiptMatches(a[1].clone(),a[2].clone(),a[3].clone(),a[4].clone(),a[5].clone(),a[6].clone(),a[7].clone(),a[8].clone(),a[9].clone(),a[10] == "true")); } }'
      ].join('\n') + '\n');
      const cargoTarget = path.join(work, 'rust-target');
      const rustEnv = { ...env, CARGO_TARGET_DIR: cargoTarget };
      command('cargo', ['build', '--locked', '--manifest-path', path.join(crate, 'Cargo.toml'),
        '--bin', 'protocol_consumer'], { env: rustEnv });
      const binary = path.join(cargoTarget, 'debug/protocol_consumer');
      encode = (...args) => command(binary, ['request', ...args]).trimEnd();
      matches = (...args) => command(binary, ['receipt', ...args.map(String)]).trim() === 'true';
    }
    const make = graph => createCompilerHostSession({ requestId: 'request-' + target,
      target, sources: [{ module: 'Payload', kind: 'lean', text }],
      canonicalAdmissions: graph, checkerExecutable: checker });
    const session = make(admissions), expected = session.request;
    const wire = encode(expected.requestId, expected.sourceClosureDigest, target, admissions);
    const parsed = JSON.parse(wire);
    assert.equal(parsed.admissions, admissions);
    assert.equal(parsed.protocol, 'psc1-compiler-host/1');
    for (const [field, value] of [['requestId', 'stale'], ['sourceClosureDigest', 'wrong'],
      ['target', target === 'js' ? 'rust' : 'js'], ['admissions', admissions + '\n']]) {
      assert.throws(() => session.admit(JSON.stringify({ ...parsed, [field]: value })),
        /PSC1_HOST_REQUEST_MISMATCH/);
    }
    assert.throws(() => session.admit(JSON.stringify({ ...parsed, accepted: true })),
      /PSC1_HOST_WIRE_FIELDS/);
    const receipt = session.admit(wire);
    assert.equal(receipt.accepted, true);
    assert.equal(receipt.behaviorallyVerified, false);
    assert.equal(receipt.admissionsDigest, sha256(admissions));
    const args = [expected.requestId, expected.sourceClosureDigest, expected.admissionsDigest, target,
      receipt.requestId, receipt.sourceClosureDigest, receipt.admissionsDigest, receipt.target,
      receipt.checkerCommit, receipt.accepted];
    assert.equal(matches(...args), true);
    for (const index of [4, 5, 6, 7, 8]) {
      const stale = [...args]; stale[index] = 'stale';
      assert.equal(matches(...stale), false);
    }
    const rejected = [...args]; rejected[9] = false;
    assert.equal(matches(...rejected), false);
    assert.throws(() => session.admit(wire), /PSC1_HOST_SESSION_CONSUMED/);
    const invalid = make('{"schema":"invalid-admissions"}');
    const invalidWire = encode(invalid.request.requestId, invalid.request.sourceClosureDigest,
      target, '{"schema":"invalid-admissions"}');
    assert.throws(() => invalid.admit(invalidWire), /PSC1_CHECKER_REJECTED/);
    assert.throws(() => invalid.admit(invalidWire), /PSC1_HOST_SESSION_CONSUMED/);
    records.push({ target, transportExecution: 'passed', independentAdmission: 'passed',
      negativeCorrelationCases: 5, negativeContinuationCases: 6, exactGraphMismatch: 'refused',
      invalidAdmission: 'refused', generatedArtifactSha256: sha256(fs.readFileSync(output)),
      selfHosting: false });
    fs.copyFileSync(output, path.join(evidence, path.basename(output)));
  }
  fs.writeFileSync(path.join(evidence, 'results.json'), JSON.stringify({
    schema: 'psc1-generated-compiler-protocol-slice/1', commit: process.env.GITHUB_SHA || null,
    logicalCheckerCommit: 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc',
    scope: 'generated transport only; staged admission graph comes from native stage 0',
    sourceClosureSelfCompilation: false, fixedPoint: false, records
  }, null, 2) + '\n');
  console.log('PSC1_COMPILER_PROTOCOL_TRANSPORT: JS/Rust generated consumers + external checker passed');
} finally {
  fs.rmSync(work, { recursive: true, force: true });
}
