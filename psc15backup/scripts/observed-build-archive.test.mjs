import assert from 'node:assert/strict';
import { test } from 'node:test';
import { artifactKey, canonicalArtifact, canonicalBytes } from './artifact-evidence.mjs';
import { createCheckedBuildGraph } from './checked-build-evidence.mjs';
import { packObservedBuildArchive, verifyObservedBuildArchive, observedBuildArchiveLimits } from './observed-build-archive.mjs';

function fixture() {
  const built = createCheckedBuildGraph({ sourceKind: 'lean', sources: ['def seven : Nat := 7'],
    admissions: '{"admissions":[],"format":"proofscript-checked-admissions","version":2}',
    typeScript: 'export const seven: bigint = 7n;', javaScript: Buffer.from('export const seven = 7n;'),
    declarations: Buffer.from('export declare const seven: bigint;'), sourceMap: Buffer.from('{}'),
    compilerBytes: Buffer.from('fictional compiler'), compilerKind: 'test-double', typeScriptCompilerBytes: Buffer.from('fictional tsc'),
    provider: { profile: 'test-profile' }, providerSecurity: { profile: 'test-security' }, kernelContract: { id: 'test-kernel' },
    hostSources: [{ path: 'test.mjs', bytes: Buffer.from('test implementation') }], runtime: { version: 'test' }, outputStem: 'seven' });
  const allowedAssumptions = [...new Set(built.graph.entries.filter(entry => entry.identity.domain === 'pass-definition')
    .flatMap(entry => entry.canonicalValue.assumptionIds))];
  return { built, policy: { expectedGraphId: built.identity, allowedAssumptions } };
}
function editArchive(bytes, mutate) {
  const value = JSON.parse(bytes); mutate(value); return canonicalBytes(value);
}

test('observed build archive retains all bytes and freshly checks pass identities and assumption policy', async () => {
  const { built, policy } = fixture(), archive = packObservedBuildArchive(built);
  built.artifacts.clear(); // Verification has no original builder, checkout or resolver.
  const result = await verifyObservedBuildArchive(archive.bytes, policy);
  assert.equal(result.kind, 'accepted', result.reason);
  assert.equal(result.artifactCount, built.graph.entries.length + 1);
  assert.equal(result.executions.length, 3);
  assert.equal(result.acceptanceScope, 'observed-artifact-integrity-only');
  for (const key of ['semanticClaimsVerified', 'preservationVerified', 'releaseAccepted', 'fullInputClosureEstablished']) assert.equal(result[key], false);
  assert.match((await verifyObservedBuildArchive(archive.bytes, { ...policy, allowedAssumptions: [] })).reason, /ASSUMPTION_DENIED/);
  assert.match((await verifyObservedBuildArchive(archive.bytes, { ...policy, expectedGraphId: { ...policy.expectedGraphId, digest: '0'.repeat(64) } })).reason, /GRAPH_ID/);
});

test('observed build archive rejects missing/corrupt/duplicate/extra bytes and resource exhaustion', async () => {
  const { built, policy } = fixture(), archive = packObservedBuildArchive(built);
  for (const mutate of [
    value => value.artifacts.pop(),
    value => { value.artifacts[0].data = Buffer.from('tampered').toString('base64'); },
    value => value.artifacts.splice(1, 0, value.artifacts[0]),
    value => {
      const extra = canonicalArtifact({ extra: true }, 'extra', 'extra/1');
      value.artifacts.push({ identity: extra.identity, data: extra.bytes.toString('base64') });
      value.artifacts.sort((a, b) => artifactKey(a.identity).localeCompare(artifactKey(b.identity)));
    },
  ]) assert.equal((await verifyObservedBuildArchive(editArchive(archive.bytes, mutate), policy)).kind, 'rejectedInvalid');
  for (const resourceLimits of [{ maxArchiveBytes: 1 }, { maxArtifacts: 1 }, { maxTotalBytes: 1 }, { maxArtifactBytes: 1 }]) {
    assert.equal((await verifyObservedBuildArchive(archive.bytes, { ...policy, resourceLimits })).kind, 'resourceExhausted');
    assert.throws(() => packObservedBuildArchive(built, resourceLimits), /EXHAUSTED/);
  }
});

test('independently pinned graphs still reject missing structured dependency references and altered action claims', async () => {
  const { built } = fixture();
  const implementation = built.graph.entries.find(entry => entry.identity.contract === 'psc-hosted-compiler-implementation/1');
  const missing = canonicalArtifact({ missing: true }, 'fixture', 'fixture/1');
  implementation.canonicalValue.compiler = missing.identity;
  const changed = canonicalArtifact(implementation.canonicalValue, implementation.identity.domain, implementation.identity.contract);
  implementation.identity = changed.identity; built.artifacts.set(artifactKey(changed.identity), changed.bytes);
  const graph = canonicalArtifact(built.graph, 'build-graph', 'psc-observed-build-graph/1');
  assert.throws(() => packObservedBuildArchive({ ...graph, artifacts: built.artifacts }), /UNLISTED_ARTIFACT_REFERENCE/);

  const f = fixture(), archive = JSON.parse(packObservedBuildArchive(f.built).bytes);
  const graphItem = archive.artifacts.find(item => artifactKey(item.identity) === artifactKey(f.built.identity));
  const graphValue = JSON.parse(Buffer.from(graphItem.data, 'base64'));
  const recordEntry = graphValue.entries.find(entry => entry.identity.contract === 'psc-pass-execution/1');
  const oldKey = artifactKey(recordEntry.identity), oldId = recordEntry.identity;
  recordEntry.canonicalValue.action.parameters.sourceCount = 999;
  const record = canonicalArtifact(recordEntry.canonicalValue, oldId.domain, oldId.contract);
  recordEntry.identity = record.identity;
  graphValue.executions = graphValue.executions.map(id => artifactKey(id) === oldKey ? record.identity : id);
  const recordItem = archive.artifacts.find(item => artifactKey(item.identity) === oldKey);
  recordItem.identity = record.identity; recordItem.data = record.bytes.toString('base64');
  const newGraph = canonicalArtifact(graphValue, graphItem.identity.domain, graphItem.identity.contract);
  graphItem.identity = newGraph.identity; graphItem.data = newGraph.bytes.toString('base64'); archive.graphId = newGraph.identity;
  archive.artifacts.sort((a, b) => artifactKey(a.identity).localeCompare(artifactKey(b.identity)));
  const result = await verifyObservedBuildArchive(canonicalBytes(archive), { ...f.policy, expectedGraphId: newGraph.identity });
  assert.match(result.reason, /ACTION_ID/);
});

test('archive resource policy is explicit data and preflight retains exact historical bytes', async () => {
  const { built, policy } = fixture();
  const defaults = observedBuildArchiveLimits();
  assert.equal(defaults.maxTotalBytes, 192 * 1024 * 1024);
  assert.equal(defaults.maxArtifactBytes, 128 * 1024 * 1024);
  assert.equal(defaults.maxArchiveBytes, 256 * 1024 * 1024);
  let accessed = false;
  const getter = Object.defineProperty({}, 'maxTotalBytes', { enumerable: true, get() { accessed = true; return 1; } });
  for (const invalid of [null, [], getter, { unknown: 1 }, { maxTotalBytes: -1 }, { maxArtifacts: 1.5 }, { [Symbol()]: 1 }])
    assert.throws(() => observedBuildArchiveLimits(invalid), /LIMIT_POLICY/);
  assert.equal(accessed, false);
  const ids = [built.identity, ...built.graph.entries.map(entry => entry.identity)];
  const total = ids.reduce((sum, id) => sum + id.byteLength, 0);
  const archive = packObservedBuildArchive(built, { maxTotalBytes: total });
  const expected = canonicalBytes({ contract: 'psc-observed-build-archive/1', graphId: built.identity,
    artifacts: ids.map(identity => ({ identity, data: (artifactKey(identity) === artifactKey(built.identity) ?
      built.bytes : built.artifacts.get(artifactKey(identity))).toString('base64') }))
      .sort((a, b) => artifactKey(a.identity) < artifactKey(b.identity) ? -1 : 1) });
  assert.deepEqual(archive.bytes, expected);
  assert.throws(() => packObservedBuildArchive(built, { maxTotalBytes: total - 1 }),
    error => error.kind === 'resourceExhausted' && error.resource === 'maxTotalBytes' &&
      error.limit === total - 1 && error.observed === total && !!error.artifact);
  assert.throws(() => packObservedBuildArchive(built, { maxArchiveBytes: archive.bytes.length - 1 }),
    error => error.kind === 'resourceExhausted' && error.resource === 'maxArchiveBytes' &&
      error.observed === archive.bytes.length);
  assert.deepEqual(packObservedBuildArchive(built, { maxArchiveBytes: archive.bytes.length }).bytes, archive.bytes);
  assert.equal((await verifyObservedBuildArchive(archive.bytes, { ...policy, resourceLimits: { maxTotalBytes: total - 1 } })).kind,
    'resourceExhausted');
});
