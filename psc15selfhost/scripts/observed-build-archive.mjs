import { artifactId, artifactKey, canonicalBytes, verifyArtifact, verifyPassExecution } from './artifact-evidence.mjs';
import { decodeComparatorJson } from './comparator-export.mjs';

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
      graph.authority !== 'audit-record-only' || graph.coverage !== 'observed-composite-edges' ||
      !Array.isArray(graph.entries) ||
      !Array.isArray(graph.executions) || !graph.executions.length || graph.executions.length > graph.entries.length ||
      !Array.isArray(graph.remaining) || !graph.remaining.every(value => typeof value === 'string')) fail('GRAPH_SCHEMA');
  if (graph.entries.length + 1 > bound.maxArtifacts) fail('RESOURCE_EXHAUSTED');
  const keys = new Set();
  const structuredContracts = new Set(['psc-pass-definition/1', 'psc-pass-execution/1', 'psc-action/1',
    'psc-hosted-compiler-implementation/1', 'psc-acceptance-context/1']);
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
 * No archived path is read/extracted, no tool is executed and no source is loaded.
 * Fresh pass integrity checking does not replay kernel checking or preservation.
 */
export async function verifyObservedBuildArchive(input, { expectedGraphId, allowedAssumptions, resourceLimits } = {}) {
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
    const executions = [];
    for (const identity of graph.executions) {
      const result = await verifyPassExecution({ identity, bytes: resolveArtifact(identity) }, { resolveArtifact, allowedAssumptions });
      executions.push(result);
    }
    return { kind: 'accepted', contract: 'psc-observed-build-verification/1', graphId: archive.graphId,
      acceptanceScope: 'observed-artifact-integrity-only', integrityVerified: true, artifactCount: blobs.size,
      artifactBytes: total, executions, fullInputClosureEstablished: false, semanticClaimsVerified: false,
      preservationVerified: false, authority: 'audit-record-only', releaseAccepted: false };
  } catch (error) {
    return { kind: error.kind === 'resourceExhausted' || /EXHAUSTED/u.test(error.message) ? 'resourceExhausted' : 'rejectedInvalid',
      reason: error.message, authority: 'audit-record-only', releaseAccepted: false };
  }
}
