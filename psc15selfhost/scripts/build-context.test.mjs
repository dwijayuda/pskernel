import assert from 'node:assert/strict';
import { test } from 'node:test';
import { artifactKey, canonicalArtifact, passDefinition } from './artifact-evidence.mjs';
import { createExtensionSet, createProfileEnvironment, createBuildAction,
  verifyProfileEnvironment, verifyBuildAction } from './build-context.mjs';

function fixture() {
  const records = new Map();
  const add = record => { records.set(artifactKey(record.identity), record.bytes); return record; };
  const artifact = (value, domain = 'fixture') => add(canonicalArtifact(value, domain, 'test-only/1'));
  const extension = artifact('extension manifest'), extensionImplementation = artifact('extension implementation');
  const extensionSet = add(createExtensionSet([{ extensionId: extension.identity,
    implementationId: extensionImplementation.identity, influenceClass: 'E1' }]));
  const profileFields = { languageEdition: 'test-edition', semanticProfileId: artifact('profile', 'semantic-profile').identity,
    standardEnvironmentId: artifact('standard').identity, extensionSetId: extensionSet.identity,
    importedStructuralInterfaceIds: [artifact('structural').identity], importedBehavioralInterfaceIds: [artifact('behavioral').identity],
    semanticOptions: { option: false } };
  const environment = add(createProfileEnvironment(profileFields));
  const implementation = artifact('compiler');
  const definition = add(passDefinition({ passId: 'fixture-pass/1', version: 1, inputContract: 'test-only/1',
    outputContract: 'test-output/1', semanticRelationId: 'fixture-relation/1', resourceContractId: 'fixture-resources/1',
    determinismClass: 'fixture', totalityClass: 'partial', implementationId: implementation.identity,
    validatorId: null, theoremIds: [], assumptionIds: [] }));
  const actionFields = { actionKind: 'fixture-pass/1', passDefinitionId: definition.identity, implementationId: implementation.identity,
    semanticProfileId: profileFields.semanticProfileId, profileEnvironmentId: environment.identity,
    extensionSetId: extensionSet.identity, exactInputArtifactIds: [artifact('input').identity],
    exactToolchainIds: [artifact('toolchain').identity], targetProfileId: artifact('target').identity,
    declaredEnvironment: [{ name: 'LANG', value: 'C' }], resourcePolicyId: artifact('resources').identity,
    outputContracts: [{ role: 'output', domain: 'output', contract: 'test-output/1' }] };
  const action = add(createBuildAction(actionFields));
  const resolveArtifact = identity => records.get(artifactKey(identity));
  return { add, artifact, records, profileFields, environment, actionFields, action, extensionSet, extensionImplementation, resolveArtifact };
}
test('environment and action replay resolve exact declared inputs without claiming hermeticity', async () => {
  const f = fixture();
  assert.equal((await verifyProfileEnvironment(f.environment, { expectedProfileEnvironmentId: f.environment.identity,
    resolveArtifact: f.resolveArtifact })).observedClosureVerified, false);
  const result = await verifyBuildAction(f.action, { expectedActionId: f.action.identity, resolveArtifact: f.resolveArtifact });
  assert.equal(result.declaredInputsVerified, true); assert.equal(result.hermeticityVerified, false);
  assert.equal(result.authority, 'audit-record-only');
  f.records.delete(artifactKey(f.extensionImplementation.identity));
  await assert.rejects(verifyBuildAction(f.action, { expectedActionId: f.action.identity, resolveArtifact: f.resolveArtifact }), /MISSING_ARTIFACT/);
});
test('all interpretation and action fields participate in identity', () => {
  const f = fixture();
  for (const [field, value] of Object.entries({
    languageEdition: 'different', semanticProfileId: f.artifact('profile2', 'semantic-profile').identity,
    standardEnvironmentId: f.artifact('standard2').identity, extensionSetId: f.add(createExtensionSet()).identity,
    importedStructuralInterfaceIds: [], importedBehavioralInterfaceIds: [], semanticOptions: { option: true },
  })) assert.notEqual(artifactKey(createProfileEnvironment({ ...f.profileFields, [field]: value }).identity), artifactKey(f.environment.identity), field);
  for (const [field, value] of Object.entries({
    actionKind: 'other-pass/1', passDefinitionId: f.artifact('other definition', 'pass-definition').identity,
    implementationId: f.artifact('other compiler').identity, semanticProfileId: f.artifact('profile3', 'semantic-profile').identity,
    profileEnvironmentId: f.add(createProfileEnvironment({ ...f.profileFields, semanticOptions: {} })).identity,
    exactInputArtifactIds: [f.artifact('input2').identity], exactToolchainIds: [],
    targetProfileId: null, extensionSetId: f.add(createExtensionSet()).identity,
    declaredEnvironment: [{ name: 'LANG', value: 'changed' }], resourcePolicyId: f.artifact('resources2').identity,
    outputContracts: [{ role: 'other', domain: 'output', contract: 'test-output/1' }],
  })) assert.notEqual(artifactKey(createBuildAction({ ...f.actionFields, [field]: value }).identity), artifactKey(f.action.identity), field);
});
test('mismatched profile, pass and consumer selections reject even when rehashed', async () => {
  const f = fixture(), policy = { expectedActionId: f.action.identity, resolveArtifact: f.resolveArtifact };
  await assert.rejects(verifyBuildAction(f.action, { ...policy, expectedActionId: f.environment.identity }), /CONSUMER_ACTION/);
  for (const [field, value, expected] of [
    ['extensionSetId', f.add(createExtensionSet()).identity, /ACTION_PROFILE/],
    ['implementationId', f.artifact('wrong compiler').identity, /PASS_BINDING/],
    ['outputContracts', [{ role: 'output', domain: 'output', contract: 'wrong/1' }], /OUTPUT_CONTRACT/],
  ]) {
    const changed = f.add(createBuildAction({ ...f.actionFields, [field]: value }));
    await assert.rejects(verifyBuildAction(changed, { ...policy, expectedActionId: changed.identity }), expected);
  }
});
test('ambiguous, undeclared and duplicate context fields reject', () => {
  const f = fixture();
  assert.throws(() => createProfileEnvironment({ ...f.profileFields, hidden: 'input' }), /FIELDS/);
  assert.throws(() => createExtensionSet([{ extensionId: f.environment.identity,
    implementationId: f.environment.identity, influenceClass: 'E7' }]), /EXTENSION_CLASS/);
  assert.throws(() => createBuildAction({ ...f.actionFields, declaredEnvironment: [{ name: 'PATH', value: 'x' }, { name: 'PATH', value: 'y' }] }), /DUPLICATE/);
  assert.throws(() => createBuildAction({ ...f.actionFields, exactInputArtifactIds: [...f.actionFields.exactInputArtifactIds, ...f.actionFields.exactInputArtifactIds] }), /DUPLICATE/);
});
