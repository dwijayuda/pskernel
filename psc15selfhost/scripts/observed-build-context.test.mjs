import { createBuildAction } from './build-context.mjs';
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { readFile } from 'node:fs/promises';
import { artifactKey, canonicalArtifact } from './artifact-evidence.mjs';
import { createCheckedBuildGraph } from './checked-build-evidence.mjs';
import { bindObservedBuildContext, verifyObservedContextProducts, verifyObservedActionBinding } from './observed-build-context.mjs';
import { packObservedBuildArchive, verifyObservedBuildArchive } from './observed-build-archive.mjs';
const backendRegistry = canonicalArtifact(JSON.parse(await readFile(new URL('../contracts/backends/BACKEND_REGISTRY_V1.json', import.meta.url))),
  'backend-registry', 'psc-backend-registry/1');
function fixture() {
  const observed = createCheckedBuildGraph({ sourceKind: 'lean', sources: ['def seven : Nat := 7'],
    admissions: '{"admissions":[],"format":"proofscript-checked-admissions","version":2}',
    typeScript: 'export const seven: bigint = 7n;', javaScript: Buffer.from('export const seven = 7n;'),
    declarations: Buffer.from('export declare const seven: bigint;'), sourceMap: Buffer.from('{}'),
    compilerBytes: Buffer.from('fixture compiler'), compilerKind: 'test-double', typeScriptCompilerBytes: Buffer.from('fixture tsc'),
    provider: { profile: 'test-profile' }, providerSecurity: { profile: 'test-security' }, kernelContract: { id: 'test-kernel' },
    hostSources: [{ path: 'test.mjs', bytes: Buffer.from('test implementation') }], runtime: { version: 'test' }, outputStem: 'seven' });
  const languageAuthority = canonicalArtifact({ languageEdition: 'test-edition' }, 'language-authority', 'psc-language-authority-snapshot/1');
  const build = bindObservedBuildContext(observed, { languageAuthority, backendRegistry, backendId: 'typescript' });
  const resolveArtifact = identity => build.artifacts.get(artifactKey(identity));
  return { build, observed, languageAuthority, resolveArtifact };
}
test('observed products carry one exact environment and one declaration per executed edge', async () => {
  const f = fixture(), result = await verifyObservedContextProducts(f.build.graph, { resolveArtifact: f.resolveArtifact });
  assert.equal(result.present, true); assert.equal(result.bindings.length, f.build.graph.executions.length);
  assert.equal(result.hermeticityVerified, false);
  assert.equal(result.artifactBundle.claimsVerified, false);
  const products = JSON.parse(f.build.artifactBundle.bytes);
  assert.equal(products.executableArtifacts.length, 2);
  assert.equal(products.publicApiArtifacts.length, 1);
  assert.equal(products.debugArtifacts.length, 1);
  assert.equal(JSON.parse(f.build.claimSet.bytes).claims.length, 0);
  assert.deepEqual(f.build.graph.executions, f.observed.graph.executions);
  assert.throws(() => bindObservedBuildContext(f.build, { languageAuthority: f.languageAuthority,
    backendRegistry, backendId: 'typescript' }), /ALREADY_BOUND/);
});
test('archive consumer independently replays the V5 binding set', async () => {
  const f = fixture(), archive = packObservedBuildArchive(f.build);
  const allowedAssumptions = [...new Set(f.build.graph.entries.filter(entry => entry.identity.domain === 'pass-definition')
    .flatMap(entry => entry.canonicalValue.assumptionIds))];
  const result = await verifyObservedBuildArchive(archive.bytes, { expectedGraphId: f.build.identity, allowedAssumptions });
  assert.equal(result.kind, 'accepted', result.reason);
  assert.equal(result.buildContext.bindings.length, f.build.graph.executions.length);
  assert.equal(result.fullInputClosureEstablished, false);
  assert.equal(result.preservationVerified, false);
});
test('partial context, changed action input and corrupt profile bytes reject', async () => {
  const f = fixture();
  const graph = { ...f.build.graph, entries: f.build.graph.entries.filter(entry => entry.identity.domain !== 'action-binding') };
  await assert.rejects(verifyObservedContextProducts(graph, { resolveArtifact: f.resolveArtifact }), /ACTION_COVERAGE/);
  const key = artifactKey(f.build.profileEnvironment.identity);
  f.build.artifacts.set(key, Buffer.from('changed'));
  await assert.rejects(verifyObservedContextProducts(f.build.graph, { resolveArtifact: f.resolveArtifact }), /ARTIFACT_BYTES/);
});

test('rehashed action cannot omit an observed input from its exact execution binding', async () => {
  const f = fixture(), original = f.build.buildActions[0];
  const fields = JSON.parse(original.action.bytes);
  delete fields.schemaVersion; delete fields.contract;
  fields.exactInputArtifactIds = fields.exactInputArtifactIds.slice(1);
  const action = createBuildAction(fields);
  f.build.artifacts.set(artifactKey(action.identity), action.bytes);
  const binding = canonicalArtifact({ ...JSON.parse(original.binding.bytes), actionId: action.identity },
    'action-binding', 'psc-observed-action-binding/1');
  await assert.rejects(verifyObservedActionBinding(binding, { resolveArtifact: f.resolveArtifact }), /EXECUTION_BINDING/);
});
