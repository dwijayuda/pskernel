import { artifactId, artifactKey, canonicalArtifact, verifyArtifact } from './artifact-evidence.mjs';
import { decodeComparatorJson } from './comparator-export.mjs';
import { decodeJsIrArtifact } from './target-ir-artifact.mjs';

export const jsGeneratedPositionsContract = 'psc-js-generated-positions/1';
export const jsGeneratedPositionMapContract = 'psc-js-generated-position-map/1';
const fail = code => { throw new Error('PSC_JS_POSITION_' + code); };
const arr = (value, count) => {
  if (!Array.isArray(value) || (count !== undefined && value.length !== count)) fail('SCHEMA');
  return value;
};
const nat = value => { if (!Number.isSafeInteger(value) || value < 0) fail('NATURAL'); };

/** Exact emitted declaration-chunk boundaries, not expression locations or
 * source attribution. Bytes outside the chunks are explicitly unmapped.
 * Coordinates are ECMAScript lines / UTF-16 columns, with CRLF counted once.
 */
export function decodeJsGeneratedPositions(bytes, { javaScript, jsIr, maxBytes = 128 * 1024 * 1024 }) {
  if (typeof javaScript !== 'string' || !javaScript.isWellFormed() || Buffer.byteLength(javaScript) > maxBytes) fail('TEXT');
  const value = decodeComparatorJson(bytes, { maxBytes, maxDepth: 64, maxNodes: 2000000 });
  arr(value, 3);
  if (value[0] !== jsGeneratedPositionsContract || value[1] !== 'declaration-emission-chunk') fail('CONTRACT');
  const ir = decodeJsIrArtifact(jsIr, { maxBytes }), entries = arr(value[2]), requested = new Map();
  if (entries.length !== ir[2].length) fail('DECLARATION_COVERAGE');
  let previousEnd = 0;
  for (let index = 0; index < entries.length; index++) {
    const [name, start, stop] = arr(entries[index], 3);
    if (name !== ir[2][index][0]) fail('DECLARATION_ORDER');
    for (const position of [start, stop]) {
      arr(position, 3); position.forEach(nat);
      const previous = requested.get(position[0]);
      if (previous && (previous[1] !== position[1] || previous[2] !== position[2])) fail('POSITION');
      requested.set(position[0], position);
    }
    if (start[0] < previousEnd || start[0] >= stop[0]) fail('SPAN');
    previousEnd = stop[0];
  }
  let offset = 0, line = 0, column = 0, previousCR = false, matched = 0;
  function check() {
    const position = requested.get(offset);
    if (!position) return;
    if (position[1] !== line || position[2] !== column) fail('POSITION');
    matched++;
  }
  for (const char of javaScript) {
    // No emitted declaration boundary may split a CRLF sequence.
    if (previousCR && char === '\n' && requested.has(offset)) fail('CRLF_BOUNDARY');
    check();
    offset += Buffer.byteLength(char);
    if (char === '\n') {
      if (!previousCR) line++;
      column = 0;
    } else if (char === '\r' || char === '\u2028' || char === '\u2029') {
      line++; column = 0;
    } else column += char.length;
    previousCR = char === '\r';
  }
  check();
  if (matched !== requested.size) fail('UTF8_BOUNDARY');
  return value;
}

export function createJsGeneratedPositionMap({ table, javaScript, jsIr, maxBytes = 128 * 1024 * 1024 }) {
  verifyArtifact(jsIr.bytes, jsIr.identity);
  if (jsIr.identity.domain !== 'js-ir' || jsIr.identity.contract !== 'psc-js-ir-json/1') fail('TARGET_IR');
  const bytes = Buffer.from(table);
  decodeJsGeneratedPositions(bytes, { javaScript, jsIr: jsIr.bytes, maxBytes });
  const tableRecord = { bytes, identity: artifactId(bytes, 'generated-position-table', jsGeneratedPositionsContract) };
  const codeBytes = Buffer.from(javaScript);
  const code = { bytes: codeBytes, identity: artifactId(codeBytes, 'javascript-output', 'psc-direct-javascript/es2022') };
  const map = canonicalArtifact({ schemaVersion: 1, contract: jsGeneratedPositionMapContract,
    jsIrId: jsIr.identity, javascriptId: code.identity, tableId: tableRecord.identity,
    granularity: 'declaration-emission-chunk',
    coordinateContract: 'utf8-byte+zero-based-ecmascript-line+utf16-column',
    outsideChunks: 'unmapped', sourceAttributionChecked: false, authority: 'debug-metadata-only'
  }, 'generated-position-map', jsGeneratedPositionMapContract);
  return { map, artifacts: [jsIr, code, tableRecord] };
}

export async function verifyJsGeneratedPositionMap(record, {
  resolveArtifact, expectedJsIrId, expectedJavaScriptId, maxBytes = 128 * 1024 * 1024,
} = {}) {
  verifyArtifact(record.bytes, record.identity);
  if (record.identity.domain !== 'generated-position-map' || record.identity.contract !== jsGeneratedPositionMapContract) fail('IDENTITY');
  const value = decodeComparatorJson(record.bytes, { maxBytes, maxDepth: 64, maxNodes: 2000000 });
  if (!value || typeof value !== 'object' || Array.isArray(value) ||
      Object.keys(value).sort().join(',') !==
        'authority,contract,coordinateContract,granularity,javascriptId,jsIrId,outsideChunks,schemaVersion,sourceAttributionChecked,tableId' ||
      value.contract !== jsGeneratedPositionMapContract || value.schemaVersion !== 1 ||
      artifactKey(value.jsIrId) !== artifactKey(expectedJsIrId) || artifactKey(value.javascriptId) !== artifactKey(expectedJavaScriptId) ||
      value.javascriptId?.domain !== 'javascript-output' || value.javascriptId?.contract !== 'psc-direct-javascript/es2022' ||
      value.tableId?.domain !== 'generated-position-table' || value.tableId?.contract !== jsGeneratedPositionsContract) fail('SUBJECT');
  async function resolve(identity) {
    if (!Number.isSafeInteger(identity?.byteLength) || identity.byteLength < 0 || identity.byteLength > maxBytes) fail('RESOURCE');
    const bytes = await resolveArtifact(identity); verifyArtifact(bytes, identity); return { bytes, identity };
  }
  const jsIr = await resolve(value.jsIrId), code = await resolve(value.javascriptId), table = await resolve(value.tableId);
  const javaScript = new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }).decode(code.bytes);
  const rebuilt = createJsGeneratedPositionMap({ table: table.bytes, javaScript, jsIr, maxBytes });
  if (artifactKey(rebuilt.map.identity) !== artifactKey(record.identity)) fail('BINDING');
  return { contract: jsGeneratedPositionMapContract, generatedCoordinatesChecked: true,
    sourceAttributionChecked: false, authority: 'debug-metadata-only' };
}
