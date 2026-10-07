import assert from 'node:assert/strict';
import { test } from 'node:test';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { artifactId, canonicalBytes } from './artifact-evidence.mjs';
import { replayClosedIrArtifact } from './ir-invariant-replay.mjs';
import { createCheckedBuildGraph } from './checked-build-evidence.mjs';
import { packObservedBuildArchive, verifyObservedBuildArchive } from './observed-build-archive.mjs';

const cwd = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const suffix = process.platform === 'win32' ? '.exe' : '';
const binary = path.join(cwd, '.lake/build/bin/pscv_ir_replay' + suffix);
const expectedBinaryId = artifactId(await readFile(binary), 'validator-executable', 'psc-closed-ir-invariant-replay/1');
const configuration = { binary, expectedBinaryId, cwd };
const subject = bytes => ({ bytes, identity: artifactId(bytes, 'verified-ir', 'psc-runtime-ir-json/1') });
function emitted(flag) {
  const output = spawnSync(path.join(cwd, '.lake/build/bin/pscv_ir_encoding_tests' + suffix),
    [flag], { cwd, encoding: 'utf8', timeout: 30000, maxBuffer: 32 * 1024 * 1024 });
  assert.equal(output.status, 0, output.error?.message ?? output.stderr);
  return Buffer.from(output.stdout.trim());
}
function roundtrip(bytes) {
  const output = spawnSync(binary, ['--roundtrip'], { cwd, input: bytes, timeout: 30000, maxBuffer: 32 * 1024 * 1024 });
  assert.equal(output.status, 0, output.stdout?.toString() + output.stderr?.toString());
  assert.deepEqual(output.stdout, bytes);
}

test('actual retained IR decodes canonically and strict validation distinguishes construction from valid IR', async () => {
  const raw = emitted('--raw');
  roundtrip(raw);
  assert.equal((await replayClosedIrArtifact(subject(raw), configuration)).kind, 'rejectedInvalid');
  for (const flag of ['--stages', '--js-stages', '--wasm-stages']) {
    const stages = JSON.parse(emitted(flag));
    for (const name of ['verifiedIr', 'specializedIr'].filter(key => stages[key] !== undefined)) {
      const bytes = Buffer.from(stages[name]);
      roundtrip(bytes);
      const replay = await replayClosedIrArtifact(subject(bytes), configuration);
      assert.equal(replay.kind, 'accepted', JSON.stringify(replay));
      assert.equal(replay.validationScope, 'closed-ir-invariants-only');
      assert.equal(replay.authority, 'none');
      assert.equal(replay.preservationVerified, false);
    }
  }
});

test('replay rejects fresh hashes of ill-typed IR and fails closed on limits, import context and validator identity', async () => {
  const valid = ['psc-runtime-ir-json/1', [], [], [], [
    ['answer', [], [], ['primitive', 'nat'], ['literal', ['natural', '42']]],
  ]];
  const bad = structuredClone(valid); bad[4][0][4] = ['literal', ['bool', true]];
  assert.equal((await replayClosedIrArtifact(subject(canonicalBytes(bad)), configuration)).kind, 'rejectedInvalid');
  const duplicate = structuredClone(valid); duplicate[4].push(duplicate[4][0]);
  assert.equal((await replayClosedIrArtifact(subject(canonicalBytes(duplicate)), configuration)).kind, 'rejectedInvalid');
  const external = structuredClone(valid); external[1].push(['external', 'pkg', 'external', ['primitive', 'nat']]);
  assert.equal((await replayClosedIrArtifact(subject(canonicalBytes(external)), configuration)).kind, 'declinedUnsupported');
  const bytes = canonicalBytes(valid);
  assert.equal((await replayClosedIrArtifact(subject(bytes), { ...configuration, limits: { maxBytes: 1 } })).kind, 'resourceExhausted');
  assert.equal((await replayClosedIrArtifact(subject(bytes), { ...configuration,
    expectedBinaryId: { ...expectedBinaryId, digest: '0'.repeat(64) } })).kind, 'infrastructureUnavailable');
  assert.equal((await replayClosedIrArtifact(subject(Buffer.concat([bytes, Buffer.from('\n')])), configuration)).kind, 'rejectedInvalid');
});

test('offline archive opt-in replays exact verified IR and rejects a fully rehashed invalid module', async () => {
  const stages = JSON.parse(emitted('--stages'));
  function build(irStages) {
    return createCheckedBuildGraph({ sourceKind: 'lean', sources: ['fixture provenance only'],
      admissions: '{"admissions":[],"format":"proofscript-checked-admissions","version":2}',
      typeScript: stages.typeScript, irStages, compilerBytes: Buffer.from('synthetic provenance'),
      compilerKind: 'fixture', provider: { profile: 'fixture' }, providerSecurity: { profile: 'fixture' },
      kernelContract: { id: 'fixture' }, hostSources: [], runtime: { implementation: 'fixture' } });
  }
  async function replay(built, strict) {
    const allowedAssumptions = [...new Set(built.graph.entries
      .filter(entry => entry.identity.contract === 'psc-pass-definition/1')
      .flatMap(entry => entry.canonicalValue.assumptionIds))];
    return verifyObservedBuildArchive(packObservedBuildArchive(built).bytes,
      { expectedGraphId: built.identity, allowedAssumptions, ...(strict ? { irValidation: configuration } : {}) });
  }
  const accepted = await replay(build(stages), true);
  assert.equal(accepted.kind, 'accepted', accepted.reason);
  assert.equal(accepted.closedIrInvariantsVerified, true);
  assert.equal(accepted.irInvariantReplays.length, 1);
  assert.equal(accepted.preservationVerified, false);
  assert.equal(accepted.releaseAccepted, false);
  const invalid = JSON.parse(stages.verifiedIr); invalid[4][0][4] = ['var', 'unbound'];
  const changed = canonicalBytes(invalid).toString();
  const forged = build({ ...stages, runtimeIr: changed, verifiedIr: changed });
  assert.equal((await replay(forged, false)).kind, 'accepted'); // Integrity alone has narrower meaning.
  const rejected = await replay(forged, true);
  assert.equal(rejected.kind, 'rejectedInvalid', JSON.stringify(rejected));
  assert.equal(rejected.closedIrInvariantsVerified, false);
});
