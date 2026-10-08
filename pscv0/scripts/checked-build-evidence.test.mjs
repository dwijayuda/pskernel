import assert from 'node:assert/strict';
import { test } from 'node:test';
import { artifactKey, canonicalBytes, verifyArtifact, verifyPassExecution } from './artifact-evidence.mjs';
import { createCheckedBuildGraph, readCheckedBuildHostSources } from './checked-build-evidence.mjs';

test('observed composite graph binds actual source, admissions and emitted files', async () => {
  const built = createCheckedBuildGraph({ sourceKind: 'lean', sources: ['def seven : Nat := 7'],
    admissions: '{"admissions":[],"format":"proofscript-checked-admissions","version":2}',
    typeScript: 'export const seven: bigint = 7n;', javaScript: Buffer.from('export const seven = 7n;'),
    declarations: Buffer.from('export declare const seven: bigint;'), sourceMap: Buffer.from('{}'),
    compilerBytes: Buffer.from('fixture compiler'), compilerKind: 'test-double', typeScriptCompilerBytes: Buffer.from('fixture tsc'),
    provider: { profile: 'test-profile' }, providerSecurity: { profile: 'test-security' }, kernelContract: { id: 'test-kernel' },
    hostSources: [{ path: 'test.mjs', bytes: Buffer.from('test implementation') }], runtime: { version: 'test' }, outputStem: 'seven' });
  verifyArtifact(built.bytes, built.identity);
  verifyArtifact(canonicalBytes(built.graph), built.identity);
  assert.equal(built.graph.executions.length, 3);
  assert.equal(built.graph.coverage, 'observed-composite-edges');
  for (const identity of built.graph.executions) {
    const bytes = built.artifacts.get(artifactKey(identity));
    const definitionId = JSON.parse(bytes).passDefinitionId;
    const definition = JSON.parse(built.artifacts.get(artifactKey(definitionId)));
    const result = await verifyPassExecution({ bytes, identity }, {
      resolveArtifact: id => built.artifacts.get(artifactKey(id)), allowedAssumptions: definition.assumptionIds });
    assert.equal(result.integrityVerified, true);
    assert.equal(result.preservationVerified, false);
  }
  const hostSources = await readCheckedBuildHostSources();
  assert.ok(hostSources.some(item => item.path === 'scripts/kernel-checked-session.mjs'));
  assert.ok(hostSources.some(item => item.path === 'scripts/checked-build-evidence.mjs'));
  assert.ok(hostSources.every(item => !item.path.includes('..')));
});
