import { closedJsRepresentationProfile, uniformJsRepresentationProfile, uniformSpecializationContract, verifyUniformSpecialization } from './uniform-specialization.mjs';
import { artifactKey, canonicalArtifact, verifyArtifact } from './artifact-evidence.mjs';
import { decodeComparatorJson } from './comparator-export.mjs';
import { createDeclarationOriginGraph, originGraphContract } from './declaration-origins.mjs';
import { createErasureDeclarationMap, erasureDeclarationMapContract } from './erasure-declarations.mjs';
import { createSpecializationInstanceMap, specializationInstanceMapContract } from './specialization-correspondence.mjs';
import { createJsGeneratedPositionMap, jsGeneratedPositionMapContract } from './js-generated-positions.mjs';
import { decodeIrArtifact } from './ir-artifact.mjs';
import { decodeJsIrArtifact, assertJsDeclarationInventory } from './target-ir-artifact.mjs';

export const jsDeclarationLineageContract = 'psc-js-declaration-lineage/1';
export const jsUniformDeclarationLineageContract = 'psc-js-uniform-declaration-lineage/1';
const fail = code => { throw new Error('PSC_JS_LINEAGE_' + code); };
const same = (a, b) => artifactKey(a) === artifactKey(b);
const commonParentKinds = Object.freeze({
  originGraphId: ['origin-graph', originGraphContract],
  erasureMapId: ['erasure-map', erasureDeclarationMapContract],
  generatedPositionMapId: ['generated-position-map', jsGeneratedPositionMapContract],
  verifiedIrId: ['verified-ir', 'psc-runtime-ir-json/1'],
});
const utf8 = bytes => new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }).decode(bytes);
function limits(maxBytes, maxTotalBytes) {
  if (![maxBytes, maxTotalBytes].every(n => Number.isSafeInteger(n) && n > 0)) fail('RESOURCE_POLICY');
}
export function jsDeclarationLineageProfile(contract) {
  if (contract === jsDeclarationLineageContract) return closedJsRepresentationProfile;
  if (contract === jsUniformDeclarationLineageContract) return uniformJsRepresentationProfile;
  fail('IDENTITY');
}
function parentKinds(profile) {
  if (![closedJsRepresentationProfile, uniformJsRepresentationProfile].includes(profile)) fail('PROFILE');
  return { ...commonParentKinds, ...(profile === uniformJsRepresentationProfile ?
    { uniformSpecializedIrId: ['uniform-specialized-ir', uniformSpecializationContract] } :
    { specializationMapId: ['specialization-map', specializationInstanceMapContract] }) };
}
export function jsDeclarationLineageParentKeys(profile) { return Object.keys(parentKinds(profile)); }
function parentIds(parents, profile) {
  const kinds = parentKinds(profile);
  if (!parents || Object.keys(parents).sort().join(',') !== Object.keys(kinds).sort().join(',')) fail('PARENTS');
  for (const [key, [domain, contract]] of Object.entries(kinds)) {
    if (parents[key]?.domain !== domain || parents[key]?.contract !== contract) fail('PARENT_KIND');
    artifactKey(parents[key]);
  }
}
function decode(record, maxBytes) {
  return decodeComparatorJson(record.bytes, { maxBytes, maxDepth: 512, maxNodes: 2000000 });
}
// A fixed two-level dependency layout. Never follow arbitrary references or
// producer-provided recursive graphs, and charge each distinct artifact once.
function childIds(origin, erasure, specialization, positions, uniform) {
  if (!Array.isArray(origin?.sourceIds) || origin.sourceIds.length > 4096) fail('SOURCE_COUNT');
  return [...origin.sourceIds, origin.publicApiId, origin.tableId,
    erasure.publicApiId, erasure.runtimeIrId, erasure.tableId,
    ...(uniform ? [] : [specialization.inputId, specialization.outputId]),
    positions.jsIrId, positions.javascriptId, positions.tableId];
}

/** Reconstruct each metadata parent, then join exact ordered inventories.
 * The source and erasure tables are observations of the actual compiler;
 * checking their composition is not independent erasure/body preservation.
 */
export function createJsDeclarationLineage({ parents, resolveArtifact, profile = closedJsRepresentationProfile,
  maxBytes = 128 * 1024 * 1024, maxTotalBytes = 512 * 1024 * 1024 }) {
  limits(maxBytes, maxTotalBytes); parentIds(parents, profile);
  const uniform = profile === uniformJsRepresentationProfile;
  const contract = uniform ? jsUniformDeclarationLineageContract : jsDeclarationLineageContract;
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
  const selectionRecord = resolve(uniform ? parents.uniformSpecializedIrId : parents.specializationMapId);
  const positionsRecord = resolve(parents.generatedPositionMapId);
  const verifiedIr = resolve(parents.verifiedIrId);
  const origin = decode(originRecord, maxBytes), erasure = decode(erasureRecord, maxBytes);
  const specialization = uniform ? null : decode(selectionRecord, maxBytes), positions = decode(positionsRecord, maxBytes);
  for (const id of childIds(origin, erasure, specialization, positions, uniform)) resolve(id);
  if (!same(origin.publicApiId, erasure.publicApiId) || (!uniform && !same(specialization.inputId, verifiedIr.identity))) fail('CHAIN_SUBJECT');
  if (uniform) verifyUniformSpecialization(verifiedIr, selectionRecord, { maxBytes });
  const publicApi = resolve(origin.publicApiId), runtimeIr = resolve(erasure.runtimeIrId);
  const selectedIr = uniform ? verifiedIr : resolve(specialization.outputId), jsIr = resolve(positions.jsIrId);
  if (!runtimeIr.bytes.equals(verifiedIr.bytes)) fail('VALIDATION_CHANGED_IR');
  const sources = origin.sourceIds.map(id => utf8(resolve(id).bytes));
  const rebuiltOrigin = createDeclarationOriginGraph({
    table: resolve(origin.tableId).bytes, sources, publicApi, maxBytes }).graph;
  const rebuiltErasure = createErasureDeclarationMap({
    table: resolve(erasure.tableId).bytes, publicApi, runtimeIr, maxBytes }).map;
  const rebuiltSpecialization = uniform ? null : createSpecializationInstanceMap(verifiedIr, selectedIr, { maxBytes }).map;
  const rebuiltPositions = createJsGeneratedPositionMap({
    table: resolve(positions.tableId).bytes, javaScript: utf8(resolve(positions.javascriptId).bytes), jsIr, maxBytes }).map;
  for (const [rebuilt, supplied] of [[rebuiltOrigin, originRecord], [rebuiltErasure, erasureRecord],
      ...(uniform ? [] : [[rebuiltSpecialization, selectionRecord]]), [rebuiltPositions, positionsRecord]]) {
    if (!same(rebuilt.identity, supplied.identity)) fail('PARENT_BINDING');
  }
  const selected = decodeIrArtifact(selectedIr.bytes, { maxBytes }), target = decodeJsIrArtifact(jsIr.bytes, { maxBytes });
  assertJsDeclarationInventory(selected, target);
  const erasureEntries = decode(resolve(erasure.tableId), maxBytes)[2];
  const sourceEntries = decode(resolve(origin.tableId), maxBytes)[3];
  const generatedEntries = decode(resolve(positions.tableId), maxBytes)[2];
  const runtimeOwners = new Map(), representationOwners = new Map();
  erasureEntries.forEach((entry, index) => {
    if (entry[1][0] === 'runtime') runtimeOwners.set(entry[1][1], index);
  });
  if (uniform) {
    selected[4].forEach((declaration, index) =>
      representationOwners.set(declaration[0], { runtimeName: declaration[0], index }));
  } else {
    decode(rebuiltSpecialization, maxBytes).instances.forEach((entry, index) => {
      if (entry[0] === 'declaration') representationOwners.set(entry[3], { runtimeName: entry[1], index });
    });
  }
  const edges = generatedEntries.map((entry, generatedIndex) => {
    const owner = representationOwners.get(entry[0]);
    const sourceIndex = runtimeOwners.get(owner?.runtimeName);
    if (!owner || sourceIndex === undefined || !sourceEntries[sourceIndex]) fail('UNOWNED_DECLARATION');
    // Uniform edges use actual retained RuntimeIR declaration indices; closed
    // edges use actual specialization witnesses. Neither guesses name mangling.
    return [generatedIndex, owner.index, sourceIndex, sourceIndex];
  });
  const lineage = canonicalArtifact({ schemaVersion: 1, contract,
    ...parents, ...(uniform ? { profile } : {}), edges, edgeOrder: uniform ?
      'generated-position-runtime-declaration-erasure-entry-source-origin-entry' :
      'generated-position-specialization-instance-erasure-entry-source-origin-entry',
    granularity: 'declaration-batch-to-emission-chunk', targetInventoryChecked: true,
    expressionCorrespondenceChecked: false, semanticPreservationProved: false,
    authority: 'debug-metadata-only' }, 'declaration-lineage', contract);
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
  if (record.identity.domain !== 'declaration-lineage') fail('IDENTITY');
  const profile = jsDeclarationLineageProfile(record.identity.contract), uniform = profile === uniformJsRepresentationProfile;
  const value = decode(record, maxBytes);
  const keys = jsDeclarationLineageParentKeys(profile);
  const parents = Object.fromEntries(keys.map(key => [key, value[key]]));
  parentIds(parents, profile);
  if (expectedParents !== undefined) {
    parentIds(expectedParents, profile);
    for (const key of keys) if (!same(parents[key], expectedParents[key])) fail('PARENT_SUBJECT');
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
      uniform ? null : parent('specializationMapId'), parent('generatedPositionMapId'), uniform)) await resolve(id);
  return { parents, profile, artifacts: [...cache.values()] };
}

/** Replay requires caller-pinned parents and reconstruction of every edge. */
export async function verifyJsDeclarationLineage(record, { resolveArtifact, expectedParents, profile = closedJsRepresentationProfile,
  maxBytes = 128 * 1024 * 1024, maxTotalBytes = 512 * 1024 * 1024 } = {}) {
  parentIds(expectedParents, profile);
  const loaded = await loadJsDeclarationLineageSubjects(record, { resolveArtifact, expectedParents, maxBytes, maxTotalBytes });
  if (loaded.profile !== profile) fail('PROFILE');
  for (const key of jsDeclarationLineageParentKeys(profile)) if (!same(loaded.parents[key], expectedParents[key])) fail('PARENT_SUBJECT');
  const cache = new Map(loaded.artifacts.map(item => [artifactKey(item.identity), item.bytes]));
  const rebuilt = createJsDeclarationLineage({ parents: expectedParents, profile, maxBytes, maxTotalBytes,
    resolveArtifact: id => cache.get(artifactKey(id)) });
  if (!same(rebuilt.lineage.identity, record.identity)) fail('BINDING');
  return { contract: rebuilt.lineage.identity.contract, declarationCompositionChecked: true,
    targetInventoryChecked: true, granularity: 'declaration-batch-to-emission-chunk',
    expressionCorrespondenceChecked: false, semanticPreservationProved: false, authority: 'debug-metadata-only' };
}
