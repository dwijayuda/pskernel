import { artifactId, artifactKey, canonicalArtifact, verifyArtifact } from './artifact-evidence.mjs';
import { decodeComparatorJson } from './comparator-export.mjs';
import { decodePublicApi, publicApiNameKey } from './public-api-artifact.mjs';
import { decodeIrArtifact } from './ir-artifact.mjs';

export const erasureDeclarationsContract = 'psc-erasure-declarations/1';
export const erasureDeclarationMapContract = 'psc-erasure-declaration-map/1';
const fail = code => { throw new Error('PSC_ERASURE_DECL_' + code); };
const arr = (value, count) => {
  if (!Array.isArray(value) || (count !== undefined && value.length !== count)) fail('SCHEMA');
  return value;
};
const sameId = (a, b) => artifactKey(a) === artifactKey(b);

/** Exhaustive ordered declaration inventory from the actual erasure fold.
 * This checks names, kinds, dispositions and coverage against exact API/IR.
 * It does not independently decide Prop or check type/body erasure semantics.
 */
export function decodeErasureDeclarations(bytes, { publicApi, runtimeIr, maxBytes = 128 * 1024 * 1024 }) {
  const value = decodeComparatorJson(bytes, { maxBytes, maxDepth: 512, maxNodes: 2000000 });
  arr(value, 3);
  if (value[0] !== erasureDeclarationsContract || value[1] !== 'declaration-inventory') fail('CONTRACT');
  const api = decodePublicApi(publicApi, { maxBytes }), ir = decodeIrArtifact(runtimeIr, { maxBytes });
  const entries = arr(value[2]), runtimeNames = new Set();
  if (entries.length !== api[2].length) fail('SOURCE_COVERAGE');
  let cursor = 0;
  for (let index = 0; index < entries.length; index++) {
    const [name, disposition] = arr(entries[index], 2);
    const declaration = api[2][index], constant = declaration[0] === 'constant';
    if (publicApiNameKey(name) !== publicApiNameKey(declaration[constant ? 2 : 1])) fail('SOURCE_ORDER');
    const executableKind = constant && ['definition', 'partial'].includes(declaration[1]);
    arr(disposition);
    switch (disposition[0]) {
      case 'runtime':
        arr(disposition, 2);
        if (!executableKind || typeof disposition[1] !== 'string' || !disposition[1].isWellFormed() ||
            !disposition[1] || runtimeNames.has(disposition[1]) || ir[4][cursor]?.[0] !== disposition[1]) fail('RUNTIME_ORDER');
        runtimeNames.add(disposition[1]); cursor++;
        break;
      case 'proof-erased':
        arr(disposition, 1); if (!executableKind) fail('DISPOSITION');
        break;
      case 'no-runtime-declaration':
        arr(disposition, 1); if (executableKind) fail('DISPOSITION');
        break;
      default: fail('DISPOSITION');
    }
  }
  if (cursor !== ir[4].length) fail('RUNTIME_COVERAGE');
  return value;
}

export function createErasureDeclarationMap({ table, publicApi, runtimeIr, maxBytes = 128 * 1024 * 1024 }) {
  for (const item of [publicApi, runtimeIr]) verifyArtifact(item.bytes, item.identity);
  if (publicApi.identity.domain !== 'public-api' || publicApi.identity.contract !== 'psc-public-api-ir/1' ||
      runtimeIr.identity.domain !== 'runtime-ir' || runtimeIr.identity.contract !== 'psc-runtime-ir-json/1') fail('SUBJECT');
  const bytes = Buffer.from(table);
  decodeErasureDeclarations(bytes, { publicApi: publicApi.bytes, runtimeIr: runtimeIr.bytes, maxBytes });
  const tableRecord = { bytes, identity: artifactId(bytes, 'erasure-table', erasureDeclarationsContract) };
  const map = canonicalArtifact({ schemaVersion: 1, contract: erasureDeclarationMapContract,
    publicApiId: publicApi.identity, runtimeIrId: runtimeIr.identity, tableId: tableRecord.identity,
    granularity: 'declaration-inventory', authority: 'debug-metadata-only',
    semanticPreservationProved: false, proofDispositionIndependentlyChecked: false
  }, 'erasure-map', erasureDeclarationMapContract);
  return { map, artifacts: [publicApi, runtimeIr, tableRecord] };
}

export async function verifyErasureDeclarationMap(record, {
  resolveArtifact, expectedPublicApiId, expectedRuntimeIrId, maxBytes = 128 * 1024 * 1024,
} = {}) {
  verifyArtifact(record.bytes, record.identity);
  if (record.identity.domain !== 'erasure-map' || record.identity.contract !== erasureDeclarationMapContract) fail('IDENTITY');
  const value = decodeComparatorJson(record.bytes, { maxBytes, maxDepth: 64, maxNodes: 2000000 });
  if (!value || typeof value !== 'object' || Array.isArray(value) ||
      Object.keys(value).sort().join(',') !==
        'authority,contract,granularity,proofDispositionIndependentlyChecked,publicApiId,runtimeIrId,schemaVersion,semanticPreservationProved,tableId' ||
      value.contract !== erasureDeclarationMapContract || value.schemaVersion !== 1 ||
      !sameId(value.publicApiId, expectedPublicApiId) || !sameId(value.runtimeIrId, expectedRuntimeIrId) ||
      value.tableId?.domain !== 'erasure-table' || value.tableId?.contract !== erasureDeclarationsContract) fail('SCHEMA');
  let total = 0;
  async function resolve(identity) {
    if (!Number.isSafeInteger(identity?.byteLength) || identity.byteLength < 0 || identity.byteLength > maxBytes ||
        (total += identity.byteLength) > 384 * 1024 * 1024) fail('RESOURCE');
    const bytes = await resolveArtifact(identity); verifyArtifact(bytes, identity);
    return { bytes, identity };
  }
  const publicApi = await resolve(value.publicApiId), runtimeIr = await resolve(value.runtimeIrId);
  const table = await resolve(value.tableId);
  const rebuilt = createErasureDeclarationMap({ table: table.bytes, publicApi, runtimeIr, maxBytes });
  if (!sameId(rebuilt.map.identity, record.identity)) fail('BINDING');
  return Object.freeze({ contract: erasureDeclarationMapContract, inventoryCorrespondenceChecked: true,
    semanticPreservationProved: false, proofDispositionIndependentlyChecked: false, authority: 'debug-metadata-only' });
}
