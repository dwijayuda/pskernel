import { artifactKey } from './artifact-evidence.mjs';
import { createSourcePreparationArtifacts, sourcePreparationContract } from './source-preparation-origins.mjs';

const fail = code => { throw new Error('PSC_SOURCE_MAP_ORIGIN_' + code); };
const same = (a, b) => artifactKey(a) === artifactKey(b);
const utf8 = bytes => new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }).decode(bytes);

export function sourceCoordinates(text, offsets) {
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
/** Shared original/prepared source composition. The caller's bounded resolver
 * supplies already rehashed snapshots; each mapping parent is rebuilt exactly.
 */
export function sourceMapOrigins({ origin, preparationOrigins, sourceSnapshot, resolve, read, maxBytes }) {
  if ((preparationOrigins === null) !== (sourceSnapshot === null)) fail('PREPARATION_PAIR');
  let sourceFiles;
  if (preparationOrigins !== null) {
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
  return sourceFiles;
}

export function generatedLineEnds(text, requested) {
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

