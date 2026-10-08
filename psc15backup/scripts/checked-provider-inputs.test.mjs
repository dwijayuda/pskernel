import assert from 'node:assert/strict';
import { test } from 'node:test';
import { mkdtemp, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { captureCheckedProviderInputs, verifyCheckedProviderInputs } from './checked-provider-inputs.mjs';
import { checkAdmissionsWithKernel } from './checked-kernel-provider.mjs';
import { createCheckedBuildGraph } from './checked-build-evidence.mjs';
import { artifactKey } from './artifact-evidence.mjs';
import { packObservedBuildArchive, verifyObservedBuildArchive } from './observed-build-archive.mjs';

test('actual bundled Lean Wasm check is bracketed by matching provider-byte snapshots', async () => {
  const captured = await captureCheckedProviderInputs('lean434-wasm');
  const checked = await checkAdmissionsWithKernel('{"admissions":[],"format":"proofscript-checked-admissions","version":2}',
    'lean434-wasm', captured.invocationOptions);
  assert.equal(checked.result.accepted, true);
  const inputs = await verifyCheckedProviderInputs(captured);
  assert.equal(inputs.details.selector, 'lean434-wasm');
  assert.equal(inputs.details.fullInputClosureEstablished, false);
  assert.ok(inputs.files.some(item => item.path.endsWith('/pskernel-lean.wasm')));
  assert.ok(inputs.files.some(item => item.path.endsWith('/LEAN_LICENSE')));
  await assert.rejects(verifyCheckedProviderInputs({ ...captured }), /UNKNOWN_CAPTURE/);
  await assert.rejects(captureCheckedProviderInputs('lean434-wasm', { wasmLauncherPath: 'unselected' }), /OPTIONS/);
  await assert.rejects(captureCheckedProviderInputs('toString'), /UNSUPPORTED/);
  await assert.rejects(captureCheckedProviderInputs('lean434-wasm', {}, { maxFiles: 0 }), /RESOURCE_EXHAUSTED/);
});

test('native selection is explicit and changed or oversized bytes fail observation', async () => {
  const directory = await mkdtemp(path.join(tmpdir(), 'psc-provider-inputs-'));
  try {
    const file = path.join(directory, 'provider.fixture');
    await writeFile(file, 'fictional executable, never invoked');
    const captured = await captureCheckedProviderInputs('pskernel-core', { coreBinaryPath: file });
    assert.equal(captured.invocationOptions.coreBinaryPath, file);
    const inputs = await verifyCheckedProviderInputs(captured);
    assert.equal(inputs.details.nativePath, 'selected-native-provider');
    assert.ok(inputs.files.some(item => item.path === 'selected-native-provider'));
    await assert.rejects(captureCheckedProviderInputs('pskernel-core', { coreBinaryPath: file }, { maxFileBytes: 1 }), /RESOURCE_EXHAUSTED/);
    await writeFile(file, 'changed executable');
    await assert.rejects(verifyCheckedProviderInputs(captured), /CHANGED/);
  } finally { await rm(directory, { recursive: true, force: true }); }
});

test('provider artifacts bind the checking action and replay offline without executing the archived provider', async () => {
  const inputs = await verifyCheckedProviderInputs(await captureCheckedProviderInputs('pskernel-core.old3'));
  const built = createCheckedBuildGraph({ sourceKind: 'lean', sources: ['fixture'], admissions: 'fixture',
    compilerBytes: Buffer.from('fictional compiler'), compilerKind: 'test-double', provider: inputs.details.provider,
    providerSecurity: {}, kernelContract: {}, hostSources: [], runtime: { version: 'test' }, providerToolInputs: [inputs] });
  const provider = built.graph.entries.find(entry => entry.identity.contract === 'psc-checked-provider-inputs/1');
  const context = built.graph.entries.find(entry => entry.identity.contract === 'psc-acceptance-context/1');
  assert.deepEqual(context.canonicalValue.providerInputs, [provider.identity]);
  const action = built.graph.entries.find(entry => entry.identity.contract === 'psc-action/1');
  assert.ok(action.canonicalValue.dependencies.some(id => artifactKey(id) === artifactKey(provider.identity)));
  const archive = packObservedBuildArchive(built);
  const allowedAssumptions = [...new Set(built.graph.entries.flatMap(entry => entry.canonicalValue?.assumptionIds ?? []))];
  const replay = await verifyObservedBuildArchive(archive.bytes, { expectedGraphId: built.identity, allowedAssumptions });
  assert.equal(replay.kind, 'accepted', replay.reason);
  assert.equal(replay.semanticClaimsVerified, false);
  assert.equal(replay.fullInputClosureEstablished, false);
  const foundation = provider.canonicalValue.files.find(item => item.path.endsWith('/foundation.js'));
  built.artifacts.get(artifactKey(foundation.artifact)).fill(0);
  assert.throws(() => packObservedBuildArchive(built), /ARTIFACT_BYTES/);
});
