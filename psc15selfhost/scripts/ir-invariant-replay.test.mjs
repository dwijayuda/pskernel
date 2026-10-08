import assert from 'node:assert/strict';
import { test } from 'node:test';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { artifactId, canonicalBytes } from './artifact-evidence.mjs';
import { replayClosedIrArtifact, replayIrLinkArtifact } from './ir-invariant-replay.mjs';
import { irLinkEncodingContract, irLinkHostIdentity } from './ir-link-artifact.mjs';
import { decodeIrArtifact } from './ir-artifact.mjs';
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
      .filter(entry => entry.identity.domain === 'pass-definition')
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

const nat = ['primitive', 'nat'];
const linkModule = (imports, declarations) => ['psc-runtime-ir-json/1', imports, [], [], declarations];
const providerIr = linkModule([], [['value', [], [], nat, ['literal', ['natural', '42']]]]);
const consumerIr = linkModule([['external', 'provider', 'value', nat]],
  [['answer', [], [], nat, ['var', 'external']]]);
const linkFixture = () => [irLinkEncodingContract, ['javascript', []], [],
  [['consumer', ['answer'], [], structuredClone(consumerIr)],
   ['provider', ['value'], [], structuredClone(providerIr)]]];
const linkSubject = value => {
  const bytes = canonicalBytes(value);
  return { bytes, identity: artifactId(bytes, 'ir-link', irLinkEncodingContract) };
};
const linkConfiguration = { ...configuration,
  linkPolicy: { target: 'javascript', allowedCapabilities: [], hostInterfaceIds: [] } };

test('linked replay decodes exact modules and derives provider signatures from checked bodies', async () => {
  const value = linkFixture(), artifact = linkSubject(value);
  const output = spawnSync(binary, ['--roundtrip-link'], { cwd, input: artifact.bytes,
    timeout: 30000, maxBuffer: 32 * 1024 * 1024 });
  assert.equal(output.status, 0, output.stdout?.toString() + output.stderr?.toString());
  assert.deepEqual(output.stdout, artifact.bytes);
  const replay = await replayIrLinkArtifact(artifact, linkConfiguration);
  assert.equal(replay.kind, 'accepted', JSON.stringify(replay));
  assert.equal(replay.validationScope, 'linked-ir-invariants-only');
  assert.equal(replay.modules.length, 2);
  assert.equal(replay.authority, 'none');
  assert.equal(replay.preservationVerified, false);
  for (const mutate of [
    value => { value[3][1][3][4][0][4] = ['literal', ['bool', true]]; },
    value => { value[3][1][1] = ['missing']; },
    value => { value[3].pop(); },
    value => { value[3].push(structuredClone(value[3][0])); },
    value => { value[3][0][3][1][0][3] = ['primitive', 'bool']; },
    value => { value[3][1][3][1].push(['cycle', 'consumer', 'answer', nat]); },
  ]) {
    const changed = linkFixture(); mutate(changed);
    assert.equal((await replayIrLinkArtifact(linkSubject(changed), linkConfiguration)).kind, 'rejectedInvalid');
  }
  assert.equal((await replayIrLinkArtifact(artifact, { ...linkConfiguration,
    linkPolicy: { ...linkConfiguration.linkPolicy, target: 'wasm' } })).kind, 'rejectedInvalid');
  assert.equal((await replayIrLinkArtifact(artifact, { ...linkConfiguration,
    limits: { maxBytes: 1 } })).kind, 'resourceExhausted');
});

test('host assumptions require exact consumer-pinned contracts and transitive capabilities', async () => {
  const host = ['host', 'psc-runtime-semantics/1', 'psc-runtime-values/1', ['javascript'], ['console'],
    ['host', 'fixture-host-implementation'], [], [], [['value', nat]]];
  const consumer = linkModule([['external', 'host', 'value', nat]], consumerIr[4]);
  const value = [irLinkEncodingContract, ['javascript', ['console']], [host],
    [['consumer', ['answer'], ['console'], consumer]]];
  const selected = { ...configuration, linkPolicy: { target: 'javascript',
    allowedCapabilities: ['console'], hostInterfaceIds: [irLinkHostIdentity(host)] } };
  assert.equal((await replayIrLinkArtifact(linkSubject(value), selected)).kind, 'accepted');
  const denied = { ...selected, linkPolicy: { ...selected.linkPolicy, hostInterfaceIds: [] } };
  assert.equal((await replayIrLinkArtifact(linkSubject(value), denied)).kind, 'rejectedInvalid');
  const changed = structuredClone(value); changed[2][0][8][0][1] = ['primitive', 'bool'];
  assert.equal((await replayIrLinkArtifact(linkSubject(changed), selected)).kind, 'rejectedInvalid');
  const unpropagated = structuredClone(value); unpropagated[3][0][2] = [];
  assert.equal((await replayIrLinkArtifact(linkSubject(unpropagated), selected)).kind, 'rejectedInvalid');
  const origin = structuredClone(value); origin[2][0][5] = ['linked'];
  const forgedPolicy = { ...selected, linkPolicy: { ...selected.linkPolicy,
    hostInterfaceIds: [irLinkHostIdentity(origin[2][0])] } };
  assert.equal((await replayIrLinkArtifact(linkSubject(origin), forgedPolicy)).kind, 'rejectedInvalid');
});

test('linked archive replay covers every exact retained IR subject and rejects rehashed dependencies', async () => {
  const encoded = canonicalBytes(consumerIr).toString();
  const built = createCheckedBuildGraph({ sourceKind: 'lean', sources: ['fixture provenance only'],
    admissions: '{"admissions":[],"format":"proofscript-checked-admissions","version":2}',
    typeScript: 'export const answer = external;\n',
    irStages: { runtimeIr: encoded, verifiedIr: encoded },
    compilerBytes: Buffer.from('synthetic provenance'), compilerKind: 'fixture',
    provider: { profile: 'fixture' }, providerSecurity: { profile: 'fixture' },
    kernelContract: { id: 'fixture' }, hostSources: [], runtime: { implementation: 'fixture' } });
  const allowedAssumptions = [...new Set(built.graph.entries
    .filter(entry => entry.identity.domain === 'pass-definition')
    .flatMap(entry => entry.canonicalValue.assumptionIds))];
  const archive = packObservedBuildArchive(built).bytes;
  const options = { expectedGraphId: built.identity, allowedAssumptions };
  assert.equal((await verifyObservedBuildArchive(archive, { ...options, irValidation: configuration })).kind,
    'declinedUnsupported');
  const verify = context => verifyObservedBuildArchive(archive, { ...options,
    irLinkValidation: { artifacts: [linkSubject(context)], validator: linkConfiguration } });
  const accepted = await verify(linkFixture());
  assert.equal(accepted.kind, 'accepted', JSON.stringify(accepted));
  assert.equal(accepted.linkedIrInvariantsVerified, true);
  assert.equal(accepted.closedIrInvariantsVerified, false);
  assert.equal(accepted.preservationVerified, false);
  assert.equal(accepted.releaseAccepted, false);
  const bad = linkFixture(); bad[3][1][3][4][0][4] = ['var', 'unbound'];
  assert.equal((await verify(bad)).kind, 'rejectedInvalid');
  const missing = linkFixture(); missing[3].shift();
  const uncovered = await verify(missing);
  assert.equal(uncovered.kind, 'rejectedInvalid');
  assert.match(uncovered.reason, /SUBJECT_UNCOVERED/);
});

test('runtime IR numeric spellings cannot hide trailing line terminators', () => {
  for (const value of ['1\n', '-1\n', '0\r\n']) {
    for (const tag of ['natural', 'integer']) {
      const module = structuredClone(providerIr);
      module[4][0][4] = ['literal', [tag, value]];
      assert.throws(() => decodeIrArtifact(canonicalBytes(module)), /SCHEMA/);
    }
  }
});
