import { createQueryKey, verifyQueryKey, applyPassEffects } from './query-context.mjs';
import { artifactId, artifactKey, canonicalArtifact, canonicalBytes, verifyArtifact } from './artifact-evidence.mjs';
import { createExtensionSet, createProfileEnvironment, createBuildAction, decodeBuildAction,
  verifyBuildAction } from './build-context.mjs';
import { createClaimSet } from './claim-set.mjs';
import { createBackendDescriptor, decodeBackendRegistry, createArtifactBundle, verifyArtifactBundle } from './backend-contract.mjs';

const fail = code => { throw new Error('PSC_OBSERVED_CONTEXT_' + code); };
const equal = (a, b) => canonicalBytes(a).equals(canonicalBytes(b));
const uniqueIds = values => [...new Map(values.map(value => [artifactKey(value), value])).values()];

/** Enrich already captured edges. No source/compiler is re-executed, and no
 * successful pass/proof claim is inferred. Historical graph records remain
 * exact inputs to the new declarations, rather than being reinterpreted.
 */
export function bindObservedBuildContext(build, { languageAuthority, backendRegistry, backendId }) {
  verifyArtifact(build.bytes, build.identity);
  if (!equal(build.graph, JSON.parse(build.bytes)) || build.identity.contract !== 'psc-observed-build-graph/1') fail('GRAPH');
  if (build.graph.entries.some(entry => entry.identity.contract === 'psc-build-action/1')) fail('ALREADY_BOUND');
  const entries = [...build.graph.entries], artifacts = new Map(build.artifacts);
  function add(record) {
    verifyArtifact(record.bytes, record.identity);
    const key = artifactKey(record.identity);
    if (!artifacts.has(key)) {
      artifacts.set(key, Buffer.from(record.bytes));
      entries.push({ identity: record.identity, source: { kind: 'inline' }, canonicalValue: JSON.parse(record.bytes) });
    }
    return record;
  }
  const json = (value, domain, contract) => add(canonicalArtifact(value, domain, contract));
  function resolve(identity) {
    const bytes = artifacts.get(artifactKey(identity)); verifyArtifact(bytes, identity); return JSON.parse(bytes);
  }
  function one(domain, contract) {
    const matches = entries.filter(entry => entry.identity.domain === domain && (!contract || entry.identity.contract === contract));
    if (matches.length !== 1) fail('SINGLE_' + domain);
    return matches[0].identity;
  }
  add(languageAuthority);
  if (languageAuthority.identity.domain !== 'language-authority' || languageAuthority.identity.contract !== 'psc-language-authority-snapshot/1') fail('LANGUAGE_AUTHORITY');
  const authority = resolve(languageAuthority.identity);
  if (typeof authority.languageEdition !== 'string' || !authority.languageEdition) fail('LANGUAGE_EDITION');
  const registry = decodeBackendRegistry(backendRegistry); add(backendRegistry);
  const registration = registry.backends.find(entry => entry.backendId === backendId);
  if (!registration) fail('BACKEND');
  const implementationId = one('implementation', 'psc-hosted-compiler-implementation/1');
  const compilerId = one('compiler', 'psc-compiler-module/1');
  const sourceSubjectId = one('source-snapshot', 'psc-source-snapshot/1');
  const source = resolve(sourceSubjectId), securityId = one('acceptance-context'), security = resolve(securityId);
  const semanticProfile = json({ languageAuthorityId: languageAuthority.identity, profile: security.provider.profile,
    kernelContract: security.kernelContract, runtimeSemantics: 'psc-runtime-semantics/1' },
  'semantic-profile', 'psc-observed-semantic-profile/1');
  // Builtin/prelude definitions are embedded in the exact selected compiler.
  // Compiler changes conservatively invalidate this standard-environment ID.
  const standard = json({ compilerId, acceptanceContextId: securityId,
    scope: 'embedded-in-selected-compiler', fullSemanticClosureEstablished: false },
  'standard-environment', 'psc-embedded-standard-environment/1');
  // The current composition has no dynamic extension loader. Prelude additions
  // are part of the embedded standard environment, not unrecorded extensions.
  const extensionSet = add(createExtensionSet());
  const profileEnvironment = add(createProfileEnvironment({
    languageEdition: authority.languageEdition, semanticProfileId: semanticProfile.identity,
    standardEnvironmentId: standard.identity, extensionSetId: extensionSet.identity,
    importedStructuralInterfaceIds: [], importedBehavioralInterfaceIds: [],
    semanticOptions: { sourceKind: source.sourceKind, importMode: 'flattened-ordered-source-closure' },
  }));
  const targetProfile = json({ backendId, observedActionIds: build.graph.executions.map(identity => resolve(identity).actionId) },
    'target-profile', 'psc-observed-target-profile/1');
  const toolchains = entries.filter(entry => ['tool-inputs', 'typescript-compiler-entry'].includes(entry.identity.domain)).map(entry => entry.identity);
  const buildActions = [], queryKeys = [];
  const inputClasses = { 'source-snapshot': 'source', 'canonical-admissions': 'checked-structural',
    'certified-source': 'certified-source', 'runtime-ir': 'runtime', 'verified-ir': 'verified-ir',
    'specialized-ir': 'specialized-ir', 'js-ir': 'target', 'wasm-ir': 'target', 'runtime-interface': 'runtime-interface' };
  for (const executionId of build.graph.executions) {
    const execution = resolve(executionId), definition = resolve(execution.passDefinitionId);
    const resource = json(execution.action.resourcePolicy, 'resource-policy', 'psc-observed-resource-policy/1');
    const action = add(createBuildAction({
      actionKind: definition.passId, passDefinitionId: execution.passDefinitionId,
      implementationId: definition.implementationId, semanticProfileId: semanticProfile.identity,
      profileEnvironmentId: profileEnvironment.identity,
      exactInputArtifactIds: uniqueIds([...execution.inputs, ...execution.action.dependencies, execution.actionId]),
      exactToolchainIds: uniqueIds(toolchains), targetProfileId: targetProfile.identity,
      extensionSetId: extensionSet.identity,
      // The inherited runner reads ambient host state. An empty declared list
      // does not claim that no ambient inputs were read; hermeticity is false.
      declaredEnvironment: [], resourcePolicyId: resource.identity,
      outputContracts: definition.schemaVersion === 2 ? definition.outputArtifacts :
        execution.outputs.map((identity, index) => ({ role: 'artifact-' + index, domain: identity.domain, contract: identity.contract })),
    }));
    const binding = json({ schemaVersion: 1, contract: 'psc-observed-action-binding/1',
      actionId: action.identity, executionId, hermeticityVerified: false, authority: 'audit-record-only' },
    'action-binding', 'psc-observed-action-binding/1');
    buildActions.push({ action, binding });
    const declaration = decodeBuildAction(action);
    queryKeys.push(add(createQueryKey({ queryKind: definition.passId, subjectIdentity: execution.inputs[0],
      profileEnvironmentId: profileEnvironment.identity, implementationId: definition.implementationId,
      buildActionId: action.identity, declaredInputs: declaration.exactInputArtifactIds.map((artifactId, index) => ({
        role: 'input-' + index, fingerprintClass: inputClasses[artifactId.domain] ?? 'action-configuration', artifactId,
      })),
    })));
  }
  const toolchain = backendId === 'typescript' ?
    toolchains.find(identity => identity.contract === 'psc-typescript-tool-inputs/1') ??
      toolchains.find(identity => identity.domain === 'typescript-compiler-entry') ?? null : null;
  const interfaceAdapterId = entries.find(entry => entry.identity.contract ===
    (backendId === 'wasm' ? 'psc-wasm-canonical-selection/1' : 'psc-js-abi-host-policy/1'))?.identity ?? null;
  const descriptor = add(createBackendDescriptor(backendRegistry, { backendId, implementationId,
    targetProfileId: targetProfile.identity, externalToolchainId: toolchain, interfaceAdapterId }));
  const products = {};
  for (const group of ['executableArtifacts', 'publicApiArtifacts', 'debugArtifacts', 'interfaceArtifacts']) {
    products[group] = [];
    for (const spec of registration.products[group]) {
      const matches = entries.filter(entry => entry.identity.domain === spec.domain && entry.identity.contract === spec.contract);
      if (matches.length > 1) fail('AMBIGUOUS_PRODUCT');
      if (matches.length) products[group].push({ role: spec.role, artifact: matches[0].identity });
    }
  }
  const claimSet = add(createClaimSet());
  const artifactBundle = add(createArtifactBundle({
    descriptor, sourceSubjectId, profileEnvironmentId: profileEnvironment.identity, claimSetId: claimSet.identity,
    ...products, targetToolchainArtifacts: uniqueIds(toolchains),
    evidenceArtifacts: [...build.graph.executions, ...buildActions.flatMap(item => [item.action.identity, item.binding.identity]), ...queryKeys.map(item => item.identity)],
  }));
  const graph = { ...build.graph, entries }, bytes = canonicalBytes(graph);
  return { ...build, graph, artifacts, bytes, identity: artifactId(bytes, 'build-graph', 'psc-observed-build-graph/1'),
    profileEnvironment, buildActions, queryKeys, backendDescriptor: descriptor, artifactBundle, claimSet };
}

/** Replay the relation from an exact old execution to its V5 declaration.
 * This validates binding only, not execution isolation or semantic preservation.
 */
export async function verifyObservedActionBinding(record, { resolveArtifact } = {}) {
  verifyArtifact(record.bytes, record.identity);
  const value = JSON.parse(record.bytes);
  if (record.identity.domain !== 'action-binding' || record.identity.contract !== 'psc-observed-action-binding/1' ||
      Object.keys(value).sort().join(',') !== 'actionId,authority,contract,executionId,hermeticityVerified,schemaVersion' ||
      value.schemaVersion !== 1 || value.contract !== 'psc-observed-action-binding/1' ||
      value.authority !== 'audit-record-only' || value.hermeticityVerified !== false ||
      !canonicalBytes(value).equals(Buffer.from(record.bytes))) fail('BINDING');
  const resolve = async identity => {
    const bytes = await resolveArtifact(identity); verifyArtifact(bytes, identity); return { identity, bytes };
  };
  const actionRecord = await resolve(value.actionId), action = decodeBuildAction(actionRecord);
  await verifyBuildAction(actionRecord, { expectedActionId: value.actionId, resolveArtifact });
  const execution = JSON.parse((await resolve(value.executionId)).bytes);
  if (value.executionId.domain !== 'pass-execution' || value.executionId.contract !== 'psc-pass-execution/1' ||
      !equal(execution.passDefinitionId, action.passDefinitionId) ||
      !equal(uniqueIds([...execution.inputs, ...execution.action.dependencies, execution.actionId]), action.exactInputArtifactIds) ||
      !equal(execution.action.resourcePolicy, JSON.parse((await resolve(action.resourcePolicyId)).bytes))) fail('EXECUTION_BINDING');
  const definition = JSON.parse((await resolve(execution.passDefinitionId)).bytes);
  const outputs = definition.schemaVersion === 2 ? definition.outputArtifacts :
    execution.outputs.map((identity, index) => ({ role: 'artifact-' + index, domain: identity.domain, contract: identity.contract }));
  if (!equal(outputs, action.outputContracts)) fail('OUTPUT_BINDING');
  return { actionId: value.actionId, executionId: value.executionId,
    bindingVerified: true, hermeticityVerified: false, authority: 'audit-record-only' };
}

/** Archives predating V5 remain readable. Once any V5 product is present the
 * entire context/binding set is mandatory; partial upgrades fail closed.
 */
export async function verifyObservedContextProducts(graph, { resolveArtifact }) {
  const entries = graph.entries;
  const scoped = entries.filter(entry => ['build-action', 'action-binding', 'profile-environment',
    'backend-descriptor', 'artifact-bundle', 'query-key'].includes(entry.identity.domain));
  if (!scoped.length) return { present: false, hermeticityVerified: false };
  const select = domain => entries.filter(entry => entry.identity.domain === domain).map(entry => entry.identity);
  const single = domain => { const ids = select(domain); if (ids.length !== 1) fail('SINGLE_' + domain); return ids[0]; };
  const profileId = single('profile-environment'), bundleId = single('artifact-bundle');
  const descriptorId = single('backend-descriptor'), sourceId = single('source-snapshot');
  const record = async identity => ({ identity, bytes: await resolveArtifact(identity) });
  const bundleRecord = await record(bundleId), bundle = JSON.parse(bundleRecord.bytes);
  const bundleResult = await verifyArtifactBundle(bundleRecord, { expectedBundleId: bundleId, resolveArtifact });
  if (!equal(bundle.profileEnvironmentId, profileId) || !equal(bundle.backendDescriptorId, descriptorId) ||
      !equal(bundle.sourceSubjectId, sourceId)) fail('BUNDLE_BINDING');
  const executions = new Set(graph.executions.map(artifactKey)), actions = new Set(select('build-action').map(artifactKey));
  const coveredExecutions = new Set(), coveredActions = new Set(), bindings = [];
  const evidenceKeys = new Set(bundle.evidenceArtifacts.map(artifactKey));
  for (const bindingId of select('action-binding')) {
    const binding = await verifyObservedActionBinding(await record(bindingId), { resolveArtifact });
    const executionKey = artifactKey(binding.executionId), actionKey = artifactKey(binding.actionId);
    if (!executions.has(executionKey) || !actions.has(actionKey) || coveredExecutions.has(executionKey) ||
        coveredActions.has(actionKey) || ![executionKey, actionKey, artifactKey(bindingId)].every(key => evidenceKeys.has(key))) fail('ACTION_COVERAGE');
    const action = decodeBuildAction(await record(binding.actionId));
    if (!equal(action.profileEnvironmentId, profileId)) fail('ACTION_ENVIRONMENT');
    coveredExecutions.add(executionKey); coveredActions.add(actionKey); bindings.push(binding);
  }
  if (coveredExecutions.size !== executions.size || coveredActions.size !== actions.size) fail('ACTION_COVERAGE');
  const queries = [], queryActions = new Set();
  for (const queryId of select('query-key')) {
    if (!evidenceKeys.has(artifactKey(queryId))) fail('QUERY_EVIDENCE');
    const query = await verifyQueryKey(await record(queryId), { expectedQueryId: queryId, resolveArtifact });
    const key = artifactKey(query.value.buildActionId);
    if (!coveredActions.has(key) || queryActions.has(key)) fail('QUERY_COVERAGE');
    queryActions.add(key);
    const effects = applyPassEffects(query.definition, { semanticProfile: query.semanticProfile });
    queries.push({ queryId, actionId: query.value.buildActionId, effects });
  }
  if (queries.length && queryActions.size !== coveredActions.size) fail('QUERY_COVERAGE');
  return { present: true, profileEnvironmentId: profileId, artifactBundle: bundleResult,
    bindings, queries, queryKeysVerified: queries.length === coveredActions.size,
    hermeticityVerified: false, authority: 'audit-record-only' };
}
