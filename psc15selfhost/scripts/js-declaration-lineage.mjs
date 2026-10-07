import { artifactKey, canonicalArtifact, verifyArtifact } from './artifact-evidence.mjs';
import { decodeComparatorJson } from './comparator-export.mjs';
import { createDeclarationOriginGraph, originGraphContract } from './declaration-origins.mjs';
import { createErasureDeclarationMap, erasureDeclarationMapContract } from './erasure-declarations.mjs';
import { createSpecializationInstanceMap, specializationInstanceMapContract } from './specialization-correspondence.mjs';
import { createJsGeneratedPositionMap, jsGeneratedPositionMapContract } from './js-generated-positions.mjs';
import { decodeIrArtifact } from './ir-artifact.mjs';
import { decodeJsIrArtifact } from './target-ir-artifact.mjs';

export const jsDeclarationLineageContract = 'psc-js-declaration-lineage/1';
const fail = code => { throw new Error('PSC_JS_LINEAGE_' + code); };
const same = (a, b) => artifactKey(a) === artifactKey(b);
const parentKinds = Object.freeze({
  originGraphId: ['origin-graph', originGraphContract],
  erasureMapId: ['erasure-map', erasureDeclarationMapContract],
  specializationMapId: ['specialization-map', specializationInstanceMapContract],
  generatedPositionMapId: ['generated-position-map', jsGeneratedPositionMapContract],
  verifiedIrId: ['verified-ir', 'psc-runtime-ir-json/1'],
});
const utf8 = bytes => new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }).decode(bytes);
function limits(maxBytes, maxTotalBytes) {
  if (![maxBytes, maxTotalBytes].every(n => Number.isSafeInteger(n) && n > 0)) fail('RESOURCE_POLICY');
}
function parentIds(parents) {
  if (!parents || Object.keys(parents).sort().join(',') !== Object.keys(parentKinds).sort().join(',')) fail('PARENTS');
  for (const [key, [domain, contract]] of Object.entries(parentKinds)) {
    if (parents[key]?.domain !== domain || parents[key]?.contract !== contract) fail('PARENT_KIND');
    artifactKey(parents[key]);
  }
}
function decode(record, maxBytes) {
  return decodeComparatorJson(record.bytes, { maxBytes, maxDepth: 512, maxNodes: 2000000 });
}
// A fixed two-level dependency layout. Never follow arbitrary references or
// producer-provided recursive graphs, and charge each distinct artifact once.
function childIds(origin, erasure, specialization, positions) {
  if (!Array.isArray(origin?.sourceIds) || origin.sourceIds.length > 4096) fail('SOURCE_COUNT');
  return [...origin.sourceIds, origin.publicApiId, origin.tableId,
    erasure.publicApiId, erasure.runtimeIrId, erasure.tableId,
    specialization.inputId, specialization.outputId,
    positions.jsIrId, positions.javascriptId, positions.tableId];
}

/** Reconstruct each metadata parent, then join exact ordered inventories.
 * The source and erasure tables are observations of the actual compiler;
 * checking their composition is not independent erasure/body preservation.
 */
export function createJsDeclarationLineage({ parents, resolveArtifact,
  maxBytes = 128 * 1024 * 1024, maxTotalBytes = 512 * 1024 * 1024 }) {
  limits(maxBytes, maxTotalBytes); parentIds(parents);
  const cache = new Map(); let total = 0;
  function resolve(identity) {
    const key = artifactKey(identity);
    if (cache.has(key)) return cache.get(key);
    if (identity.byteLength > maxBytes || (total += identity.byteLength) > maxTotalBytes || cache.size >= 4120) fail('RESOURCE');
    const bytes = resolveArtifact(identity);
    if (!(bytes instanceof Uint8Array)) fail('SYNCHRONOUS_BYTES_REQUIRED');
    verifyArtifact(bytes, identity);
    const record = { identity, bytes: Buffer.from(bytes) }; cache.set(key, record); return record;
  }
  const originRecord = resolve(parents.originGraphId), erasureRecord = resolve(parents.erasureMapId);
  const specializationRecord = resolve(parents.specializationMapId), positionsRecord = resolve(parents.generatedPositionMapId);
  const verifiedIr = resolve(parents.verifiedIrId);
  const origin = decode(originRecord, maxBytes), erasure = decode(erasureRecord, maxBytes);
  const specialization = decode(specializationRecord, maxBytes), positions = decode(positionsRecord, maxBytes);
  for (const id of childIds(origin, erasure, specialization, positions)) resolve(id);
  if (!same(origin.publicApiId, erasure.publicApiId) || !same(specialization.inputId, verifiedIr.identity)) fail('CHAIN_SUBJECT');
  const publicApi = resolve(origin.publicApiId), runtimeIr = resolve(erasure.runtimeIrId);
  const specializedIr = resolve(specialization.outputId), jsIr = resolve(positions.jsIrId);
  if (!runtimeIr.bytes.equals(verifiedIr.bytes)) fail('VALIDATION_CHANGED_IR');
  const sources = origin.sourceIds.map(id => utf8(resolve(id).bytes));
  const rebuiltOrigin = createDeclarationOriginGraph({
    table: resolve(origin.tableId).bytes, sources, publicApi, maxBytes }).graph;
  const rebuiltErasure = createErasureDeclarationMap({
    table: resolve(erasure.tableId).bytes, publicApi, runtimeIr, maxBytes }).map;
  const rebuiltSpecialization = createSpecializationInstanceMap(verifiedIr, specializedIr, { maxBytes }).map;
  const rebuiltPositions = createJsGeneratedPositionMap({
    table: resolve(positions.tableId).bytes, javaScript: utf8(resolve(positions.javascriptId).bytes), jsIr, maxBytes }).map;
  for (const [rebuilt, supplied] of [[rebuiltOrigin, originRecord], [rebuiltErasure, erasureRecord],
      [rebuiltSpecialization, specializationRecord], [rebuiltPositions, positionsRecord]]) {
    if (!same(rebuilt.identity, supplied.identity)) fail('PARENT_BINDING');
  }
  const specialized = decodeIrArtifact(specializedIr.bytes, { maxBytes }), target = decodeJsIrArtifact(jsIr.bytes, { maxBytes });
  if (specialized[4].length !== target[2].length) fail('TARGET_DECLARATION_COVERAGE');
  // The current JS lowerer preserves declaration/parameter names and order.
  // This deliberately checks only that boundary's inventory, not its bodies.
  for (let index = 0; index < target[2].length; index++) {
    const a = specialized[4][index], b = target[2][index];
    if (a[0] !== b[0] || a[2].length !== b[1].length ||
        a[2].some((parameter, i) => parameter[0] !== b[1][i])) fail('TARGET_DECLARATION_INVENTORY');
  }
  const erasureEntries = decode(resolve(erasure.tableId), maxBytes)[2];
  const sourceEntries = decode(resolve(origin.tableId), maxBytes)[3];
  const instanceEntries = decode(rebuiltSpecialization, maxBytes).instances;
  const generatedEntries = decode(resolve(positions.tableId), maxBytes)[2];
  const runtimeOwners = new Map(), instanceOwners = new Map();
  erasureEntries.forEach((entry, index) => {
    if (entry[1][0] === 'runtime') runtimeOwners.set(entry[1][1], index);
  });
  instanceEntries.forEach((entry, index) => {
    if (entry[0] === 'declaration') instanceOwners.set(entry[3], index);
  });
  const edges = generatedEntries.map((entry, generatedIndex) => {
    const instanceIndex = instanceOwners.get(entry[0]);
    const sourceIndex = runtimeOwners.get(instanceEntries[instanceIndex]?.[1]);
    if (instanceIndex === undefined || sourceIndex === undefined || !sourceEntries[sourceIndex]) fail('UNOWNED_DECLARATION');
    // Both reconstructed source tables cover the exact same API inventory.
    return [generatedIndex, instanceIndex, sourceIndex, sourceIndex];
  });
  const lineage = canonicalArtifact({ schemaVersion: 1, contract: jsDeclarationLineageContract,
    ...parents, edges, edgeOrder: 'generated-position-specialization-instance-erasure-entry-source-origin-entry',
    granularity: 'declaration-batch-to-emission-chunk', targetInventoryChecked: true,
    expressionCorrespondenceChecked: false, semanticPreservationProved: false,
    authority: 'debug-metadata-only' }, 'declaration-lineage', jsDeclarationLineageContract);
  if (lineage.bytes.byteLength > maxBytes || total + lineage.bytes.byteLength > maxTotalBytes) fail('RESOURCE');
  return { lineage, artifacts: [...cache.values()] };
}

/** Load the fixed subject closure for any async consumer. Loading alone is
 * not validation: consumers must reconstruct the lineage before using edges.
 */
export async function loadJsDeclarationLineageSubjects(record, { resolveArtifact, expectedParents,
  maxBytes = 128 * 1024 * 1024, maxTotalBytes = 512 * 1024 * 1024 } = {}) {
  limits(maxBytes, maxTotalBytes);
  verifyArtifact(record.bytes, record.identity);
  if (record.identity.domain !== 'declaration-lineage' || record.identity.contract !== jsDeclarationLineageContract) fail('IDENTITY');
  const value = decode(record, maxBytes);
  const parents = Object.fromEntries(Object.keys(parentKinds).map(key => [key, value[key]]));
  parentIds(parents);
  if (expectedParents !== undefined) {
    parentIds(expectedParents);
    for (const key of Object.keys(parentKinds)) if (!same(parents[key], expectedParents[key])) fail('PARENT_SUBJECT');
  }
  const cache = new Map(); let total = record.bytes.byteLength;
  async function resolve(identity) {
    const key = artifactKey(identity);
    if (cache.has(key)) return cache.get(key);
    if (identity.byteLength > maxBytes || (total += identity.byteLength) > maxTotalBytes || cache.size >= 4120) fail('RESOURCE');
    const bytes = await resolveArtifact(identity); verifyArtifact(bytes, identity);
    const artifact = { bytes, identity }; cache.set(key, artifact); return artifact;
  }
  for (const id of Object.values(parents)) await resolve(id);
  const parent = key => decode(cache.get(artifactKey(parents[key])), maxBytes);
  for (const id of childIds(parent('originGraphId'), parent('erasureMapId'),
      parent('specializationMapId'), parent('generatedPositionMapId'))) await resolve(id);
  return { parents, artifacts: [...cache.values()] };
}

/** Replay requires caller-pinned parents and reconstruction of every edge. */
export async function verifyJsDeclarationLineage(record, { resolveArtifact, expectedParents,
  maxBytes = 128 * 1024 * 1024, maxTotalBytes = 512 * 1024 * 1024 } = {}) {
  parentIds(expectedParents);
  const loaded = await loadJsDeclarationLineageSubjects(record, { resolveArtifact, expectedParents, maxBytes, maxTotalBytes });
  for (const key of Object.keys(parentKinds)) if (!same(loaded.parents[key], expectedParents[key])) fail('PARENT_SUBJECT');
  const cache = new Map(loaded.artifacts.map(item => [artifactKey(item.identity), item.bytes]));
  const rebuilt = createJsDeclarationLineage({ parents: expectedParents, maxBytes, maxTotalBytes,
    resolveArtifact: id => cache.get(artifactKey(id)) });
  if (!same(rebuilt.lineage.identity, record.identity)) fail('BINDING');
  return { contract: jsDeclarationLineageContract, declarationCompositionChecked: true,
    targetInventoryChecked: true, granularity: 'declaration-batch-to-emission-chunk',
    expressionCorrespondenceChecked: false, semanticPreservationProved: false, authority: 'debug-metadata-only' };
}
