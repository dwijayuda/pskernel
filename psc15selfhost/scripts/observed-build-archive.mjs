import { verifyObservedContextProducts } from './observed-build-context.mjs';
import { artifactId, artifactKey, canonicalArtifact, canonicalBytes, verifyArtifact, verifyPassExecution } from './artifact-evidence.mjs';
import { decodeComparatorJson } from './comparator-export.mjs';
import { verifySourcePreparationOrigins } from './source-preparation-origins.mjs';
import { decodePublicApi } from './public-api-artifact.mjs';
import { verifyRuntimeInterfaceProjection } from './runtime-interface-artifact.mjs';
import { verifySpecializationCorrespondence } from './specialization-correspondence.mjs';
import { jsAbiArtifactsFromVerifiedIr } from './js-abi-artifact.mjs';
import { verifyWasmCanonicalProjection, verifyWasmCanonicalBinary } from './wasm-canonical-artifact.mjs';
import { replayClosedIrArtifact, replayIrLinkArtifact } from './ir-invariant-replay.mjs';
import { decodeJsIrArtifact, decodeWasmIrArtifact } from './target-ir-artifact.mjs';

const contract = 'psc-observed-build-archive/1';
const defaults = Object.freeze({ maxArchiveBytes: 256 * 1024 * 1024, maxArtifactBytes: 128 * 1024 * 1024,
  maxTotalBytes: 192 * 1024 * 1024, maxArtifacts: 4096, maxGraphBytes: 16 * 1024 * 1024 });
const fail = code => { throw new Error('PSC_BUILD_ARCHIVE_' + code); };
function limits(values = {}) {
  if (Object.keys(values).some(key => !Object.hasOwn(defaults, key))) fail('LIMIT_POLICY');
  const bound = { ...defaults, ...values };
  if (Object.values(bound).some(value => !Number.isSafeInteger(value) || value < 0)) fail('LIMIT_POLICY');
  return bound;
}
function exact(value, fields) {
  if (!value || typeof value !== 'object' || Array.isArray(value) ||
      Object.keys(value).sort().join(',') !== [...fields].sort().join(',')) fail('SCHEMA');
}
function identityKey(identity) {
  exact(identity, ['algorithm', 'schemaVersion', 'domain', 'contract', 'byteLength', 'digest']);
  return artifactKey(identity);
}
function graphValue(bytes, bound) {
  const graph = decodeComparatorJson(bytes, { maxBytes: bound.maxGraphBytes });
  exact(graph, ['schemaVersion', 'contract', 'authority', 'entries', 'executions', 'coverage', 'remaining']);
  if (graph.schemaVersion !== 1 || graph.contract !== 'psc-observed-build-graph/1' ||
      graph.authority !== 'audit-record-only' ||
      !['observed-composite-edges', 'observed-erasure-validation-and-composite-backend-edges',
        'observed-erasure-validation-specialization-and-composite-backend-edges',
        'observed-erasure-validation-specialization-target-ir-and-executable-edges'].includes(graph.coverage) ||
      !Array.isArray(graph.entries) ||
      !Array.isArray(graph.executions) || !graph.executions.length || graph.executions.length > graph.entries.length ||
      !Array.isArray(graph.remaining) || !graph.remaining.every(value => typeof value === 'string')) fail('GRAPH_SCHEMA');
  if (graph.entries.length + 1 > bound.maxArtifacts) fail('RESOURCE_EXHAUSTED');
  const keys = new Set();
  const structuredContracts = new Set(['psc-pass-definition/1', 'psc-pass-definition/2', 'psc-pass-execution/1', 'psc-action/1',
    'psc-query-key/1', 'psc-profile-environment/1', 'psc-extension-set/1', 'psc-build-action/1', 'psc-observed-action-binding/1',
    'psc-artifact-bundle/1', 'psc-backend-descriptor/1', 'psc-claim-set/1',
    'psc-hosted-compiler-implementation/1', 'psc-acceptance-context/1', 'psc-typescript-tool-inputs/1', 'psc-checked-provider-inputs/1']);
  for (const entry of graph.entries) {
    exact(entry, Object.hasOwn(entry, 'canonicalValue') ? ['identity', 'source', 'canonicalValue'] : ['identity', 'source']);
    const key = identityKey(entry.identity);
    if (keys.has(key)) fail('DUPLICATE_GRAPH_ENTRY'); keys.add(key);
    if (!['archive-required', 'inline', 'output-file', 'repository-file'].includes(entry.source?.kind)) fail('SOURCE_SCHEMA');
    if (structuredContracts.has(entry.identity.contract) && !Object.hasOwn(entry, 'canonicalValue')) fail('STRUCTURED_RECORD_REQUIRED');
    if (Object.hasOwn(entry, 'canonicalValue')) verifyArtifact(canonicalBytes(entry.canonicalValue), entry.identity);
  }
  const executions = new Set();
  for (const id of graph.executions) {
    const key = identityKey(id);
    if (!keys.has(key) || executions.has(key) || id.domain !== 'pass-execution' || id.contract !== 'psc-pass-execution/1') fail('EXECUTION_SCHEMA');
    executions.add(key);
  }
  // The graph and its inline structured records must resolve every ArtifactId.
  // Opaque input/output bytes remain opaque; no claim of tool discovery follows.
  const pending = [graph]; let nodes = 0;
  while (pending.length) {
    if (++nodes > 1000000) fail('RESOURCE_EXHAUSTED');
    const value = pending.pop();
    if (!value || typeof value !== 'object') continue;
    if (!Array.isArray(value) && Object.hasOwn(value, 'algorithm') && Object.hasOwn(value, 'digest') && Object.hasOwn(value, 'byteLength')) {
      if (!keys.has(identityKey(value))) fail('UNLISTED_ARTIFACT_REFERENCE');
    } else for (const item of Object.values(value)) pending.push(item);
  }
  return graph;
}

/** Capture the exact already observed graph bytes and all listed byte snapshots.
 * This is data packaging, never a claim that hidden tool inputs were discovered.
 */
export function packObservedBuildArchive(build, resourceLimits) {
  const bound = limits(resourceLimits);
  if (!(build.bytes instanceof Uint8Array) || build.bytes.byteLength > bound.maxGraphBytes) fail('RESOURCE_EXHAUSTED');
  verifyArtifact(build.bytes, build.identity);
  if (build.identity.domain !== 'build-graph' || build.identity.contract !== 'psc-observed-build-graph/1') fail('GRAPH_ID');
  const graph = graphValue(build.bytes, bound), items = new Map(); let total = 0;
  for (const id of [build.identity, ...graph.entries.map(entry => entry.identity)]) {
    const key = identityKey(id), input = key === artifactKey(build.identity) ? build.bytes : build.artifacts.get(key);
    if (items.has(key)) fail('DUPLICATE_GRAPH_ENTRY');
    if (!(input instanceof Uint8Array)) fail('MISSING_ARTIFACT');
    if (input.byteLength > bound.maxArtifactBytes || total + input.byteLength > bound.maxTotalBytes) fail('RESOURCE_EXHAUSTED');
    const bytes = Buffer.from(input); verifyArtifact(bytes, id); total += bytes.length;
    items.set(key, { identity: id, data: bytes.toString('base64') });
  }
  if (items.size > bound.maxArtifacts) fail('RESOURCE_EXHAUSTED');
  const bytes = canonicalBytes({ contract, graphId: build.identity,
    artifacts: [...items].sort(([a], [b]) => a < b ? -1 : a > b ? 1 : 0).map(([, item]) => item) },
  { maxBytes: bound.maxArchiveBytes });
  return { bytes, identity: artifactId(bytes, 'observed-build-archive', contract) };
}

/** Consumer supplies the expected graph identity and allowed assumptions.
 * No archived path is read/extracted and no source is loaded. Optional closed-IR
 * replay runs only the validator explicitly selected and pinned by the caller.
 * Fresh pass integrity checking does not replay kernel checking or preservation.
 */
export async function verifyObservedBuildArchive(input, { expectedGraphId, allowedAssumptions, resourceLimits, irValidation, irLinkValidation } = {}) {
  try {
    const bound = limits(resourceLimits), expectedKey = identityKey(expectedGraphId);
    if (!Array.isArray(allowedAssumptions) || allowedAssumptions.some(id => typeof id !== 'string' || !id) ||
        new Set(allowedAssumptions).size !== allowedAssumptions.length) fail('ASSUMPTION_POLICY');
    if (!(input instanceof Uint8Array) || input.byteLength > bound.maxArchiveBytes) fail('RESOURCE_EXHAUSTED');
    const archive = decodeComparatorJson(Buffer.from(input), { maxBytes: bound.maxArchiveBytes });
    exact(archive, ['contract', 'graphId', 'artifacts']);
    if (archive.contract !== contract || identityKey(archive.graphId) !== expectedKey ||
        archive.graphId.domain !== 'build-graph' || archive.graphId.contract !== 'psc-observed-build-graph/1') fail('GRAPH_ID');
    if (!Array.isArray(archive.artifacts) || archive.artifacts.length > bound.maxArtifacts) fail('RESOURCE_EXHAUSTED');
    const blobs = new Map(); let total = 0, previous = '';
    for (const item of archive.artifacts) {
      exact(item, ['identity', 'data']); const key = identityKey(item.identity), size = item.identity.byteLength;
      if (key <= previous) fail('ARTIFACT_ORDER_OR_DUPLICATE'); previous = key;
      if (size > bound.maxArtifactBytes || total + size > bound.maxTotalBytes) fail('RESOURCE_EXHAUSTED');
      if (typeof item.data !== 'string' || item.data.length !== Math.ceil(size / 3) * 4) fail('BASE64');
      const bytes = Buffer.from(item.data, 'base64');
      if (bytes.toString('base64') !== item.data) fail('BASE64');
      verifyArtifact(bytes, item.identity); total += bytes.length; blobs.set(key, bytes);
    }
    const resolveArtifact = id => {
      const bytes = blobs.get(identityKey(id)); if (!bytes) fail('MISSING_ARTIFACT'); return bytes;
    };
    const graph = graphValue(resolveArtifact(archive.graphId), bound);
    if (graph.entries.length + 1 !== blobs.size) fail('ARTIFACT_SET');
    for (const entry of graph.entries) resolveArtifact(entry.identity);
    const buildContext = await verifyObservedContextProducts(graph, { resolveArtifact });
    const irInvariantReplays = [], irLinkInvariantReplays = [];
    if (irValidation !== undefined && irLinkValidation !== undefined) fail('IR_VALIDATION_POLICY');
    if (irLinkValidation !== undefined) {
      if (!Array.isArray(irLinkValidation.artifacts) || !irLinkValidation.artifacts.length ||
          irLinkValidation.artifacts.length > bound.maxArtifacts) fail('IR_LINK_POLICY');
      const subjects = graph.entries.filter(entry =>
        ['verified-ir', 'specialized-ir'].includes(entry.identity.domain));
      if (!subjects.length) fail('IR_VALIDATION_SUBJECT_REQUIRED');
      const covered = new Set();
      let contextBytes = 0;
      for (const artifact of irLinkValidation.artifacts) {
        if (!(artifact?.bytes instanceof Uint8Array) ||
            artifact.bytes.byteLength > bound.maxArtifactBytes) fail('IR_LINK_CONTEXT');
        contextBytes += artifact.bytes.byteLength;
        if (contextBytes > bound.maxTotalBytes) fail('RESOURCE_EXHAUSTED');
        const replay = await replayIrLinkArtifact(artifact, irLinkValidation.validator);
        if (replay.kind !== 'accepted') return { kind: replay.kind, reason: replay.reason ?? replay.resource,
          irLinkInvariantReplays, authority: 'audit-record-only', releaseAccepted: false,
          linkedIrInvariantsVerified: false, preservationVerified: false };
        irLinkInvariantReplays.push(replay);
        for (const { identity } of subjects) {
          // The same canonical runtime representation serves distinct stage domains.
          // Coverage binds exact bytes; it never promotes a stage or source authority.
          if (replay.modules.some(({ irId }) =>
              irId.algorithm === identity.algorithm && irId.schemaVersion === identity.schemaVersion &&
              irId.contract === identity.contract && irId.byteLength === identity.byteLength &&
              irId.digest === identity.digest)) covered.add(artifactKey(identity));
        }
      }
      if (subjects.some(({ identity }) => !covered.has(artifactKey(identity)))) fail('IR_LINK_SUBJECT_UNCOVERED');
    }
    if (irValidation !== undefined) {
      const subjects = graph.entries.filter(entry =>
        ['verified-ir', 'specialized-ir'].includes(entry.identity.domain));
      if (!subjects.length) fail('IR_VALIDATION_SUBJECT_REQUIRED');
      for (const { identity } of subjects) {
        const replay = await replayClosedIrArtifact({ identity, bytes: resolveArtifact(identity) }, irValidation);
        if (replay.kind !== 'accepted') return { kind: replay.kind, reason: replay.reason ?? replay.resource,
          irInvariantReplays, authority: 'audit-record-only', releaseAccepted: false,
          closedIrInvariantsVerified: false, preservationVerified: false };
        irInvariantReplays.push(replay);
      }
    }
    const executions = [], runtimeInterfaceProjections = [], specializationCorrespondences = [], jsAbiPlans = [], targetIrArtifacts = [], wasmCanonicalProjections = [], wasmCanonicalSignatures = [];
    for (const identity of graph.executions) {
      const result = await verifyPassExecution({ identity, bytes: resolveArtifact(identity) }, { resolveArtifact, allowedAssumptions });
      executions.push(result);
      const execution = JSON.parse(resolveArtifact(identity));
      const definition = JSON.parse(resolveArtifact(execution.passDefinitionId));
      if (definition.passId === 'psc-source-preparation-origins/1') {
        if (execution.inputs.length !== 1 || execution.outputs.length !== 1 ||
            definition.semanticRelationId !== 'psc-source-preparation-origin-projection/1') fail('SOURCE_ORIGIN_SUBJECT');
        await verifySourcePreparationOrigins({ identity: execution.outputs[0], bytes: resolveArtifact(execution.outputs[0]) },
          { expectedSourceId: execution.inputs[0], resolveArtifact, maxBytes: bound.maxArtifactBytes });
      }
      if (definition.passId === 'psc-project-public-api/1') {
        if (execution.inputs.length !== 1 || execution.outputs.length !== 1 ||
            execution.inputs[0].domain !== 'certified-source' || execution.inputs[0].contract !== 'psc-certified-source/1' ||
            execution.outputs[0].domain !== 'public-api' || execution.outputs[0].contract !== 'psc-public-api-ir/1' ||
            definition.semanticRelationId !== 'psc-source-public-api-projection/1') fail('PUBLIC_API_SUBJECT');
        // Decode the exact output, without promoting the trusted projection to
        // independent Core correspondence or executable export evidence.
        decodePublicApi(resolveArtifact(execution.outputs[0]), { maxBytes: bound.maxArtifactBytes });
      }
      if (definition.passId === 'psc-project-runtime-interface/1') {
        if (execution.inputs.length !== 1 || execution.outputs.length !== 1 ||
            definition.semanticRelationId !== 'psc-runtime-interface-projection/1') fail('INTERFACE_PROJECTION_SUBJECT');
        runtimeInterfaceProjections.push(verifyRuntimeInterfaceProjection(
          { identity: execution.inputs[0], bytes: resolveArtifact(execution.inputs[0]) },
          { identity: execution.outputs[0], bytes: resolveArtifact(execution.outputs[0]) }, { maxBytes: bound.maxArtifactBytes }));
      }
      if (definition.passId === 'psc-pass-specialize/1') {
        if (execution.inputs.length !== 1 || execution.outputs.length !== 1 ||
            definition.semanticRelationId !== 'psc-specialization-runtime-refinement/1') fail('SPECIALIZATION_SUBJECT');
        specializationCorrespondences.push(verifySpecializationCorrespondence(
          { identity: execution.inputs[0], bytes: resolveArtifact(execution.inputs[0]) },
          { identity: execution.outputs[0], bytes: resolveArtifact(execution.outputs[0]) }, { maxBytes: bound.maxArtifactBytes }));
      }
      if (definition.passId === 'psc-specialized-ir-to-js-ir/1') {
        if (execution.inputs.length !== 1 || execution.outputs.length !== 1 ||
            definition.semanticRelationId !== 'psc-specialized-ir-js-ir/1') fail('JS_IR_SUBJECT');
        decodeJsIrArtifact(resolveArtifact(execution.outputs[0]), { maxBytes: bound.maxArtifactBytes });
        targetIrArtifacts.push(Object.freeze({ kind: 'js-ir', inputId: execution.inputs[0], outputId: execution.outputs[0] }));
      }
      if (definition.passId === 'psc-specialized-ir-to-wasm-ir/1') {
        if (execution.inputs.length !== 1 || execution.outputs.length !== 1 ||
            definition.semanticRelationId !== 'psc-specialized-ir-wasm-ir/1') fail('WASM_IR_SUBJECT');
        decodeWasmIrArtifact(resolveArtifact(execution.outputs[0]), { maxBytes: bound.maxArtifactBytes });
        targetIrArtifacts.push(Object.freeze({ kind: 'wasm-ir', inputId: execution.inputs[0], outputId: execution.outputs[0] }));
      }
      if (definition.passId === 'psc-specialized-ir-to-canonical-interface/1') {
        if (execution.inputs.length !== 1 || execution.outputs.length !== 2 ||
            definition.semanticRelationId !== 'psc-specialized-ir-canonical-scalar-interface/1' ||
            !execution.action?.parameters?.selectionId) fail('WASM_CANONICAL_PROJECTION_SUBJECT');
        const subject = id => ({ identity: id, bytes: resolveArtifact(id) });
        wasmCanonicalProjections.push(verifyWasmCanonicalProjection({
          specializedIr: subject(execution.inputs[0]), selection: subject(execution.action.parameters.selectionId),
          interfaceArtifact: subject(execution.outputs[0]), binding: subject(execution.outputs[1]),
        }, { maxBytes: bound.maxArtifactBytes }));
      }
      if (definition.passId === 'psc-check-canonical-wasm-exports/1') {
        const parameters = execution.action?.parameters;
        if (execution.inputs.length !== 1 || execution.outputs.length !== 1 ||
            definition.semanticRelationId !== 'psc-wasm-canonical-scalar-export-signatures/1' ||
            !parameters?.interfaceId || !parameters?.bindingId || !parameters?.targetIrId)
          fail('WASM_CANONICAL_BINARY_SUBJECT');
        const subject = id => ({ identity: id, bytes: resolveArtifact(id) });
        const result = verifyWasmCanonicalBinary({ binary: subject(execution.inputs[0]),
          interfaceArtifact: subject(parameters.interfaceId), binding: subject(parameters.bindingId),
          targetIr: subject(parameters.targetIrId),
        }, { ir: { maxBytes: bound.maxArtifactBytes } });
        const expected = canonicalArtifact(result, 'adapter-validation', 'psc-wasm-canonical-signatures-validation/1');
        if (artifactKey(expected.identity) !== artifactKey(execution.outputs[0])) fail('WASM_CANONICAL_BINARY_RELATION');
        wasmCanonicalSignatures.push(result);
      }
      if (definition.passId === 'psc-verified-ir-to-js-abi-plan/1') {
        if (execution.inputs.length !== 1 || execution.outputs.length !== 1 ||
            definition.semanticRelationId !== 'psc-verified-ir-js-scalar-abi-plan/1' ||
            !execution.action?.parameters?.policyId) fail('JS_ABI_SUBJECT');
        const policyId = execution.action.parameters.policyId;
        const policyBytes = resolveArtifact(policyId);
        verifyArtifact(policyBytes, policyId);
        const policy = JSON.parse(policyBytes);
        const derived = jsAbiArtifactsFromVerifiedIr(
          { identity: execution.inputs[0], bytes: resolveArtifact(execution.inputs[0]) },
          policy, { maxBytes: bound.maxArtifactBytes });
        if (artifactKey(derived.policy.identity) !== artifactKey(policyId) ||
            artifactKey(derived.plan.identity) !== artifactKey(execution.outputs[0])) fail('JS_ABI_RELATION');
        jsAbiPlans.push(Object.freeze({ inputId: execution.inputs[0], policyId,
          planId: execution.outputs[0], relation: derived.relation, authority: derived.authority }));
      }
    }
    return { kind: 'accepted', contract: 'psc-observed-build-verification/1', graphId: archive.graphId,
      acceptanceScope: irLinkValidation !== undefined ? 'observed-artifact-integrity-and-linked-ir-invariants' :
        irValidation === undefined ? 'observed-artifact-integrity-only' : 'observed-artifact-integrity-and-closed-ir-invariants',
      linkedIrInvariantsVerified: irLinkValidation !== undefined, irLinkInvariantReplays,
      closedIrInvariantsVerified: irValidation !== undefined, irInvariantReplays, integrityVerified: true, artifactCount: blobs.size,
      artifactBytes: total, executions, runtimeInterfaceProjections, specializationCorrespondences, jsAbiPlans, targetIrArtifacts, wasmCanonicalProjections, wasmCanonicalSignatures,
      buildContext, fullInputClosureEstablished: false, semanticClaimsVerified: false,
      preservationVerified: false, authority: 'audit-record-only', releaseAccepted: false };
  } catch (error) {
    return { kind: error.kind === 'resourceExhausted' || /EXHAUSTED/u.test(error.message) ? 'resourceExhausted' : 'rejectedInvalid',
      reason: error.message, authority: 'audit-record-only', releaseAccepted: false };
  }
}
