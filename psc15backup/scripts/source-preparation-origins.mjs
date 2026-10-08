import { artifactId, canonicalArtifact, canonicalBytes, verifyArtifact } from './artifact-evidence.mjs';
import { decodeComparatorJson } from './comparator-export.mjs';

export const sourcePreparationContract = 'psc-source-preparation-origins/1';
const fail = code => { throw new Error('PSC_SOURCE_ORIGIN_' + code); };
const same = (a, b) => canonicalBytes(a).equals(canonicalBytes(b));

/** Preserve the existing import removal/newline/trim semantics exactly while
 * recording copied UTF-8 ranges. The source reader already bounds and validates
 * source bytes. No original file is reopened to reconstruct provenance.
 */
export function prepareSourceWithOrigins(source) {
  if (typeof source !== 'string' || !source.isWellFormed()) fail('SOURCE_TEXT');
  const kept = [];
  let charOffset = 0, byteOffset = 0;
  for (const line of source.split(/\r?\n/u)) {
    const size = Buffer.byteLength(line), next = charOffset + line.length;
    const newlineSize = source[next] === '\r' && source[next + 1] === '\n' ? 2 : source[next] === '\n' ? 1 : 0;
    if (!/^\s*import\s+[A-Za-z0-9_.]+\s*;?\s*$/u.test(line)) {
      kept.push({ text: line, sourceStart: byteOffset, size,
        newlineOffset: newlineSize ? byteOffset + size + newlineSize - 1 : null });
    }
    charOffset = next + newlineSize; byteOffset += size + newlineSize;
  }
  const joined = kept.map(item => item.text).join('\n'), prepared = joined.trim();
  const leading = Buffer.byteLength(joined.slice(0, joined.length - joined.trimStart().length));
  const stop = leading + Buffer.byteLength(prepared);
  const segments = [];
  let generated = 0;
  function copy(size, sourceStart) {
    const start = Math.max(leading, generated), end = Math.min(stop, generated + size);
    if (start < end) {
      const next = [start - leading, end - leading, sourceStart + start - generated, sourceStart + end - generated];
      const previous = segments.at(-1);
      if (previous && previous[1] === next[0] && previous[3] === next[2]) {
        previous[1] = next[1]; previous[3] = next[3];
      } else segments.push(next);
    }
    generated += size;
  }
  for (let index = 0; index < kept.length; index++) {
    if (index) {
      if (kept[index - 1].newlineOffset === null) fail('NEWLINE_PROVENANCE');
      copy(1, kept[index - 1].newlineOffset);
    }
    copy(kept[index].size, kept[index].sourceStart);
  }
  return Object.freeze({ prepared, segments: Object.freeze(segments.map(Object.freeze)) });
}

export function sourcePreparationRecord(path, source, preparedIndex) {
  const product = prepareSourceWithOrigins(source);
  return Object.freeze({ path, source, prepared: product.prepared,
    preparedIndex: product.prepared ? preparedIndex : null, segments: product.segments });
}

export function createSourcePreparationArtifacts(records, sourceSubject) {
  verifyArtifact(sourceSubject.bytes, sourceSubject.identity);
  const subject = decodeComparatorJson(sourceSubject.bytes, { maxBytes: 128 * 1024 * 1024 });
  if (sourceSubject.identity.domain !== 'source-snapshot' || sourceSubject.identity.contract !== 'psc-source-snapshot/1' ||
      !Array.isArray(subject.sources) || !Array.isArray(records) || records.length > 4096) fail('SOURCE_SUBJECT');
  const artifacts = [], files = [], paths = new Set(); let input = 0;
  for (const record of records) {
    if (typeof record.path !== 'string' || !record.path || paths.has(record.path)) fail('FILE');
    paths.add(record.path);
    const expected = prepareSourceWithOrigins(record.source);
    if (expected.prepared !== record.prepared || !same(expected.segments, record.segments) ||
        record.preparedIndex !== (record.prepared ? input : null)) fail('PROJECTION');
    if (record.prepared && subject.sources[input++] !== record.prepared) fail('INPUT_ORDER');
    const originalBytes = Buffer.from(record.source), preparedBytes = Buffer.from(record.prepared);
    const original = { bytes: originalBytes, identity: artifactId(originalBytes, 'source-text', 'psc-source-utf8/1') };
    const prepared = { bytes: preparedBytes, identity: artifactId(preparedBytes, 'prepared-source', 'psc-prepared-source-utf8/1') };
    artifacts.push(original, prepared);
    files.push({ path: record.path, preparedIndex: record.preparedIndex, originalId: original.identity,
      preparedId: prepared.identity, segments: record.segments });
  }
  if (input !== subject.sources.length) fail('INPUT_COVERAGE');
  const map = canonicalArtifact({ schemaVersion: 1, contract: sourcePreparationContract, coordinateUnit: 'utf8-byte',
    sourceSubjectId: sourceSubject.identity, files, authority: 'debug-metadata-only' }, 'source-origins', sourcePreparationContract);
  return { map, artifacts };
}

/** An interval crossing removed import lines returns several exact source
 * fragments. It must not be widened into a falsely contiguous source span.
 * Empty ranges have no copied bytes and return no fragments.
 */
export function mapPreparedRange(segments, start, stop) {
  if (!Number.isSafeInteger(start) || !Number.isSafeInteger(stop) || start < 0 || stop < start ||
      stop > (segments.at(-1)?.[1] ?? 0)) fail('RANGE');
  const result = [];
  for (const [from, to, originalFrom] of segments) {
    if (to <= start) continue;
    if (from >= stop) break;
    const low = Math.max(from, start), high = Math.min(to, stop);
    if (low < high) result.push([originalFrom + low - from, originalFrom + high - from]);
  }
  return result;
}

/** Map one byte offset in an already validated copied-segment inventory.
 * Binary search keeps declaration-anchor composition O(log segmentCount).
 * The caller reconstructs/validates the preparation product before this query.
 */
export function mapPreparedOffset(segments, offset) {
  if (!Number.isSafeInteger(offset) || offset < 0 || !Array.isArray(segments)) fail('RANGE');
  let low = 0, high = segments.length;
  while (low < high) {
    const middle = Math.floor((low + high) / 2);
    if (segments[middle][1] <= offset) low = middle + 1; else high = middle;
  }
  const segment = segments[low];
  if (!segment || offset < segment[0] || offset >= segment[1]) fail('RANGE');
  return segment[2] + offset - segment[0];
}

/** Replays exact preparation from archived source bytes, including input order.
 * This is a text transformation/origin check, not a semantic frontend theorem.
 */
export async function verifySourcePreparationOrigins(record, { expectedSourceId, resolveArtifact, maxBytes = 128 * 1024 * 1024 } = {}) {
  verifyArtifact(record.bytes, record.identity);
  if (record.identity.domain !== 'source-origins' || record.identity.contract !== sourcePreparationContract) fail('IDENTITY');
  const value = decodeComparatorJson(record.bytes, { maxBytes, maxDepth: 64, maxNodes: 2000000 });
  if (Object.keys(value).sort().join(',') !== 'authority,contract,coordinateUnit,files,schemaVersion,sourceSubjectId' ||
      value.contract !== sourcePreparationContract || value.schemaVersion !== 1 || value.coordinateUnit !== 'utf8-byte' ||
      value.authority !== 'debug-metadata-only' || !Array.isArray(value.files) || value.files.length > 4096 ||
      !same(value.sourceSubjectId, expectedSourceId)) fail('SCHEMA');
  let totalBytes = 0;
  async function resolve(identity) {
    if (!Number.isSafeInteger(identity?.byteLength) || identity.byteLength < 0 || identity.byteLength > maxBytes ||
        (totalBytes += identity.byteLength) > 512 * 1024 * 1024) fail('RESOURCE');
    const bytes = await resolveArtifact(identity); verifyArtifact(bytes, identity);
    return bytes;
  }
  const subject = decodeComparatorJson(await resolve(expectedSourceId), { maxBytes, maxDepth: 64, maxNodes: 2000000 });
  if (expectedSourceId.domain !== 'source-snapshot' || expectedSourceId.contract !== 'psc-source-snapshot/1' ||
      !Array.isArray(subject.sources) || subject.sources.some(text => typeof text !== 'string')) fail('SOURCE_SUBJECT');
  const paths = new Set(); let input = 0;
  const utf8 = new TextDecoder('utf-8', { fatal: true, ignoreBOM: true });
  for (const file of value.files) {
    if (Object.keys(file).sort().join(',') !== 'originalId,path,preparedId,preparedIndex,segments' ||
        typeof file.path !== 'string' || !file.path || paths.has(file.path) ||
        file.originalId?.domain !== 'source-text' || file.originalId?.contract !== 'psc-source-utf8/1' ||
        file.preparedId?.domain !== 'prepared-source' || file.preparedId?.contract !== 'psc-prepared-source-utf8/1') fail('FILE');
    paths.add(file.path);
    const source = utf8.decode(await resolve(file.originalId));
    const actual = utf8.decode(await resolve(file.preparedId));
    const expected = prepareSourceWithOrigins(source);
    if (actual !== expected.prepared || !same(file.segments, expected.segments)) fail('PROJECTION');
    if (actual) {
      if (file.preparedIndex !== input || subject.sources[input] !== actual) fail('INPUT_ORDER');
      input++;
    } else if (file.preparedIndex !== null) fail('EMPTY_INPUT');
  }
  if (input !== subject.sources.length) fail('INPUT_COVERAGE');
  return { contract: sourcePreparationContract, inputCount: input, fileCount: value.files.length,
    projectionChecked: true, semanticPreservationProved: false, authority: 'debug-metadata-only' };
}
