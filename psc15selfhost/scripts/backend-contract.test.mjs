import { createProfileEnvironment, createExtensionSet } from './build-context.mjs';
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { readFile } from 'node:fs/promises';
import { artifactKey, canonicalArtifact } from './artifact-evidence.mjs';
import { createClaimSet } from './claim-set.mjs';
import { createBackendDescriptor, decodeBackendDescriptor, createArtifactBundle, verifyArtifactBundle,
  selectUniformJavaScriptRegistry, selectUniformJavaScriptRegistryV1, uniformJavaScriptDeclarationMapDerivation, uniformJavaScriptMapLinkDerivation, backendSelectionContract, verifyBackendProfileSelection } from './backend-contract.mjs';

const registryValue = JSON.parse(await readFile(new URL('../contracts/backends/BACKEND_REGISTRY_V1.json', import.meta.url), 'utf8'));
function fixture(backendId) {
  const records = new Map();
  const add = record => { records.set(artifactKey(record.identity), record.bytes); return record; };
  const artifact = (value, domain = 'fixture', contract = 'test-only/1') => add(canonicalArtifact(value, domain, contract));
  const registry = add(canonicalArtifact(registryValue, 'backend-registry', 'psc-backend-registry/1'));
  const selected = registryValue.backends.find(item => item.backendId === backendId);
  const implementationId = artifact('fixture compiler').identity;
  const targetProfileId = artifact('fixture target profile').identity;
  const externalToolchainId = selected.backendKind === 'sourceTarget' ? artifact('fixture pinned toolchain').identity : null;
  const descriptor = add(createBackendDescriptor(registry, { backendId, implementationId,
    targetProfileId, externalToolchainId, interfaceAdapterId: null }));
  const product = selected.products.executableArtifacts[0];
  const executable = artifact('fixture target bytes', product.domain, product.contract);
  const sourceSubjectId = artifact('fixture source').identity;
  const extensionSet = add(createExtensionSet());
  const profileEnvironmentId = add(createProfileEnvironment({
    languageEdition: 'test-edition', semanticProfileId: artifact('test profile', 'semantic-profile', 'test-profile/1').identity,
    standardEnvironmentId: artifact('test standard').identity, extensionSetId: extensionSet.identity,
    importedStructuralInterfaceIds: [], importedBehavioralInterfaceIds: [], semanticOptions: {},
  })).identity;
  const claims = add(createClaimSet());
  const fields = { descriptor, sourceSubjectId, profileEnvironmentId, claimSetId: claims.identity,
    executableArtifacts: [{ role: product.role, artifact: executable.identity }],
    publicApiArtifacts: [], debugArtifacts: [], interfaceArtifacts: [],
    targetToolchainArtifacts: externalToolchainId ? [externalToolchainId] : [], evidenceArtifacts: [] };
  const bundle = add(createArtifactBundle(fields));
  const policy = { expectedBundleId: bundle.identity, resolveArtifact: id => records.get(artifactKey(id)) };
  return { records, add, artifact, descriptor, fields, bundle, policy, registry, executable, externalToolchainId };
}

test('all four lanes share identified bundles without inferred semantic claims', async () => {
  assert.deepEqual(registryValue.backends.map(item => item.backendId), ['typescript', 'javascript', 'wasm', 'rust']);
  for (const backend of registryValue.backends) {
    const f = fixture(backend.backendId), result = await verifyArtifactBundle(f.bundle, f.policy);
    assert.equal(result.integrityVerified, true); assert.equal(result.claimsVerified, false);
    assert.equal(result.preservationVerified, false); assert.equal(result.releaseAccepted, false);
    const checkedEmpty = await verifyArtifactBundle(f.bundle, { ...f.policy, claimVerification: {} });
    assert.equal(checkedEmpty.verifiedClaims.verifiedClaimCount, 0);
    assert.equal(decodeBackendDescriptor(f.descriptor).backendKind, backend.backendKind);
  }
});

test('direct JS cannot silently substitute tsc declarations or maps', () => {
  const f = fixture('javascript');
  const declaration = f.artifact('declaration', 'declarations-output', 'typescript-emitted-file/1');
  assert.throws(() => createArtifactBundle({ ...f.fields,
    publicApiArtifacts: [{ role: 'declaration', artifact: declaration.identity }] }), /UNSUPPORTED_PRODUCT/);
  assert.throws(() => createArtifactBundle({ ...f.fields, backendId: 'typescript' }), /SCHEMA/);
});

test('source backend tool products require the exact declared toolchain artifact', () => {
  const f = fixture('typescript');
  const js = f.artifact('javascript', 'javascript-output', 'typescript-emitted-file/1');
  const products = [{ role: 'javascript', artifact: js.identity }];
  assert.throws(() => createArtifactBundle({ ...f.fields, executableArtifacts: products, targetToolchainArtifacts: [] }), /TOOLCHAIN_REQUIRED/);
  assert.throws(() => createArtifactBundle({ ...f.fields, executableArtifacts: products,
    targetToolchainArtifacts: [f.artifact('other toolchain').identity] }), /TOOLCHAIN_REQUIRED/);
  assert.doesNotThrow(() => createArtifactBundle({ ...f.fields, executableArtifacts: products }));
});

test('bundle identity, registry binding and every referenced byte are checked', async () => {
  const f = fixture('wasm');
  await assert.rejects(verifyArtifactBundle(f.bundle, { ...f.policy, expectedBundleId: f.artifact('other').identity }), /CONSUMER_POLICY/);
  const key = artifactKey(f.executable.identity), bytes = f.records.get(key);
  f.records.set(key, Buffer.from('changed'));
  await assert.rejects(verifyArtifactBundle(f.bundle, f.policy), /ARTIFACT_BYTES/);
  f.records.set(key, bytes);
  const value = JSON.parse(f.descriptor.bytes); value.emitterId = 'unregistered-emitter';
  const descriptor = f.add(canonicalArtifact(value, 'backend-descriptor', 'psc-backend-descriptor/1'));
  const changed = f.add(createArtifactBundle({ ...f.fields, descriptor }));
  await assert.rejects(verifyArtifactBundle(changed, { ...f.policy, expectedBundleId: changed.identity }), /DESCRIPTOR_REGISTRY_BINDING/);
});

test('missing debug products are independent from claims and cannot hide a missing executable', () => {
  const f = fixture('typescript');
  assert.doesNotThrow(() => createArtifactBundle({ ...f.fields, debugArtifacts: [] }));
  assert.throws(() => createArtifactBundle({ ...f.fields, executableArtifacts: [] }), /LIST/);
  const map = f.artifact('map', 'source-map-output', 'typescript-emitted-file/1');
  assert.throws(() => createArtifactBundle({ ...f.fields,
    publicApiArtifacts: [{ role: 'source-map', artifact: map.identity }] }), /UNSUPPORTED_PRODUCT/);
});

test('ClaimSet subjects and profiles cannot be transplanted into another bundle', async () => {
  const f = fixture('javascript');
  for (const changed of ['subject', 'profile']) {
    const claim = { kind: 'TargetToolAccepted', subjects: [changed === 'subject' ? f.artifact('other').identity : f.executable.identity],
      profileEnvironmentId: changed === 'profile' ? f.artifact('other profile').identity : f.fields.profileEnvironmentId,
      evidenceClass: 'target-tool-acceptance', evidenceIds: [f.artifact('test-only evidence').identity],
      checkerImplementationId: f.artifact('test checker').identity, resourcePolicyId: f.artifact('test resource policy').identity,
      assumptionIds: [] };
    const claims = f.add(createClaimSet([claim]));
    const bundle = f.add(createArtifactBundle({ ...f.fields, claimSetId: claims.identity }));
    await assert.rejects(verifyArtifactBundle(bundle, { ...f.policy, expectedBundleId: bundle.identity }), /CLAIM_SUBJECT/);
  }
});

test('uniform selection derives one lane and freshly rejects rehashed registry drift or missing selection', async () => {
  const f = fixture('javascript'), selected = selectUniformJavaScriptRegistry(f.registry);
  f.add(selected.registry); f.add(selected.selection);
  const base = JSON.parse(f.registry.bytes), registry = JSON.parse(selected.registry.bytes);
  assert.deepEqual(registry.backends.filter(item => item.backendId !== 'javascript'),
    base.backends.filter(item => item.backendId !== 'javascript'));
  const js = registry.backends.find(item => item.backendId === 'javascript');
  assert.equal(js.inputDomain, 'uniform-specialized-ir');
  assert.equal(js.packagePath, 'packages/backend-js');
  assert.equal(js.emitterId, base.backends.find(item => item.backendId === 'javascript').emitterId);
  assert.equal(JSON.parse(selected.selection.bytes).pipelineEntry.packagePath, 'packages/driver-js');
  assert.equal(js.products.debugArtifacts.some(item => item.role === 'source-map'), true);
  const old = decodeBackendDescriptor(f.descriptor);
  const fields = Object.fromEntries(['backendId', 'implementationId', 'targetProfileId', 'externalToolchainId', 'interfaceAdapterId']
    .map(key => [key, old[key]]));
  const descriptor = f.add(createBackendDescriptor(selected.registry, fields));
  const bundle = f.add(createArtifactBundle({ ...f.fields, descriptor, evidenceArtifacts: [selected.selection.identity] }));
  const result = await verifyArtifactBundle(bundle, { ...f.policy, expectedBundleId: bundle.identity });
  assert.equal(result.profileSelection.bindingVerified, true);
  assert.equal(result.preservationVerified, false);
  const omitted = f.add(createArtifactBundle({ ...f.fields, descriptor }));
  await assert.rejects(verifyArtifactBundle(omitted, { ...f.policy, expectedBundleId: omitted.identity }), /SELECTION_REQUIRED/);
  const badValue = JSON.parse(selected.registry.bytes);
  badValue.backends.find(item => item.backendId === 'javascript').emitterId = 'invented-emitter';
  const badRegistry = f.add(canonicalArtifact(badValue, 'backend-registry', 'psc-backend-registry/1'));
  const badSelection = f.add(canonicalArtifact({ ...JSON.parse(selected.selection.bytes), selectedRegistryId: badRegistry.identity },
    'backend-profile-selection', backendSelectionContract));
  await assert.rejects(verifyBackendProfileSelection(badSelection, {
    expectedRegistryId: badRegistry.identity, resolveArtifact: f.policy.resolveArtifact }), /SELECTION_BINDING/);
  const badDescriptor = f.add(createBackendDescriptor(badRegistry, fields));
  const badBundle = f.add(createArtifactBundle({ ...f.fields, descriptor: badDescriptor, evidenceArtifacts: [badSelection.identity] }));
  await assert.rejects(verifyArtifactBundle(badBundle, { ...f.policy, expectedBundleId: badBundle.identity }), /SELECTION_BINDING/);
  assert.throws(() => selectUniformJavaScriptRegistry(selected.registry), /SELECTION_BASE/);
});

test('historical uniform selections replay under their frozen derivation and cannot acquire current ownership metadata', async () => {
  const f = fixture('javascript');
  const historical = selectUniformJavaScriptRegistryV1(f.registry);
  const current = selectUniformJavaScriptRegistry(f.registry);
  for (const item of [historical, current]) { f.add(item.registry); f.add(item.selection); }
  assert.notEqual(artifactKey(historical.registry.identity), artifactKey(current.registry.identity));
  assert.equal(JSON.parse(historical.registry.bytes).backends.find(item => item.backendId === 'javascript').emitterId,
    'psCompilerUniformJavaScriptStagesFromPrepared');
  const replay = await verifyBackendProfileSelection(historical.selection, {
    expectedRegistryId: historical.registry.identity, resolveArtifact: f.policy.resolveArtifact });
  assert.equal(replay.emitterRole, 'historical-driver-entry');
  const fields = Object.fromEntries(['backendId', 'implementationId', 'targetProfileId', 'externalToolchainId', 'interfaceAdapterId']
    .map(key => [key, decodeBackendDescriptor(f.descriptor)[key]]));
  const descriptor = f.add(createBackendDescriptor(historical.registry, fields));
  const bundle = f.add(createArtifactBundle({ ...f.fields, descriptor, evidenceArtifacts: [historical.selection.identity] }));
  assert.equal((await verifyArtifactBundle(bundle, { ...f.policy, expectedBundleId: bundle.identity })).profileSelection.bindingVerified, true);
  for (const mutate of [
    value => { value.derivationId = 'unknown-derivation'; },
    value => { value.pipelineEntry.packagePath = 'packages/backend-js'; },
    value => { value.selectedRegistryId = historical.registry.identity; },
  ]) {
    const value = JSON.parse(current.selection.bytes); mutate(value);
    const changed = f.add(canonicalArtifact(value, 'backend-profile-selection', backendSelectionContract));
    await assert.rejects(verifyBackendProfileSelection(changed, {
      expectedRegistryId: value.selectedRegistryId, resolveArtifact: f.policy.resolveArtifact }), /SELECTION_/);
  }
});

test('earlier selection/2 derivation remains replayable without newly implemented uniform maps', async () => {
  const f = fixture('javascript');
  const historical = selectUniformJavaScriptRegistry(f.registry, { derivationId: 'psc-uniform-js-backend-derivation/2' });
  const current = selectUniformJavaScriptRegistry(f.registry);
  for (const selected of [historical, current]) {
    f.add(selected.registry); f.add(selected.selection);
    assert.equal((await verifyBackendProfileSelection(selected.selection, {
      expectedRegistryId: selected.registry.identity, resolveArtifact: f.policy.resolveArtifact })).bindingVerified, true);
  }
  assert.equal(JSON.parse(historical.registry.bytes).backends.find(item => item.backendId === 'javascript').products.debugArtifacts
    .some(item => item.role === 'source-map'), false);
  assert.equal(JSON.parse(current.registry.bytes).backends.find(item => item.backendId === 'javascript').products.debugArtifacts
    .find(item => item.role === 'source-map-recipe').contract, 'psc-direct-javascript-source-map-recipe/2');
  assert.notEqual(artifactKey(historical.registry.identity), artifactKey(current.registry.identity));
});

test('declaration maps require the explicit current product inventory and versioned uniform derivation', async () => {
  const value = JSON.parse(await readFile(new URL('../contracts/backends/BACKEND_REGISTRY_V2.json', import.meta.url), 'utf8'));
  const base = canonicalArtifact(value, 'backend-registry', 'psc-backend-registry/1');
  assert.deepEqual(value.backends.filter(item => item.backendId !== 'javascript'),
    registryValue.backends.filter(item => item.backendId !== 'javascript'));
  const selected = selectUniformJavaScriptRegistry(base, { derivationId: uniformJavaScriptDeclarationMapDerivation });
  const records = new Map([base, selected.registry, selected.selection].map(item => [artifactKey(item.identity), item.bytes]));
  const result = await verifyBackendProfileSelection(selected.selection, {
    expectedRegistryId: selected.registry.identity, resolveArtifact: id => records.get(artifactKey(id)) });
  assert.equal(result.bindingVerified, true);
  const lane = JSON.parse(selected.registry.bytes).backends.find(item => item.backendId === 'javascript');
  assert.equal(lane.products.debugArtifacts.filter(item => item.role === 'declaration-map').length, 1);
  const old = fixture('javascript');
  assert.throws(() => selectUniformJavaScriptRegistry(old.registry,
    { derivationId: uniformJavaScriptDeclarationMapDerivation }), /SELECTION_DECLARATION_MAP_BASE/);
});

test('opt-in linked output has exact versioned uniform registry and retains historical derivations', async () => {
  const v3 = JSON.parse(await readFile(new URL('../contracts/backends/BACKEND_REGISTRY_V3.json', import.meta.url), 'utf8'));
  const base = canonicalArtifact(v3, 'backend-registry', 'psc-backend-registry/1');
  const selected = selectUniformJavaScriptRegistry(base, { derivationId: uniformJavaScriptMapLinkDerivation });
  const values = new Map([base, selected.registry, selected.selection].map(item => [artifactKey(item.identity), item.bytes]));
  const checked = await verifyBackendProfileSelection(selected.selection, {
    expectedRegistryId: selected.registry.identity, resolveArtifact: id => values.get(artifactKey(id)) });
  assert.equal(checked.bindingVerified, true);
  const lane = JSON.parse(selected.registry.bytes).backends.find(item => item.backendId === 'javascript');
  assert.ok(lane.products.executableArtifacts.some(item => item.role === 'linked-javascript'));
  assert.ok(lane.products.publicApiArtifacts.some(item => item.role === 'linked-declarations'));
  assert.ok(lane.products.debugArtifacts.some(item => item.role === 'source-map-link-recipe'));
  assert.throws(() => selectUniformJavaScriptRegistry(base,
    { derivationId: uniformJavaScriptDeclarationMapDerivation }), /SELECTION_DECLARATION_MAP_BASE/);
});
