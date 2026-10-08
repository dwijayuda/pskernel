import { artifactId, artifactKey, canonicalArtifact, verifyArtifact } from './artifact-evidence.mjs';
import { decodeComparatorJson } from './comparator-export.mjs';
import { decodePublicApi, publicApiNameKey } from './public-api-artifact.mjs';

const fail = code => { throw new Error('PSC_DECL_ORIGIN_' + code); };
const arr = (value, count) => { if (!Array.isArray(value) || (count !== undefined && value.length !== count)) fail('SCHEMA'); return value; };
const nat = value => { if (!Number.isSafeInteger(value) || value < 0) fail('NATURAL'); };
const sameId = (a, b) => artifactKey(a) === artifactKey(b);
export const declarationOriginContract = 'psc-declaration-origins/1';
export const originGraphContract = 'psc-origin-graph/1';

/** Check a declaration-level side table against exact prepared source bytes and
 * the complete source API name inventory. Positions use parser coordinates:
 * zero-based UTF-8 bytes, one-based lines and Unicode scalar columns.
 * This checks bounds/coverage, not whether elaboration produced the right term.
 */
export function decodeDeclarationOrigins(bytes, { sources, publicApi, maxBytes = 128 * 1024 * 1024 }) {
  const value = decodeComparatorJson(bytes, { maxBytes, maxDepth: 512, maxNodes: 2000000 });
  arr(value, 4);
  if (value[0] !== declarationOriginContract || value[1] !== 'declaration-batch' ||
      !Array.isArray(sources) || sources.length > 4096 || value[2] !== sources.length ||
      sources.some(source => typeof source !== 'string' || !source.isWellFormed())) fail('CONTRACT');
  if (sources.reduce((sum, source) => sum + Buffer.byteLength(source), 0) > maxBytes) fail('SOURCE_BYTES_LIMIT');
  const api = decodePublicApi(publicApi, { maxBytes }), entries = arr(value[3]);
  if (entries.length !== api[2].length) fail('DECLARATION_COVERAGE');
  const requested = sources.map(() => new Map());
  for (let index = 0; index < entries.length; index++) {
    const entry = arr(entries[index], 4); nat(entry[0]);
    if (entry[0] >= sources.length) fail('SOURCE_INDEX');
    const declaration = api[2][index], name = declaration[declaration[0] === 'constant' ? 2 : 1];
    if (publicApiNameKey(entry[1]) !== publicApiNameKey(name)) fail('DECLARATION_ORDER');
    for (const position of [entry[2], entry[3]]) {
      arr(position, 3); position.forEach(nat);
      if (!position[1] || !position[2]) fail('POSITION');
      const previous = requested[entry[0]].get(position[0]);
      if (previous && (previous[1] !== position[1] || previous[2] !== position[2])) fail('POSITION');
      requested[entry[0]].set(position[0], position);
    }
    if (entry[2][0] > entry[3][0]) fail('SPAN');
  }
  // One scan per source, independent of the number of declaration endpoints.
  for (let index = 0; index < sources.length; index++) {
    const positions = requested[index]; let offset = 0, line = 1, column = 1, matched = 0;
    function check() {
      const position = positions.get(offset);
      if (!position) return;
      if (position[1] !== line || position[2] !== column) fail('POSITION');
      matched++;
    }
    check();
    for (const char of sources[index]) {
      offset += Buffer.byteLength(char);
      if (char === '\n') { line++; column = 1; } else column++;
      check();
    }
    if (matched !== positions.size) fail('UTF8_BOUNDARY');
  }
  return value;
}

export function createDeclarationOriginGraph({ table, sources, publicApi, maxBytes = 128 * 1024 * 1024 }) {
  verifyArtifact(publicApi.bytes, publicApi.identity);
  if (publicApi.identity.domain !== 'public-api' || publicApi.identity.contract !== 'psc-public-api-ir/1') fail('PUBLIC_API');
  const tableBytes = Buffer.from(table);
  decodeDeclarationOrigins(tableBytes, { sources, publicApi: publicApi.bytes, maxBytes });
  const tableRecord = { bytes: tableBytes, identity: artifactId(tableBytes, 'origin-table', declarationOriginContract) };
  const sourceRecords = sources.map(text => {
    const bytes = Buffer.from(text);
    return { bytes, identity: artifactId(bytes, 'prepared-source', 'psc-prepared-source-utf8/1') };
  });
  const graph = canonicalArtifact({ schemaVersion: 1, contract: originGraphContract,
    granularity: 'declaration-batch', coordinateContract: 'utf8-byte+one-based-unicode-scalar',
    sourceIds: sourceRecords.map(item => item.identity), publicApiId: publicApi.identity, tableId: tableRecord.identity,
    unmappedStages: ['runtime-ir', 'specialized-ir', 'target-ir'], authority: 'debug-metadata-only' }, 'origin-graph', originGraphContract);
  return { graph, artifacts: [publicApi, tableRecord, ...sourceRecords] };
}

export async function verifyDeclarationOriginGraph(record, { resolveArtifact, expectedPublicApiId, expectedSources, maxBytes = 128 * 1024 * 1024 } = {}) {
  verifyArtifact(record.bytes, record.identity);
  if (record.identity.domain !== 'origin-graph' || record.identity.contract !== originGraphContract) fail('IDENTITY');
  const value = decodeComparatorJson(record.bytes, { maxBytes, maxDepth: 64, maxNodes: 2000000 });
  if (Object.keys(value).sort().join(',') !== 'authority,contract,coordinateContract,granularity,publicApiId,schemaVersion,sourceIds,tableId,unmappedStages' ||
      value.contract !== originGraphContract || value.schemaVersion !== 1 ||
      value.granularity !== 'declaration-batch' || value.coordinateContract !== 'utf8-byte+one-based-unicode-scalar' ||
      value.authority !== 'debug-metadata-only' || JSON.stringify(value.unmappedStages) !== '["runtime-ir","specialized-ir","target-ir"]' ||
      !Array.isArray(value.sourceIds) || value.sourceIds.length > 4096 || !sameId(value.publicApiId, expectedPublicApiId) ||
      !Array.isArray(expectedSources) || expectedSources.length !== value.sourceIds.length ||
      value.tableId?.domain !== 'origin-table' || value.tableId?.contract !== declarationOriginContract) fail('SCHEMA');
  let total = 0;
  const resolve = async identity => {
    if (!Number.isSafeInteger(identity?.byteLength) || identity.byteLength < 0 || identity.byteLength > maxBytes ||
        (total += identity.byteLength) > 512 * 1024 * 1024) fail('RESOURCE');
    const bytes = await resolveArtifact(identity); verifyArtifact(bytes, identity); return bytes;
  };
  const sources = [], utf8 = new TextDecoder('utf-8', { fatal: true, ignoreBOM: true });
  for (let index = 0; index < value.sourceIds.length; index++) {
    const id = value.sourceIds[index];
    if (id.domain !== 'prepared-source' || id.contract !== 'psc-prepared-source-utf8/1') fail('SOURCE_ID');
    const text = utf8.decode(await resolve(id));
    if (text !== expectedSources[index]) fail('SOURCE_BYTES');
    sources.push(text);
  }
  const publicApi = { identity: value.publicApiId, bytes: await resolve(value.publicApiId) };
  const rebuilt = createDeclarationOriginGraph({ table: await resolve(value.tableId), sources, publicApi, maxBytes });
  if (!sameId(rebuilt.graph.identity, record.identity)) fail('GRAPH_BINDING');
  return { contract: originGraphContract, declarationOriginsChecked: true, granularity: 'declaration-batch',
    expressionCorrespondenceChecked: false, semanticPreservationProved: false, authority: 'debug-metadata-only' };
}
