import { artifactId, artifactKey, canonicalArtifact, canonicalBytes, verifyArtifact } from './artifact-evidence.mjs';
import { decodeComparatorJson } from './comparator-export.mjs';
import { createJsDeclarationLineage, loadJsDeclarationLineageSubjects, jsDeclarationLineageContract } from './js-declaration-lineage.mjs';
import { createSourcePreparationArtifacts, mapPreparedOffset, sourcePreparationContract } from './source-preparation-origins.mjs';
import { encodeSourceMapMappings } from './source-map-encoding.mjs';

export const directJsSourceMapContract = 'psc-direct-javascript-source-map/1';
export const directJsSourceMapRecipeContract = 'psc-direct-javascript-source-map-recipe/1';
const fail = code => { throw new Error('PSC_JS_SOURCE_MAP_' + code); };
const same = (a, b) => artifactKey(a) === artifactKey(b);
const utf8 = bytes => new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }).decode(bytes);
const parentKeys = ['originGraphId', 'erasureMapId', 'specializationMapId', 'generatedPositionMapId', 'verifiedIrId'];
const read = (record, maxBytes) => decodeComparatorJson(record.bytes, { maxBytes, maxDepth: 512, maxNodes: 2000000 });
function policy(file, maxBytes, maxTotalBytes) {
  if (![maxBytes, maxTotalBytes].every(n => Number.isSafeInteger(n) && n > 0)) fail('RESOURCE_POLICY');
  if (file !== null && (typeof file !== 'string' || !file || !file.isWellFormed() || file.length > 4096)) fail('FILE');
}
function sourceCoordinates(text, offsets) {
  const result = new Map(); let byte = 0, line = 0, column = 0;
  function check() { if (offsets.has(byte)) result.set(byte, [line, column]); }
  check();
  // PSC source lines are LF-delimited; scalar parser columns must not be
  // copied into source maps. Convert the actual original text to UTF-16.
  for (const char of text) {
    byte += Buffer.byteLength(char);
    if (char === '\n') { line++; column = 0; } else column += char.length;
    check();
  }
  if (result.size !== offsets.size) fail('SOURCE_BOUNDARY');
  return result;
}
function generatedLineEnds(text, requested) {
  const ends = new Map(); let byte = 0, line = 0, column = 0, previousCR = false;
  for (const char of text) {
    if (char === '\n' && previousCR) {
      byte++; previousCR = false; continue;
    }
    if (char === '\r' || char === '\n' || char === '\u2028' || char === '\u2029') {
      if (requested.has(line)) ends.set(line, [byte, line, column]);
      line++; column = 0;
    } else column += char.length;
    byte += Buffer.byteLength(char); previousCR = char === '\r';
  }
  return ends;
}

/** Standalone ECMA-426 map of declaration anchors, produced without tsc.
 * Input is exact lineage plus optional exact original-source preparation.
 * The executable bytes are unchanged; URL annotation/linking is a separate
 * packaging operation, not a hidden mutation of the printer product.
 */
export function createDirectJsSourceMap({ lineage, resolveArtifact, preparationOrigins = null,
  sourceSnapshot = null, file = null, maxBytes = 128 * 1024 * 1024, maxTotalBytes = 512 * 1024 * 1024 }) {
  policy(file, maxBytes, maxTotalBytes);
  const cache = new Map(); let total = 0;
  function add(record) {
    const key = artifactKey(record.identity);
    if (cache.has(key)) return cache.get(key);
    if (record.identity.byteLength > maxBytes || (total += record.identity.byteLength) > maxTotalBytes || cache.size >= 8250) fail('RESOURCE');
    verifyArtifact(record.bytes, record.identity);
    const copied = { bytes: Buffer.from(record.bytes), identity: record.identity };
    cache.set(key, copied); return copied;
  }
  const resolve = identity => cache.get(artifactKey(identity)) ?? add({ identity, bytes: resolveArtifact(identity) });
  lineage = add(lineage);
  if (lineage.identity.domain !== 'declaration-lineage' || lineage.identity.contract !== jsDeclarationLineageContract) fail('LINEAGE_ID');
  const value = read(lineage, maxBytes);
  const parents = Object.fromEntries(parentKeys.map(key => [key, value[key]]));
  const rebuilt = createJsDeclarationLineage({ parents, resolveArtifact: id => resolve(id).bytes, maxBytes, maxTotalBytes });
  if (!same(rebuilt.lineage.identity, lineage.identity)) fail('LINEAGE_BINDING');
  const origin = read(resolve(value.originGraphId), maxBytes);
  const positions = read(resolve(value.generatedPositionMapId), maxBytes);
  const sourceEntries = read(resolve(origin.tableId), maxBytes)[3];
  const generatedEntries = read(resolve(positions.tableId), maxBytes)[2];
  const javaScript = utf8(resolve(positions.javascriptId).bytes);
  const javaScriptByteLength = Buffer.byteLength(javaScript);
  if ((preparationOrigins === null) !== (sourceSnapshot === null)) fail('PREPARATION_PAIR');
  let sourceFiles;
  if (preparationOrigins !== null) {
    preparationOrigins = add(preparationOrigins); sourceSnapshot = add(sourceSnapshot);
    if (preparationOrigins.identity.domain !== 'source-origins' ||
        preparationOrigins.identity.contract !== sourcePreparationContract) fail('PREPARATION_ID');
    const preparation = read(preparationOrigins, maxBytes);
    if (!Array.isArray(preparation.files) || preparation.files.length > 4096 ||
        !same(preparation.sourceSubjectId, sourceSnapshot.identity)) fail('PREPARATION_SUBJECT');
    const records = preparation.files.map(item => ({ path: item.path, preparedIndex: item.preparedIndex,
      source: utf8(resolve(item.originalId).bytes), prepared: utf8(resolve(item.preparedId).bytes), segments: item.segments }));
    const replay = createSourcePreparationArtifacts(records, sourceSnapshot);
    if (!same(replay.map.identity, preparationOrigins.identity)) fail('PREPARATION_BINDING');
    sourceFiles = preparation.files.filter(item => item.preparedIndex !== null).map(item => ({
      text: utf8(resolve(item.originalId).bytes), preparedId: item.preparedId, segments: item.segments,
      // A relative display URL with one encoded filename component cannot
      // introduce an absolute scheme, traversal or query from a source path.
      url: 'psc-source/' + item.preparedIndex + '/file-' + encodeURIComponent(item.path),
    }));
  } else {
    sourceFiles = origin.sourceIds.map((id, index) => ({
      text: utf8(resolve(id).bytes), preparedId: id, segments: null, url: 'psc-prepared-source/' + index + '.psc',
    }));
  }
  if (sourceFiles.length !== origin.sourceIds.length ||
      sourceFiles.some((item, index) => !same(item.preparedId, origin.sourceIds[index]))) fail('SOURCE_CHAIN');
  const offsets = sourceFiles.map(() => new Set()), anchors = [];
  for (const edge of value.edges) {
    const source = sourceEntries[edge[3]], generated = generatedEntries[edge[0]];
    const sourceIndex = source[0], sourceFile = sourceFiles[sourceIndex];
    if (source[2][0] === source[3][0]) continue;
    const offset = sourceFile.segments === null ? source[2][0] :
      mapPreparedOffset(sourceFile.segments, source[2][0]);
    offsets[sourceIndex].add(offset); anchors.push({ generated, sourceIndex, offset });
  }
  const coordinates = sourceFiles.map((item, index) => sourceCoordinates(item.text, offsets[index]));
  const ends = generatedLineEnds(javaScript, new Set(anchors.map(item => item.generated[1][1])));
  const events = new Map();
  const event = item => events.set(item[0] + ':' + item[1], item);
  if (javaScript.length) event([0, 0]); // module prefix remains explicitly unmapped
  for (const { generated, sourceIndex, offset } of anchors) {
    const [, start, stop] = generated, original = coordinates[sourceIndex].get(offset);
    event([start[1], start[2], sourceIndex, ...original]);
    const lineEnd = ends.get(start[1]);
    const boundary = lineEnd && lineEnd[0] < stop[0] ? lineEnd : stop;
    // The terminator itself is a permitted generated mapping location.
    // Avoid inventing a mapping to a nonexistent character beyond EOF.
    if (boundary[0] < javaScriptByteLength) event([boundary[1], boundary[2]]);
  }
  const mappings = encodeSourceMapMappings([...events.values()].sort((a, b) => a[0] - b[0] || a[1] - b[1]), { maxBytes });
  const mapBytes = canonicalBytes({ version: 3, ...(file === null ? {} : { file }),
    sources: sourceFiles.map(item => item.url), sourcesContent: sourceFiles.map(item => item.text), names: [], mappings,
    x_psc_mappingGranularity: 'declaration-first-generated-line',
    x_psc_sourceCoordinateContract: 'zero-based-lf-line+utf16-column',
    x_psc_expressionOrigins: false }, { maxBytes, maxNodes: 2000000 });
  const sourceMap = { bytes: mapBytes, identity: artifactId(mapBytes, 'source-map-output', directJsSourceMapContract) };
  const recipe = canonicalArtifact({ schemaVersion: 1, contract: directJsSourceMapRecipeContract,
    lineageId: lineage.identity, javascriptId: positions.javascriptId, sourceMapId: sourceMap.identity,
    preparationOriginsId: preparationOrigins?.identity ?? null, sourceSnapshotId: sourceSnapshot?.identity ?? null,
    file, granularity: 'declaration-first-generated-line', linking: 'standalone-map-executable-unchanged',
    expressionCorrespondenceChecked: false, semanticPreservationProved: false, authority: 'debug-metadata-only'
  }, 'source-map-recipe', directJsSourceMapRecipeContract);
  if (recipe.bytes.byteLength > maxBytes || total + mapBytes.byteLength + recipe.bytes.byteLength > maxTotalBytes) fail('RESOURCE');
  return { sourceMap, recipe, artifacts: [...cache.values()] };
}

/** Fresh bounded archive replay; neither map deltas nor serialized lineage are
 * trusted as source correspondence. The pass caller pins all input subjects.
 */
export async function verifyDirectJsSourceMap({ sourceMap, recipe }, { resolveArtifact, expectedLineageId,
  expectedJavaScriptId, expectedPreparationOriginsId = null, expectedSourceSnapshotId = null, expectedFile = null,
  maxBytes = 128 * 1024 * 1024, maxTotalBytes = 512 * 1024 * 1024 } = {}) {
  policy(expectedFile, maxBytes, maxTotalBytes);
  for (const record of [sourceMap, recipe]) verifyArtifact(record.bytes, record.identity);
  if (sourceMap.identity.domain !== 'source-map-output' || sourceMap.identity.contract !== directJsSourceMapContract ||
      recipe.identity.domain !== 'source-map-recipe' || recipe.identity.contract !== directJsSourceMapRecipeContract) fail('IDENTITY');
  const value = read(recipe, maxBytes);
  const nullableSame = (a, b) => a === null || b === null ? a === b : same(a, b);
  if (!same(value.lineageId, expectedLineageId) || !same(value.javascriptId, expectedJavaScriptId) ||
      !same(value.sourceMapId, sourceMap.identity) || !nullableSame(value.preparationOriginsId, expectedPreparationOriginsId) ||
      !nullableSame(value.sourceSnapshotId, expectedSourceSnapshotId) || value.file !== expectedFile) fail('SUBJECT');
  const cache = new Map(); let total = sourceMap.bytes.byteLength + recipe.bytes.byteLength;
  async function resolve(identity) {
    const key = artifactKey(identity);
    if (cache.has(key)) return cache.get(key);
    if (identity.byteLength > maxBytes || (total += identity.byteLength) > maxTotalBytes || cache.size >= 8250) fail('RESOURCE');
    const bytes = await resolveArtifact(identity); verifyArtifact(bytes, identity);
    const record = { identity, bytes }; cache.set(key, record); return record;
  }
  const lineage = await resolve(expectedLineageId);
  await loadJsDeclarationLineageSubjects(lineage, { resolveArtifact: async id => (await resolve(id)).bytes, maxBytes, maxTotalBytes });
  let preparationOrigins = null, sourceSnapshot = null;
  if (expectedPreparationOriginsId !== null) {
    preparationOrigins = await resolve(expectedPreparationOriginsId);
    sourceSnapshot = await resolve(expectedSourceSnapshotId);
    const preparation = read(preparationOrigins, maxBytes);
    if (!Array.isArray(preparation.files) || preparation.files.length > 4096) fail('SOURCE_COUNT');
    for (const item of preparation.files) { await resolve(item.originalId); await resolve(item.preparedId); }
  }
  const rebuilt = createDirectJsSourceMap({ lineage, preparationOrigins, sourceSnapshot, file: expectedFile,
    resolveArtifact: id => cache.get(artifactKey(id))?.bytes, maxBytes, maxTotalBytes });
  if (!same(rebuilt.sourceMap.identity, sourceMap.identity) || !same(rebuilt.recipe.identity, recipe.identity)) fail('BINDING');
  return { contract: directJsSourceMapRecipeContract, declarationMapReconstructed: true,
    granularity: 'declaration-first-generated-line', expressionCorrespondenceChecked: false,
    semanticPreservationProved: false, authority: 'debug-metadata-only' };
}
