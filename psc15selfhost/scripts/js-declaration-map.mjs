import { artifactId, artifactKey, canonicalArtifact, canonicalBytes, verifyArtifact } from './artifact-evidence.mjs';
import { decodeComparatorJson } from './comparator-export.mjs';
import { createDirectJsDeclarationPositions, directJsDeclarationProfile } from './js-declarations.mjs';
import { createDeclarationOriginGraph } from './declaration-origins.mjs';
import { mapPreparedOffset } from './source-preparation-origins.mjs';
import { sourceCoordinates, sourceMapOrigins, generatedLineEnds } from './source-map-origins.mjs';
import { encodeSourceMapMappings } from './source-map-encoding.mjs';

export const directJsDeclarationMapContract = 'psc-direct-js-declaration-map/1';
export const directJsDeclarationMapRecipeContract = 'psc-direct-js-declaration-map-recipe/1';
const fail = code => { throw new Error('PSC_JS_DECLARATION_MAP_' + code); };
const same = (a, b) => artifactKey(a) === artifactKey(b);
const utf8 = bytes => new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }).decode(bytes);
const read = (record, maxBytes) => decodeComparatorJson(record.bytes, { maxBytes, maxDepth: 512, maxNodes: 2000000 });
function policy(file, maxBytes, maxTotalBytes) {
  if (![maxBytes, maxTotalBytes].every(n => Number.isSafeInteger(n) && n > 0)) fail('RESOURCE_POLICY');
  if (file !== null && (typeof file !== 'string' || !file || !file.isWellFormed() || file.length > 4096)) fail('FILE');
}
function boundedRecords(maxBytes, maxTotalBytes) {
  const records = new Map(); let total = 0;
  return {
    records,
    add(record) {
      const key = artifactKey(record?.identity);
      if (record.identity.byteLength > maxBytes || !(record.bytes instanceof Uint8Array)) fail('RESOURCE');
      verifyArtifact(record.bytes, record.identity);
      if (!records.has(key)) {
        if ((total += record.bytes.byteLength) > maxTotalBytes || records.size >= 8250) fail('RESOURCE');
        records.set(key, { identity: JSON.parse(canonicalBytes(record.identity)), bytes: Buffer.from(record.bytes) });
      }
      return records.get(key);
    },
    checkOutput(...outputs) {
      const bytes = outputs.reduce((sum, item) => {
        if (item.bytes.byteLength > maxBytes) fail('RESOURCE');
        return sum + item.bytes.byteLength;
      }, 0);
      if (total + bytes > maxTotalBytes) fail('RESOURCE');
    },
  };
}

/** A standalone map from exact declaration writer chunks to source declaration
 * anchors. Source signatures and origins are replayed; no JavaScript position
 * or optimized instance is used to recover a public source signature.
 */
export function createDirectJsDeclarationMap({ declarations, sourceSignatures, binding, originGraph,
  resolveArtifact, profile = directJsDeclarationProfile, preparationOrigins = null, sourceSnapshot = null,
  file = null, maxBytes = 128 * 1024 * 1024, maxTotalBytes = 512 * 1024 * 1024 }) {
  policy(file, maxBytes, maxTotalBytes);
  const cache = boundedRecords(maxBytes, maxTotalBytes), add = record => cache.add(record);
  const resolve = identity => cache.records.get(artifactKey(identity)) ?? add({ identity, bytes: resolveArtifact(identity) });
  declarations = add(declarations); sourceSignatures = add(sourceSignatures); binding = add(binding); originGraph = add(originGraph);
  const bound = read(binding, maxBytes);
  if (bound.profile !== profile) fail('PROFILE');
  const subjects = Object.fromEntries(Object.entries(bound.subjects ?? {}).map(([key, identity]) => [key, resolve(identity)]));
  const rebuilt = createDirectJsDeclarationPositions({ subjects, profile, maxBytes, maxTotalBytes });
  for (const [key, record] of Object.entries({ declarations, sourceSignatures, binding }))
    if (!same(rebuilt[key].identity, record.identity)) fail('DECLARATION_BINDING');
  const origin = read(originGraph, maxBytes);
  if (!Array.isArray(origin.sourceIds) || origin.sourceIds.length > 4096 ||
      !same(origin.publicApiId, subjects.publicApi.identity)) fail('ORIGIN_SUBJECT');
  const sources = origin.sourceIds.map(identity => utf8(resolve(identity).bytes));
  const replay = createDeclarationOriginGraph({ table: resolve(origin.tableId).bytes,
    sources, publicApi: subjects.publicApi, maxBytes });
  if (!same(replay.graph.identity, originGraph.identity)) fail('ORIGIN_BINDING');
  if (preparationOrigins !== null) preparationOrigins = add(preparationOrigins);
  if (sourceSnapshot !== null) sourceSnapshot = add(sourceSnapshot);
  const sourceFiles = sourceMapOrigins({ origin, preparationOrigins, sourceSnapshot, resolve, read, maxBytes });
  const sourceEntries = read(resolve(origin.tableId), maxBytes)[3];
  const positions = read(rebuilt.declarationPositions, maxBytes).positions;
  const offsets = sourceFiles.map(() => new Set()), anchors = [];
  for (const [sourceIndex, role, start, stop] of positions) {
    const source = sourceEntries[sourceIndex], sourceFile = sourceFiles[source[0]];
    if (source[2][0] === source[3][0]) continue;
    const offset = sourceFile.segments === null ? source[2][0] : mapPreparedOffset(sourceFile.segments, source[2][0]);
    offsets[source[0]].add(offset); anchors.push({ sourceIndex: source[0], offset, start, stop, role });
  }
  const coordinates = sourceFiles.map((item, index) => sourceCoordinates(item.text, offsets[index]));
  const text = utf8(declarations.bytes), ends = generatedLineEnds(text, new Set(anchors.map(item => item.start[1])));
  const events = new Map(), event = item => events.set(item[0] + ':' + item[1], item);
  if (text.length) event([0, 0]);
  for (const { sourceIndex, offset, start, stop } of anchors) {
    event([start[1], start[2], sourceIndex, ...coordinates[sourceIndex].get(offset)]);
    const lineEnd = ends.get(start[1]), boundary = lineEnd && lineEnd[0] < stop[0] ? lineEnd : stop;
    if (boundary[0] < declarations.bytes.byteLength) event([boundary[1], boundary[2]]);
  }
  const mappings = encodeSourceMapMappings([...events.values()].sort((a, b) => a[0] - b[0] || a[1] - b[1]), { maxBytes });
  const bytes = canonicalBytes({ version: 3, ...(file === null ? {} : { file }),
    sources: sourceFiles.map(item => item.url), sourcesContent: sourceFiles.map(item => item.text), names: [], mappings,
    x_psc_mappingGranularity: 'source-declaration-chunks',
    x_psc_sourceCoordinateContract: 'zero-based-lf-line+utf16-column',
    x_psc_expressionOrigins: false }, { maxBytes, maxNodes: 2000000 });
  const declarationMap = { bytes, identity: artifactId(bytes, 'declaration-map-output', directJsDeclarationMapContract) };
  const declarationPositions = rebuilt.declarationPositions;
  const recipe = canonicalArtifact({ schemaVersion: 1, contract: directJsDeclarationMapRecipeContract, profile,
    declarationsId: declarations.identity, sourceSignaturesId: sourceSignatures.identity, bindingId: binding.identity,
    originGraphId: originGraph.identity, declarationPositionsId: declarationPositions.identity,
    declarationMapId: declarationMap.identity, preparationOriginsId: preparationOrigins?.identity ?? null,
    sourceSnapshotId: sourceSnapshot?.identity ?? null, file, granularity: 'source-declaration-chunks',
    linking: 'standalone-map-declarations-unchanged', expressionCorrespondenceChecked: false,
    semanticPreservationProved: false, authority: 'debug-metadata-only',
  }, 'declaration-map-recipe', directJsDeclarationMapRecipeContract);
  cache.checkOutput(declarationPositions, declarationMap, recipe);
  return { declarationPositions, declarationMap, recipe, artifacts: [...cache.records.values()] };
}

/** Consumer pins declaration products and origins independently. Every input
 * and output is rehashed and the entire map is reconstructed before acceptance.
 */
export async function verifyDirectJsDeclarationMap({ declarationPositions, declarationMap, recipe }, {
  resolveArtifact, expectedDeclarationsId, expectedSourceSignaturesId, expectedBindingId, expectedOriginGraphId,
  expectedProfile = directJsDeclarationProfile, expectedPreparationOriginsId = null, expectedSourceSnapshotId = null,
  expectedFile = null, maxBytes = 128 * 1024 * 1024, maxTotalBytes = 512 * 1024 * 1024,
} = {}) {
  policy(expectedFile, maxBytes, maxTotalBytes);
  const cache = boundedRecords(maxBytes, maxTotalBytes);
  declarationPositions = cache.add(declarationPositions); declarationMap = cache.add(declarationMap); recipe = cache.add(recipe);
  const snapshot = identity => JSON.parse(canonicalBytes(identity));
  expectedDeclarationsId = snapshot(expectedDeclarationsId); expectedSourceSignaturesId = snapshot(expectedSourceSignaturesId);
  expectedBindingId = snapshot(expectedBindingId); expectedOriginGraphId = snapshot(expectedOriginGraphId);
  if ((expectedPreparationOriginsId === null) !== (expectedSourceSnapshotId === null)) fail('PREPARATION_PAIR');
  if (expectedPreparationOriginsId !== null) {
    expectedPreparationOriginsId = snapshot(expectedPreparationOriginsId); expectedSourceSnapshotId = snapshot(expectedSourceSnapshotId);
  }
  if (declarationMap.identity.domain !== 'declaration-map-output' || declarationMap.identity.contract !== directJsDeclarationMapContract ||
      recipe.identity.domain !== 'declaration-map-recipe' || recipe.identity.contract !== directJsDeclarationMapRecipeContract ||
      declarationPositions.identity.domain !== 'declaration-positions' ||
      declarationPositions.identity.contract !== 'psc-js-declaration-positions/1') fail('IDENTITY');
  const value = read(recipe, maxBytes), nullableSame = (a, b) => a === null || b === null ? a === b : same(a, b);
  for (const [key, identity] of Object.entries({ declarationsId: expectedDeclarationsId, sourceSignaturesId: expectedSourceSignaturesId,
    bindingId: expectedBindingId, originGraphId: expectedOriginGraphId, declarationPositionsId: declarationPositions.identity,
    declarationMapId: declarationMap.identity })) if (!same(value[key], identity)) fail('SUBJECT');
  if (value.profile !== expectedProfile || value.file !== expectedFile ||
      !nullableSame(value.preparationOriginsId, expectedPreparationOriginsId) ||
      !nullableSame(value.sourceSnapshotId, expectedSourceSnapshotId)) fail('SUBJECT');
  async function resolve(identity) {
    const key = artifactKey(identity);
    if (!cache.records.has(key)) {
      if (identity.byteLength > maxBytes) fail('RESOURCE');
      cache.add({ identity, bytes: await resolveArtifact(identity) });
    }
    return cache.records.get(key);
  }
  const declarations = await resolve(expectedDeclarationsId), sourceSignatures = await resolve(expectedSourceSignaturesId);
  const binding = await resolve(expectedBindingId), originGraph = await resolve(expectedOriginGraphId);
  const bound = read(binding, maxBytes), origin = read(originGraph, maxBytes);
  if (!Array.isArray(origin.sourceIds) || origin.sourceIds.length > 4096) fail('SOURCE_COUNT');
  for (const identity of [...Object.values(bound.subjects ?? {}), origin.tableId, ...origin.sourceIds]) await resolve(identity);
  let preparationOrigins = null, sourceSnapshot = null;
  if (expectedPreparationOriginsId !== null) {
    preparationOrigins = await resolve(expectedPreparationOriginsId); sourceSnapshot = await resolve(expectedSourceSnapshotId);
    const preparation = read(preparationOrigins, maxBytes);
    if (!Array.isArray(preparation.files) || preparation.files.length > 4096) fail('SOURCE_COUNT');
    for (const item of preparation.files) { await resolve(item.originalId); await resolve(item.preparedId); }
  }
  const rebuilt = createDirectJsDeclarationMap({ declarations, sourceSignatures, binding, originGraph,
    profile: expectedProfile, preparationOrigins, sourceSnapshot, file: expectedFile,
    resolveArtifact: id => cache.records.get(artifactKey(id))?.bytes, maxBytes, maxTotalBytes });
  for (const key of ['declarationPositions', 'declarationMap', 'recipe'])
    if (!same(rebuilt[key].identity, ({ declarationPositions, declarationMap, recipe })[key].identity)) fail('BINDING');
  return { contract: directJsDeclarationMapRecipeContract, declarationMapReconstructed: true,
    granularity: 'source-declaration-chunks', expressionCorrespondenceChecked: false,
    semanticPreservationProved: false, authority: 'debug-metadata-only' };
}
